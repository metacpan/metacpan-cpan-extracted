# ABSTRACT: Perl wrapper for the BitTorrent Sync API
package Net::BitTorrentSync;

use strict;
use warnings;

# for now, check switching to HTTP::Tiny or Hijk
use LWP::Simple;
use JSON;

use Exporter;
our @ISA = 'Exporter';

our @EXPORT = qw(
    start_btsync
    set_config
    set_listened_address
    add_folder
    get_folders
    remove_folder
    get_files
    set_file_prefs
    get_folder_peers
    get_secrets
    get_folder_prefs
    set_folder_prefs
    get_folder_hosts
    set_folder_hosts
    get_prefs
    set_prefs
    get_os
    get_version
    get_speed
    shutdown_btsync
);

our $VERSION = '0.21';

my ($config, $listen);

=head1 NAME

Net::BitTorrentSync - A Perl interface to the BitTorrent Sync API

=head1 VERSION

version 0.21

=head1 SYNOPSIS

    use Net::BitTorrentSync;

    start_btsync('/path/to/btsync_executable', '/path/to/config_file');

or

    set_config('/path/to/config_file');

or

    set_listened_path('127.0.0.1:8888');

then

    add_folder('/path/to/folder');

    my $folders = get_folders();

    remove_folder($folders->[0]->{secret});


=head1 DESCRIPTION

BitTorrent Sync uses the BitTorrent protocol to sync files between
two or more machines, or nodes (computers or mobile phones) without
the need of a server. It uses "secrets", a unique hash string given
for each folder that replaces the need for a tracker machine.
The more nodes the network has, the faster the data will be synched
between the nodes, allowing for very fast exchange rates.
In addition, folders and files can be shared as read-only, or as
read and write.

This is a complete wrapper of the published BitTorrent Sync API.
It can be used to connect your Perl application to a running
BitTorrent Sync instance, in order to perform any action such as
adding, removing folders/files, querying them, setting preferences,
and fetch information about the BitTorrent Sync instance.

=head1 !WARNING!

The BitTorrent Sync technology and the existing BitTorrent Sync
client are not open source or free software, nor are their specs
available in any shape or form other than the API. Therefore, there
is no guarantee whatsoever that the communication between nodes is
not being monitored by BitTorrent Inc. or by any third party,
including the US Government or any Agency on behalf of the US
Government.

=head1 REQUIREMENTS

In order to run these commands you must have a running instance of the
BitTorrent Sync client, available for download here:
L<http://www.bittorrent.com/sync/downloads>.

No other non-perl requirements are needed.

You will need an API key, for which you'll need to apply here:
L<http://www.bittorrent.com/sync/developers>

Once BitTorrent Sync is installed, either add its executable's location
to the system path, or pass the location of the executable and the config
file to the start_btsync function.

=head1 CONFIG FILE

To enable the API, you must run BitTorrent Sync with the config file.
This can be achieved either through the function start_btsync, or
manually:

On Mac and Linux, run the Sync executable with --config path_to_file
argument.
On Windows, use /config path_to_file.

The config file may be located in any directory on your drive.

If you wish for this module to locate it automatically, you need
to name it btconfig and add its path to the environment path variable.

Sync uses JSON format for the configuration file.
Here is a sample config file that you can use to enable API:

    {
        // path to folder where Sync will store its internal data,
        // folder must exist on disk
        "storage_path" : "/Users/user/.SyncAPI",

        // run Sync in GUI-less mode
        "use_gui" : false,

        "webui" : {
            // IP address and port to access HTTP API
            "listen" : "127.0.0.1:8888",
            // login and password for HTTP basic authentication
            // authentication is optional
            "login" : "api",
            "password" : "secret",
            // API key received from BitTorrent
            "api_key" : "xxx"
        }
    }

=head1 METHODS

=head2 start_btsync

Launches a system command that starts the BitTorrent Sync program.
Returns the full path to the BitTorrent Sync executable.

=over 4

=item executable (required)

Specifies path to the BitTorrent Sync executable.
Alternatively, you can start the process manually and call either
set_config or set_listened_address.

=item config_file (required)

Specifies path to the config file path.

=back

=cut

sub start_btsync {
  my ($btsync, $cfg_path) = @_;
  $btsync ||= _find_in_path('btsync');
  $cfg_path ||= _find_in_path('btconfig');

    if ($^O eq 'MSWin32') {
      ($btsync, $cfg_path) = map {
        _format_windows_path($_)
      } ($btsync,$cfg_path);
        system("\"$btsync\" /config \"$cfg_path\"");
    } else {
        system("$btsync --config $cfg_path");
    }
  set_config($cfg_path);
  return $btsync;
}

=head2 set_config

Parses the config file to get the listened address from.
Alternatively, you can use set_listened_address.

returns the config JSON parsed to a Perl HashRef.

=over 4

=item config_file (required)

Specifies path to the config file.

=back

=cut

sub set_config {
    my $cfg_path = shift;
    $cfg_path ||= _find_in_path('btconfig');

    local $/;
    open my $fh, '<', $cfg_path or
      die "Error opening config file $cfg_path - $!\n";
    $config = decode_json(<$fh>);
    close $fh;
    $listen = $config->{webui}->{listen};
    return $config;
}

=head2 set_listened_address

Sets the listened address used to communicate with the BitTorrent Sync Process

=over 4

=item address (required)

Specifies address that the process listens to, address should be represented as
"[address]:[port]"

=back

=cut

sub set_listened_address {
    $listen = shift;
}

=head2 add_folder

Adds a folder to Sync. If a secret is not specified, it will be generated
automatically.
The folder will have to pre-exist on the disk and Sync will add it into a list
of syncing folders.
Returns '0' if no errors, error code and error message otherwise.

=over 4

=item dir (required)

Specifies path to the sync folder

=item secret (optional)

Specifies folder secret

=item selective_sync (optional)

Specifies sync mode: selective - 1; all files (default) - 0

=back

=cut

sub add_folder {
    my ($dir, $secret, $selective_sync) = @_;
    $dir = _format_windows_path($dir) if $^O eq 'MSWin32';

    my $request = "add_folder&dir=$dir";

    $request .= "&secret=$secret" if $secret;
    $request .= '&selective_sync=1' if $selective_sync;

    return _access_api($request);
}

=head2 get_folders

Returns an array with folders info.
If a secret is specified, will return info about the folder with this secret.

    [
        {
            dir      => "/path/to/dir/"
            secret   => "A54HDDMPN4T4BTBT7SPBWXDB7JVYZ2K6D",
            size     => 23762511569,
            type     => "read_write",
            files    => 3206,
            error    => 0,
            indexing => 0
        }
   ]

=over 4

=item secret (optional)

If a secret is specified, will return info about the folder with this secret

=back

=cut

sub get_folders {
    my ($secret) = @_;
    my $request = "get_folders";

    $request .= "&secret=$secret" if $secret;

    return _access_api($request);
}

=head2 remove_folder

Removes folder from Sync while leaving actual folder and files on disk.
It will remove a folder from the Sync list of folders and does not touch any
files or folders on disk.
Returns '0' if no error, '1' if there’s no folder with specified secret.

=over 4

=item secret (required)

Specifies folder secret

=back

=cut

sub remove_folder {
    my ($secret) = @_;
    my $request = "remove_folder&secret=$secret";

    return _access_api($request);
}

=head2 get_files

Returns list of files within the specified directory.
If a directory is not specified, will return list of files and folders within
the root folder.
Note that the Selective Sync function is only available in the API at this time.

    [
        {
            name  => "images",
            state => "created",
            type  => "folder"
        },
        {
            have_pieces  => 1,
            name         => "index.html",
            size         => 2726,
            state        => "created",
            total_pieces => 1,
            type         => "file",
            download     => 1 # only for selective sync folders
        }
    ]

=over 4

=item secret (required)

=item path (optional)

Specifies path to a subfolder of the sync folder.

=back

=cut

sub get_files {
    my ($secret, $path) = @_;
    my $request = "get_files&secret=$secret";

    $request .= "&path=$path" if $path;

    return _access_api($request);
}

=head2 set_file_prefs

Selects file for download for selective sync folders.
Returns file information with applied preferences.

=over 4

=item secret (required)

=item path (required)

Specifies path to a subfolder of the sync folder.

=item download (required)

Specifies if file should be downloaded (yes - 1, no - 0)

=back

=cut

sub set_file_prefs {
    my ($secret, $path, $download) = @_;
    my $request = "get_files&secret=$secret&path=$path&download=$download";

    return _access_api($request);
}

=head2 get_folder_peers

Returns list of peers connected to the specified folder.

    [
        {
            id         => "ARRdk5XANMb7RmQqEDfEZE-k5aI=",
            connection => "direct", # direct or relay
            name       => "GT-I9500",
            synced     => 0, # timestamp when last sync completed
            download   => 0,
            upload     => 22455367417
        }
    ]

=over 4

=item secret (required)

=back

=cut

sub get_folder_peers {
    my ($secret) = @_;
    my $request = "get_folder_peers&secret=$secret";
    return _access_api($request);
}

=head2 get_secrets

Generates read-write, read-only and encryption read-only secrets.
If ‘secret’ parameter is specified,
will return secrets available for sharing under this secret.
The Encryption Secret is new functionality.
This is a secret for a read-only peer with encrypted content
(the peer can sync files but can not see their content).
One example use is if a user wanted to backup files to an untrusted,
unsecure, or public location.
This is set to disabled by default for all users but included in the API.

    {
        read_only  => "ECK2S6MDDD7EOKKJZOQNOWDTJBEEUKGME",
        read_write => "DPFABC4IZX33WBDRXRPPCVYA353WSC3Q6",
        encryption => "G3PNU7KTYM63VNQZFPP3Q3GAMTPRWDEZ"
    }

=over 4

=item secret (required)

=item type (optional)

If type = encrypted, generate secret with support of encrypted peer

=back

NOTE: there seems to be some contradiction in the documentation
wrt to secret being required.

=cut

sub get_secrets {
    my ($secret, $type) = @_;

    my $request = "get_secrets";
    $request .= "&secret=$secret" if $secret;
    $request .= "&type=encryption" if $type;
    return _access_api($request);
}

=head2 get_folder_prefs

Returns preferences for the specified sync folder.

    {
        search_lan       => 1,
        use_dht          => 0,
        use_hosts        => 0,
        use_relay_server => 1,
        use_sync_trash   => 1,
        use_tracker      => 1
    }

=over 4

=item secret (required)

=back

=cut

sub get_folder_prefs {
    my ($secret) = @_;
    my $request = "get_folder_prefs&secret=$secret";
    return _access_api($request);
}

=head2 set_folder_prefs

Sets preferences for the specified sync folder.
Parameters are the same as in ‘Get folder preferences’.
Returns current settings.

=over 4

=item secret (required)

=item preferences

A hashref containing the preferences you wish to change.

=over 4

=item use_dht

=item use_hosts

=item search_lan

=item use_relay_server

=item use_tracker

=item use_sync_trash

=back

=back

=cut

sub set_folder_prefs {
    my ($secret, $prefs) = @_;
    my $request = "set_folder_prefs&secret=$secret";

    foreach my $pref (keys %{$prefs}) {
        $request .= '&' . $pref . '=' . $prefs->{$pref};
    }

    return _access_api($request);
}

=head2 get_folder_hosts

Returns list of predefined hosts for the folder,
or error code if a secret is not specified.

    {
        hosts => [
           "192.168.1.1:4567",
           "example.com:8975"
        ]
    }

=over 4

=item secret (required)

=back

=cut

sub get_folder_hosts {
    my ($secret) = @_;
    my $request = "get_folder_hosts&secret=$secret";
    return _access_api($request);
}

=head2 set_folder_hosts

Sets one or several predefined hosts for the specified sync folder.
Existing list of hosts will be replaced.
Hosts should be added as values of the ‘host’ parameter and separated by commas.
Returns current hosts if set successfully, error code otherwise.

=over 4

=item secret (required)

=item hosts (required)

List of hosts, each host should be represented as “[address]:[port]”

=back

=cut

sub set_folder_hosts {
    my ($secret, $hosts) = @_;
    my $request = "set_folder_hosts&secret=$secret&hosts=";

    $request .= join ',', @{$hosts};

    return _access_api($request);
}

=head2 get_prefs

Returns BitTorrent Sync preferences.
Contains dictionary with advanced preferences.
Please see Sync user guide for description of each option.

    {
        device_name                     => "iMac",
        disk_low_priority               => "true",
        download_limit                  => 0,
        folder_rescan_interval          => "600",
        lan_encrypt_data                => "true",
        lan_use_tcp                     => "false",
        lang                            => -1,
        listening_port                  => 11589,
        max_file_size_diff_for_patching => "1000",
        max_file_size_for_versioning    => "1000",
        rate_limit_local_peers          => "false",
        send_buf_size                   => "5",
        sync_max_time_diff              => "600",
        sync_trash_ttl                  => "30",
        upload_limit                    => 0,
        use_upnp                        => 0,
        recv_buf_size                   => "5"
    }

=cut

sub get_prefs {
    return _access_api("get_prefs");
}

=head2 set_prefs

Sets BitTorrent Sync preferences.
Parameters are the same as in ‘Get preferences’.
Advanced preferences are set as general settings. Returns current settings.

=over 4

=item preferences (required)

A hashref (see get_prefs) containing the preferences you wish to change.

=back

=cut

sub set_prefs {
    my ($secret, $prefs) = @_;
    my $request = "set_prefs";

    foreach my $pref (keys %{$prefs}) {
        $request .= '&' . $pref . '=' . $prefs->{$pref};
    }

    return _access_api($request);
}

=head2 get_os

Returns OS name where BitTorrent Sync is running.

    {
        os => "win32"
    }

=cut

sub get_os {
    return _access_api("get_os");
}

=head2 get_version

Returns BitTorrent Sync version.

    {
        version => "1.2.48"
    }

=cut

sub get_version {
    return _access_api("get_version");
}

=head2 get_speed

Returns current upload and download speed.

    {
        download => 61007,
        upload   => 0
    }

=cut

sub get_speed {
    return _access_api("get_speed");
}

=head2 shutdown

Gracefully stops Sync.

=cut

sub shutdown_btsync {
    return _access_api("shutdown");
}

sub _access_api {
    my $request = shift;

    $request = "http://$listen/api?method=" . $request;

    my $response = get $request;

    die "API returned undef, check if btsync process is running\n"
                                                        unless $response;

    return decode_json($response);
}

sub _format_windows_path {
    my $path = shift;
    $path =~ s!/|\\!\\!g;
    return $path;
}

sub _find_in_path {
  my $locate = shift;
  foreach my $dir (split ':', $ENV{'PATH'}) {
    opendir my $dh, $dir or die "can't opendir $dir: $!";
    if (grep { $_ eq $locate } readdir $dh) {
      closedir $dh;
      return "$dir/$locate";
    }
    closedir $dh;
  }
}

=head1 TODO

Not all methods are tested still

There's no way to make test this without a btsync executable in the path
I would've liked to be able to test the module without having to force the
user to conform to a precondition.

Also, the current documentation is lifted verbatim from the BitTorrent Sync
one, there should be some more explanation on what does what on my side.

=head1 BUGS

Most likely. Patches, bug reports and other ideas are welcomed.

=head1 SEE ALSO

L<http://www.bittorrent.com/sync/developers/api>

=head1 AUTHOR

Erez Schatz <erez@cpan.com>

=head1 LICENSE

Copyright (c) 2014 Erez Schatz.
This implementation of the BitTorrent Sync API is licensed under the
GNU General Public License (GPL) Version 3 or later.

The BitTorrent Sync API itself,
and the description text used in this module is:

Copyright (c) 2014 BitTorrent, Inc.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;

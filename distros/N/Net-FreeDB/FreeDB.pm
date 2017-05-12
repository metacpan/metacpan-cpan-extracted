package Net::FreeDB;

use Moo;
use Net::FreeDBConnection;
use Net::Cmd qw/CMD_OK CMD_MORE/;
use CDDB::File;
use File::Temp;

has hostname               => (is => 'ro', default => $ENV{HOSTNAME} // 'unknown');
has remote_host            => (is => 'rw', default => 'freedb.freedb.org');
has remote_port            => (is => 'rw', default => 8880);
has user                   => (is => 'rw', default => $ENV{USER} // 'unknown');
has timeout                => (is => 'rw', default => 120);
has debug                  => (is => 'rw', default => 0);
has current_protocol_level => (is => 'rw');
has max_protocol_level     => (is => 'rw');
has obj                    => (is => 'rw', lazy => 1, builder => '_create_obj');
has error                  => (is => 'rw');

require DynaLoader;
extends 'DynaLoader';

our $VERSION = '0.10';
bootstrap Net::FreeDB $VERSION;

sub _create_obj
{
    my $self = shift;
    my $obj = Net::FreeDBConnection->new(
        PeerAddr => $self->remote_host,
        PeerPort => $self->remote_port,
        Proto    => 'tcp',
        Timeout  => $self->timeout,
    );

    if ($obj) {
        my $res = $obj->response();

        if ($res == CMD_OK) {
            $obj->debug($self->debug);
            if ($obj->command(join(' ', ("CDDB HELLO ", $self->user, $self->hostname, ref($self), $self->VERSION)))) {
                my $response_code = $obj->response();
                if ($response_code != CMD_OK) {
                    $self->error($obj->message());
                }
            }
        } else {
            $obj = undef;
        }
    }

    return $obj;
}

sub lscat
{
    my $self = shift;
    my @categories = ();

    if ($self->_run_command('CDDB LSCAT') == CMD_OK) {
        my $data = $self->_read();
        if ($data) {
            map { my $line = $_; chomp($line); push @categories, $line; } @$data;
        }
    }

    return @categories;
}

sub query
{
    my $self = shift;
    my @results = ();

    if ($self->_run_command('CDDB QUERY', @_) == CMD_OK) {
        if ($self->obj->code() == 200) {
            my $data = $self->obj->message();
            push @results, _query_line_to_hash($data);
        } elsif ($self->obj->code() == 211) {
            my $lines = $self->_read();
            foreach my $line (@$lines) {
                push @results, _query_line_to_hash($line);
            }
        }
    }

    return @results;
}

sub read
{
    my $self = shift;
    my $result = undef;

    if ($self->_run_command('CDDB READ', @_) == CMD_OK) {
        my $data = $self->_read();
        my $fh = File::Temp->new();
        print $fh join('', @$data);
        seek($fh, 0, 0);
        my $cddb_file_obj = CDDB::File->new($fh->filename);
        $fh->close;
        $result = $cddb_file_obj;
    }

    return $result;
}

sub unlink
{
    my $self = shift;
    my $response = undef;

    if ($self->_run_command('CDDB UNLINK', @_) == CMD_OK) {
        $response = 1;
    }

    return $response;
}

sub write
{
    my $self = shift;
    my $response = undef;
    my $category = shift;
    my $disc_id  = shift;

    if ($self->_run_command('CDDB WRITE', $category, $disc_id) == CMD_MORE) {
        if ($self->_run_command(@_, ".\n") == CMD_OK) {
            $response = 1;
        }
    }

    return $response;
}

sub discid
{
    my $self = shift;
    my $response = undef;

    if ($self->_run_command('DISCID', @_) == CMD_OK) {
        $response = $self->obj->message();
        chomp($response);
        my (undef, undef, undef, $disc_id) = split(/\s/, $response);
        $response = $disc_id;
    }

    return $response;
}

sub get
{
    my $self = shift;
    my $filename = shift;
    my $file_contents = undef;

    if ($self->_run_command('GET', $filename) == CMD_OK) {
        $file_contents = $self->_read();
    }

    return $file_contents;
}

sub log
{
    my $self = shift;
    my @log_lines = ();

    if ($self->_run_command('LOG -l', @_) == CMD_OK) {
        my $lines = $self->_read();
        foreach my $line (@$lines) {
            chomp($line);
            push @log_lines, $line;
        }
    }

    return @log_lines;
}

sub motd
{
    my $self = shift;
    my @motd = ();

    if ($self->_run_command('MOTD') == CMD_OK) {
        push @motd, $self->obj->message();
        my $lines = $self->_read();
        foreach my $line (@$lines) {
            chomp($line);
            push @motd, $line;
        }
    }

    return @motd;
}

sub proto
{
    my $self = shift;
    my ($current_level, $max_level);

    if ($self->_run_command("PROTO", @_) == CMD_OK) {
        my $message = $self->obj->message();
        if ($message =~ /OK/) {
            $message =~ /OK, CDDB protocol level now: (\d)/;
            $self->current_protocol_level($1);
        } else {
            $message =~ /CDDB protocol level: current (\d), supported (\d)/;
            $self->current_protocol_level($1);
            $self->max_protocol_level($2);
        }
    }

    return $self->current_protocol_level();
}


sub put
{
    my $self = shift;
    my $type = shift;

    if ($self->_run_command('PUT', $type) == CMD_MORE) {
        $self->obj->datasend(@_);
    }
}

sub quit
{
    my $self = shift;
    $self->_run_command('QUIT');
}

sub sites
{
    my $self = shift;
    my @sites = ();

    if ($self->_run_command('SITES') == CMD_OK) {
        my $lines = $self->_read();
        foreach my $line (@$lines) {
            chomp($line);
            my ($hostname, $port, $latitude, $longitude, $description) = split(/\s/, $line, 5);
            push @sites, {
                hostname    => $hostname,
                port        => $port,
                latitude    => $latitude,
                longitude   => $longitude,
                description => $description,
            };
        }
    }

    return @sites;
}

sub stat
{
    my $self = shift;
    my $response = {};

    if ($self->_run_command('STAT') == CMD_OK) {
        my $lines = $self->_read();
        foreach my $line (@$lines) {
            chomp($line);
            my ($key, $value) = split(/:/, $line);
            if ($key && $value) {
                $key =~ s/\s*(.+)\s*/$1/;
                $value =~ s/\s*(.+)\s*/$1/;
                $response->{$key} = $value;
            }
        }
    }

    return $response;
}

sub update
{
    my $self = shift;
    my $response = undef;

    if ($self->_run_command('UPDATE') == CMD_OK) {
        $response = 1;
    }

    return $response;
}

sub validate
{
    my $self = shift;
    my $response = undef;

    if ($self->_run_command('VALIDATE') == CMD_MORE) {
        if ($self->run_command(@_ . "\n") == CMD_OK) {
            $response = 1;
        }
    }

    return $response;
}

sub ver
{
    my $self = shift;
    my $response = undef;

    if ($self->_run_command('VER') == CMD_OK) {
        $response = $self->obj->message();
    }

    return $response;
}

sub whom
{
    my $self = shift;
    my @users = ();

    if ($self->_run_command('WHOM') == CMD_OK) {
        my $lines = $self->_read();
        foreach my $line (@$lines) {
            chomp($line);
            push @users, $line;
        }
    }

    return @users;
}

sub get_local_disc_id
{
    my $self = shift;
    my $device = shift;
    my $disc_id = undef;

    if ($device) {
        $disc_id = xs_discid($device);
        if ($disc_id eq 'UNDEF' || $disc_id eq '') {
            $self->error('Drive Error: no disc found');
            $disc_id = undef;
        }
    }

    return $disc_id;
}

sub get_local_disc_data
{
    my $self = shift;
    my $device = shift;
    my $disc_data = undef;

    if ($device) {
        $disc_data = xs_discinfo($device);
        if (!$disc_data) {
            $self->error('Drive Error: no disc found');
        }
    }

    return $disc_data;
}

sub _read
{
    my $self = shift;
    my $data = $self->obj->read_until_dot
        or return undef;

    return $data;
}

sub _query_line_to_hash
{
    my $line = shift;
    chomp($line);
    my ($category, $disc_id, $the_rest) = split(/\s/, $line, 3);
    my ($artist, $album) = split(/\s\/\s/, $the_rest);

    return {
        Category => $category,
        DiscID   => $disc_id,
        Artist   => $artist,
        Album    => $album,
    };
}

sub _run_command
{
    my ($self, @arguments) = @_;

    my $response_code = undef;
    if ($self->obj->command(@arguments)) {
        $response_code = $self->obj->response();
        if ($response_code != CMD_OK) {
            my $error = $self->obj->message();
            chomp($error);
            $self->error($error);
        } 
    }

    return $response_code;
}

1;

__END__


=head1 NAME

Net::FreeDB - Perl interface to freedb server(s)

=head1 SYNOPSIS

    use Net::FreeDB;
    $freedb = Net::FreeDB->new();
    $discdata = $freedb->getdiscdata('/dev/cdrom');
    my $cddb_file_object = $freedb->read('rock', $discdata->{ID});
    print $cddb_file_object->id;

=head1 DESCRIPTION

    Net::FreeDB was inspired by Net::CDDB.  And in-fact
    was designed as a replacement in-part by Net::CDDB's
    author Jeremy D. Zawodny.  Net::FreeDB allows an
    oop interface to the freedb server(s) as well as
    some basic cdrom functionality like determining
    disc ids, track offsets, etc.

=head2 METHODS

=over

=item new(remote_host => $h, remote_port => $p, user => $u, hostname => $hn, timeout => $to)

     Constructor:
        Creates a new Net::FreeDB object.

     Parameters:
          Set to username or user-string you'd like to be logged as. Defaults to $ENV{USER}

        HOSTNAME: (optional)
          Set to the hostname you'd like to be known as. Defaults to $ENV{HOSTNAME}

        TIMEOUT: (optional)
          Set to the number of seconds to timeout on freedb server. Defaults to 120


    new() creates and returns a new Net::FreeDB object that is connected
    to either the given host or freedb.freedb.org as default.

=item lscat

    Returns a list of all available categories on the server.
    Sets $obj->error on error

=item query($id, $num_trks, $trk_offset1, $trk_offset2, $trk_offset3...)

  Parameters:

    query($$$...) takes:
  1: a discid
  2: the number of tracks
  3: first track offset
  4: second track offset... etc.

    Query expects $num_trks number of extra params after the first two.

    query() returns an array of hashes. The hashes looks like:

    {
        Category => 'newage',
        DiscID   => 'discid',
        Artist   => 'artist',
        Album    => 'title'
    }

    Sets $obj->error on error

    NOTE: query() can return 'inexact' matches and/or 'multiple exact'
    matches. The returned array is the given returned match(es).

=item read($server_category_string, $disc_id)

  Parameters:

    read($$) takes 2 parameters, the first being a server category name.
    This can be any string either that you make up yourself or
    that you believe the disc to be. The second is the disc id. This
    may be generated for the current cd in your drive by calling get_local_disc_id()

    Sets $obj->error on error

  NOTE:
    Using an incorrect category will result in either no return or an
    incorrect return. Please check the CDDB::File documentation for
    information on this module.

  read() requests a freedb record for the given information and returns a
    CDDB::File object.

=item unlink($server_category_string, $disc_id)

    Parameters:

    1: a server category name
    2: a valid disc_id

    This will delete the given entry on the server (if you have permission).
    Check the docs for the read() method to get more information on the parameters.

    Sets $obj->error on error.

=item write($server_category_string, $disc_id, $cddb_formatted_data)

    Parameters:

    1: a server category name
    2: a valid disc_id
    3: a properly formatted array of lines from a cddb file

    Returns true on success, otherwise $obj->error will be set.

=item discid($number_of_tracks, $track_1_offset, $track_2_offset, ..., $total_number_of_seconds_of_disc)

    Parameters:

    1: The total number of tracks of the current disc
    2: An array of the track offsets in seconds
    3: The total number of seconds of the disc.

    Returns a valid disc_id if found, otherwise $obj->error will be set.

=item get($filename)

    Parameters:

    1: The filename to retrieve from the server.

    Returns a scalar containing raw file contents. Returns $obj->error on error.


=item log($number_of_lines_per_section, start_date, end_date, 'day', $number_of_days, 'get')

    Parameters:

    1: The number of lines per section desired
    2: (Optional) A date after which statistics should be calculated in the format of hh[mm[ss[MM[DD[[CC]YY]]]]]
    3: (Optional) Must pass a start_date if passing this. A date after start date at which time statistics
        to not be calculated in the format of hh[mm[ss[MM[DD[[CC]YY]]]]]
    4: (Optional) The string 'day' to indicate that statistics should be calcuated for today.
    5: (Optional) A number of days to be calculated, default is 1
    6: (Optional) The string 'get' which will cause the log data to be recorded on the server's machine.

    NOTE: You must provide at least one of the optional options (2,3,4).
    Sets $obj->error on error.

=item motd

    Parameters:
        None

    Returns the message of the day as a string.
    Sets $obj->error on error.

=item proto($desired_protocol_level)

    Parameters: (Optional) The desired protocol level as a number.

    When called with NO parameters, will set the current and maximum allowed procotol levels,
    when called with a desired protocol level it will be set, $obj->errror will be set if an error occurs.

    Returns the currently selected protocol level.

=item put($type, $file)

    Parameters:

    1: type is either sites or motd
    2: based on param 1, an array of lines, either a list of mirror sites
        or a new message of the day

    Assuming you have permission to do so the server content will be updated.
    Sets $obj->error on error.

=item quit

    Parameters:
        None

    Disconnects from the server.

=item sites()

  Parameters:
    None

    sites() returns an array reference of urls that can be used as 
    a new remote_host.

=item stat

    Parameters:
        None

    Returns undef on error (and sets $obj->error). Otherwise returns a hashref
        where the keys/values are:

        max proto => <current_level>
            An integer representing the server's current operating protocol level.

        gets => <yes | no>
            The maximum protocol level.

        updates => <yes | no>
            Whether or not the client is allowed to initiate a database update.

        posting => <yes | no>
            Whether or not the client is allowed to post new entries.

        quotes => <yes | no>
            Whether or not quoted arguments are enabled.

        current users => <num_users>
            The number of users currently connected to the server.

        max users => <num_max_users>
            The number of users that can concurrently connect to the server.

        strip ext => <yes | no>
            Whether or not extended data is stripped by the server before presented to the user.

        Database entries => <num_db_entries>
            The total number of entries in the database.

        <category_name => <num_db_entries>
            The total number of entries in the database by category.

=item update

    Parameters:

    None

    Tells the server to update the database (if you have permission).
    Sets $obj->error on error.

=item validate($validating_string)

    Parameters:

    1: A string to be validated.

    If you have permission, given a string the server will validate the string
    as valid for use in a write call or not.

    Sets $obj->error on error.

=item ver

    Parameters:

    None

    Returns a string of the server's version.

=item whom

    Parameters:

    None

    If you have permission, returns a list of usernames of all connected users.
    Sets $obj->error on error.

=item get_local_disc_id

  Parameters:
    getdiscid($) takes the device you want to use.
    Basically this means '/dev/cdrom' or whatever on linux machines
    but it's an array index in the number of cdrom drives on windows
    machines starting at 0. (Sorry, I may change this at a later time).
    So, if you have only 1 cdrom drive then getdiscid(0) would work fine.

  getdiscid() returns the discid of the current disc in the given drive.

    NOTE: See BUGS

=item get_local_disc_data

  Parameters:
    getdiscdata($) takes the device you want to use. See getdiscid()
    for full description.

  getdiscdata() returns a hash of the given disc data as you would
  require for a call to query. The returns hash look like:

   {
     ID => 'd00b3d10',
     NUM_TRKS => '3',
     TRACKS => [
                 '150',
                 '18082',
                 '29172'
               ],
     SECONDS => '2879'
   }

   NOTE: A different return type/design may be developed.

=back

=head1 BUGS

        The current version of getdiscid() and getdiscdata()
        on the Windows platform takes ANY string in a single
        cdrom configuration and works fine.  That is if you
        only have 1 cdrom drive; you can pass in ANY string
        and it will still scan that cdrom drive and return
        the correct data.  If you have more then 1 cdrom drive
        giving the correct drive number will return in an
        accurate return.

=head1 Resources
    The current version of the CDDB Server Protocol can be
    found at: http://ftp.freedb.org/pub/freedb/latest/CDDBPROTO

=head1 AUTHOR
    David Shultz E<lt>dshultz@cpan.orgE<gt>
    Peter Pentchev E<lt>roam@ringlet.netE<gt>

=head1 CREDITS
    Jeremy D. Zawodny E<lt>jzawodn@users.sourceforge.netE<gt>
    Pete Jordon E<lt>ramtops@users.sourceforge.netE<gt>

=head1 COPYRIGHT
    Copyright (c) 2002, 2014 David Shultz.
    Copyright (c) 2005, 2006 Peter Pentchev.
    All rights reserved.
    This program is free software; you can redistribute it
    and/or modify if under the same terms as Perl itself.

=cut


package Net::SharePoint::Basic;

# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: Artistic-1.0-Perl

use 5.10.1;
use strict;
use warnings FATAL => 'all';
use utf8;
use experimental qw(smartmatch);

use Carp qw(carp croak confess cluck longmess shortmess);
use File::Basename;
use IO::Scalar;
use Storable;

use Data::UUID;
use File::Path;
use JSON::XS;
use LWP::UserAgent;
use POSIX qw(strftime);
use URI::Escape;

use Data::Dumper;

use base 'Exporter';

our @EXPORT = qw(
	$DEFAULT_SHAREPOINT_TOKEN_FILE $DEFAULT_SHAREPOINT_CONFIG_FILE
	$DEFAULT_RETRIES $DEFAULT_CHUNK_SIZE $MAX_LOG_SIZE
);

=head1 NAME

Net::SharePoint::Basic - Basic interface to Microsoft SharePoint REST API

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';

our %PATTERNS = (
	payload => "grant_type=client_credentials&client_id=%1\$s\@%3\$s&client_secret=%2\$s&resource=%4\$s/%5\$s\@%3\$s&scope=%4\$s/%5\$s\@%3\$s",
	upload  => "https://%1\$s/%2\$s/_api/web/GetFolderByServerRelativeUrl('/%2\$s/Shared Documents/%4\$s')/files/add(overwrite=true,url='%3\$s')",
	download =>	"https://%1\$s/%2\$s/_api/web/GetFolderByServerRelativeUrl('/%2\$s/Shared Documents/%4\$s')/files('%3\$s')/\$value",
	makedir  => "https://%1\$s/%2\$s/_api/SP.AppContextSite(\@target)/web/folders/add('Shared Documents/%4\$s')?\@target='https://%1\$s/%2\$s'",
	delete   => "https://%1\$s/%2\$s/_api/web/GetFolderByServerRelativeUrl('/%2\$s/Shared Documents/%3\$s')/recycle",
	list     => {
		files   => "https://%1\$s/%2\$s/_api/web/GetFolderByServerRelativeUrl('/%2\$s/Shared Documents/%3\$s')/Files",
		folders => "https://%1\$s/%2\$s/_api/web/GetFolderByServerRelativeUrl('/%2\$s/Shared Documents/%3\$s')/Folders",
	},
	chunk    => {
		start    => "https://%1\$s/%2\$s/_api/web/GetFileByServerRelativeUrl('/%2\$s/Shared Documents/%4\$s/%3\$s')/startupload(uploadId=guid'%5\$s')",
		continue => "https://%1\$s/%2\$s/_api/SP.AppContextSite(\@target)/web/GetFileByServerRelativeUrl('/%2\$s/Shared Documents/%4\$s/%3\$s')/continueupload(uploadId=guid'%5\$s', fileOffset='%6\$s')?\@target='https://%1\$s/%2\$s'",
		finish   => "https://%1\$s/%2\$s/_api/SP.AppContextSite(\@target)/web/GetFileByServerRelativeUrl('/%2\$s/Shared Documents/%4\$s/%3\$s')/finishupload(uploadId=guid'%5\$s', fileOffset='%6\$s')?\@target='https://%1\$s/%2\$s'",
	},
	move     => "https://%1\$s/%2\$s/_api/SP.AppContextSite(\@target)/web/GetFileByServerRelativeUrl('/%2\$s/Shared Documents/%3\$s')/moveto(newurl='/%2\$s/Shared Documents/%4\$s', flags=1)?\@target='https://%1\$s/%2\$s'",
	copy     => "https://%1\$s/%2\$s/_api/SP.AppContextSite(\@target)/web/GetFileByServerRelativeUrl('/%2\$s/Shared Documents/%3\$s')/copyto(strnewurl='/%2\$s/Shared Documents/%4\$s', boverwrite=true)?\@target='https://%1\$s/%2\$s'",
);
our $DEFAULT_SHAREPOINT_TOKEN_FILE     = '/var/run/sharepoint.token';
our $DEFAULT_SHAREPOINT_CONFIG_FILE    = '/etc/sharepoint.conf';

our %DEFAULT_SHAREPOINT_POST_PARAMS    = (
	Accept         => 'application/json;odata=verbose',
	Content_Type   => 'application/json;odata=verbose',
);
our $MAX_LOG_SIZE       =    500000;
our $DEFAULT_CHUNK_SIZE = 200000000;
our $DEFAULT_RETRIES    =         3;

=head1 SYNOPSIS

Net::SharePoint::Basic - Basic interface to Microsoft SharePoint REST API.

This module provides a basic interface for managing the Shared Documents catalog in the Microsoft SharePoint site via its REST API. In the current version only the following actions are supported:

 * generating a connection token
 * upload file or string
 * download file content and save it
 * list contents of folder
 * create new folder
 * delete file or folder

More actions are expected to be added in the future as well as we plan to increase the versatility of the arguments accepted by this module and the sample implementation of a client, 'sp-client', that comes with it.

The interface is object oriented. A few constants are exported.

The full testing (and naturally the full usage) of the module requires a working SharePoint site configuration. The structure of the configuration file will be described in this manual as well. The sample configuration file provided in this distribution will not work against SharePoint and plays the role of a placeholder only.

    use Net::SharePoint::Basic;

    my $sp = Net::SharePoint::Basic->new({config_file => 'sharepoint.conf'});
    # creates Shared Documents/test
    my $response = $sp->makedir({retries => 1}, '/test');
    # uploads a string as Shared Documents/test/teststring
    $sp->upload({}, '/test/teststring', 'abcd');
    # uploads a file 'testfile' into Shared Documents/test/
    $sp->upload({type => 'file'}, '/test/', 'testfile');
    # downloads contents of a file
    $sp->download({}, '/test/teststring');
    # downloads contents and saves it to a file
    $sp->download({save_file => 'testfile'}, '/test/teststring');
    # lists contents of a folder
    $sp->list({}, '/test');
    # deletes the folder
    $sp->delete({}, '/test');

This module was developed based on the MSDN SharePoint REST API at https://msdn.microsoft.com/en-us/library/office/jj860569.aspx .

=head1 EXPORT

The following constants (all can be overridden through either configuration file or constructor options) are exported:

=over

=item $DEFAULT_SHAREPOINT_TOKEN_FILE

The default location of the authorization token file (/var/run/sharepoint.token'

=item $DEFAULT_SHAREPOINT_CONFIG_FILE

The default location of the SharePoint portal configuration (/etc/sharepoint.conf)

=item $DEFAULT_RETRIES

The default number of retries to perform a REST action (3)

=item $DEFAULT_CHUNK_SIZE

The default chunk size for uploading large items. (200000000 bytes)

=item $MAX_LOG_SIZE

The maxium number of logged actions to keep (see C<log_it> method (500000)

=back

=head1 CONFIGURATION FILE

The module can work with a configuration file of the following format:

configuration_option <whitespace> value

The lines starting with '#' are ignored. The multiline values can be broken by using a backslash '\' sign. A sample configuration file is provided in the 't/' directory. It will NOT work with a Microsoft SharePoint instance, it is a placeholder file, useful only for internal tests. The default location of the configuration file assumed by the module is /etc/sharepoint.conf . The recognized options in the configuration file are:

 * module configuration:
   o token_file   - where to store the SharePoint token
   o max_log_size - maximum log size of $object->{log} (q.v.)
   o retries      - number of retries
   o chunk_size   - size of a chunk for upload in chunks of large files
 * SharePoint configuration:
   o sharepoint_client_id     - UUID of this client for SharePoint
   o sharepoint_client_secret - client secret for generating the access token
   o sharepoint_tenant_id     - UUID of the SharePoint tenant
   o sharepoint_principal_id  - UUID of the SharePoint principal
   o sharepoint_host          - the hostname of the SharePoint portal
   o sharepoint_site          - the site to work with in SharePoint
   o sharepoint_access_url    - URL to request the token from

=cut

=head1 ENVIROMENT VARIABLES

The following environment variables control the SharePoint client's behavior, for the purpose of debugging output:

 * NET_SHAREPOINT_VERBOSE - enable verbose output
 * NET_SHAREPOINT_DEBUG   - enable debug output

=cut

=head1 SUBROUTINES/METHODS

=head2 verbose ($)

 Utility function printing some extra messages. Newline is automatically appended.
 Parameters: the message to print (if a verbosity setting is on).
 Returns: void

=cut

sub verbose ($) {

	my $message = shift;
	binmode STDERR, ':utf8';
	print STDERR "$message\n" if $ENV{NET_SHAREPOINT_VERBOSE} || $ENV{NET_SHAREPOINT_DEBUG};
}

=head2 debug ($)

 Utility function printing some debug messages. Newline is automatically appended.
 Parameters: the message to print (if a verbosity setting is on).
 Returns: void

=cut

sub debug ($) {

	my $message = shift;
	print STDERR "$message\n" if $ENV{NET_SHAREPOINT_DEBUG};
}

=head2 timedebug ($)

 Utility function printing some debug messages with timestamp prepended. Newline is automatically appended.
 Parameters: the message to print (if a verbosity setting is on).
 Returns: void

=cut

sub timedebug ($) {

	my $message = shift;
	(print STDERR localtime(time) . " $message\n") if $ENV{NET_SHAREPOINT_DEBUG};
}

=head2 version (;$)

 Utility function returning the version of the package
 Parameters: Do not exit after printing version (optional)
 Returns: never.

=cut

sub version (;$) {

	print $VERSION, "\n";
	exit 0 unless shift;
}

=head2 read_file ($)

 Utility function that reads file into a string or dies if the file is not available.
 Parameters: the file to read
 Returns: the contents of the file as a string

=cut

sub read_file ($) {

	my $file = shift;

	local $/ = undef;
	debug "Reading $file";
	open(my $mail_fh, '<', $file) or die "Can't read file $file: $!";
	my $content = <$mail_fh>;
	close $mail_fh;

	$content;
}

=head2 write_file ($$;$)

 Utility function thgat writes the given string into a file, creating the necessary directories above it if necessary. Dies if the write is unsuccessful.
 Parameters: the contents
             the file to write
             [optional] force binary mode in writing
 Returns: the file path that was written.

=cut

sub write_file ($$;$) {

	my $content = shift;
	my $file    = shift;
	my $binary  = shift || 0;

	my $dir = dirname($file);
	mkpath($dir) unless -d $dir;
	open my $fh, $binary ? '>:raw' : '>:encoding(utf8)', $file or die "Couldn't open file $file for writing: $!";
	binmode $fh if $binary;
	print $fh $content;
	close $fh;
	verbose "Wrote file $file";
	$file;
}

=head2 read_config ($)

 Utility function that reads the sharepoint configuration file of whitespace separated values. See the detailed description of C<Configuration File>
 Parameters: the configuration file
 Returns: Hash of configuration parameters and their values.

=cut

sub read_config ($) {

	my $config_file = shift;
	my $config      = {};

	open(my $conf_fh, '<', $config_file) or return 0;
	while (<$conf_fh>) {
		next if /^\#/;
		next unless /\S/;
		s/^\s+//;
		s/\s+$//;
		my ($key, $value) = split(/\s+/, $_, 2);
		unless ($value) {
			$config->{$key} = undef;
			next;
		}
		chomp $value;
		while ($value =~ /\\$/) {
			my $extra_value = <$conf_fh>;
			next if $extra_value =~ /^\#/;
			next unless $extra_value =~ /\S/;
			$extra_value =~ s/^\s+//;
			$extra_value =~ s/\s+$//;
			chop $value;
			$value =~ s/\s+$//;
			$value .= " $extra_value";
		}
		$config->{$key} = $value;
	}
	close $conf_fh;
	return $config;
}

=head2 new ($;$)

 The constructor. Creates the Net::SharePoint::Basic object
 Parameters: optional hash with keys corresponding to the configuration file fields. Will override even the given a specific configuration file.
 Returns: Net::SharePoint::Basic object.

=cut

sub new ($;$) {

	my $class = shift;
	my $opts  = shift || {};

	my $self = {};
	if ($opts->{config_file}) {
		$self->{config} = read_config($opts->{config_file});
	}
	else {
		$self->{config} = read_config($DEFAULT_SHAREPOINT_CONFIG_FILE)
			if -f $DEFAULT_SHAREPOINT_CONFIG_FILE;
	}
	$self->{config} ||= {};
	for my $key (keys %{$opts}) {
		next if $key eq 'config_file';
		next unless defined $opts->{$key};
		debug "Setting $key to $opts->{$key}";
		$self->{config}{$key} = $opts->{$key};
	}
	$self->{token} = { ts => 0 };
	$self->{next_guid} = 1;
	$self->{config}{token_file}   ||= $DEFAULT_SHAREPOINT_TOKEN_FILE;
	$self->{config}{max_log_size} ||= $MAX_LOG_SIZE;
	$self->{config}{chunk_size}   ||= $DEFAULT_CHUNK_SIZE;
	$self->{config}{retries}      ||= $DEFAULT_RETRIES;
	$ENV{NET_SHAREPOINT_DEBUG}    ||= $opts->{debug};
	$ENV{NET_SHAREPOINT_VERBOSE}  ||= $opts->{verbose};
	bless $self, $class;
	$self;
}

=head2 dump_config ($)

 Dumps the supplied config and exits
 Arguments: the options hash
 Returns: void
 Caveat: will dump the credentials as well. Use with caution.

=cut

sub dump_config ($) {

	my $self = shift;

	for my $opt (keys %{$self->{config}}) {
		printf "%-25s %s\n", $opt, $self->{config}{$opt} || 'undef';
	}
}

=head2 validate_config ($;@)

 Validates the configuration for the SharePoint client. Checks basic syntactic requirements for the key configuration parameters expected to make connection with the REST API.
 Parameters: [optional] a list of extra options that would require to be defined by the application
 Returns: Error string if there was an error, empty string otherwise.

=cut

sub validate_config ($;@) {

	my $self       = shift;
	my @extra_opts = @_;

	my $opts = $self->{config};
	my $validated = '';

	return "Config was not found\n" unless $opts;
	for my $id (qw(sharepoint_client_id sharepoint_tenant_id sharepoint_principal_id)) {
		if (! $opts->{$id}) {
			$validated .= "Missing $id in configuration\n";
		}
		elsif ($opts->{$id} !~ /^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$/) {
			$validated .= "Badly formatted $id $opts->{$id} in configuration\n";
		}
	}
	$validated .= "SharePoint secret must be 44-char string ending with =\n"
		unless $opts->{sharepoint_client_secret}
		&& $opts->{sharepoint_client_secret} =~ /^(\S){43}\=/;
	$validated .= "SharePoint access URL must start with https://\n"
		unless $opts->{sharepoint_access_url}
		&& $opts->{sharepoint_access_url} =~ m|^https://|;
	$validated .= "SharePoint host must be defined\n"
		unless $opts->{sharepoint_host};
	$validated .= "SharePoint Site must include 'sites' in the URL\n"
		unless $opts->{sharepoint_site}
		&& $opts->{sharepoint_site} =~ m|^sites/.+|;
	for my $extra_opt (@extra_opts) {
		$validated .= "Option $extra_opt must be set according to the app"
			unless $opts->{$extra_opt};
	}
	return $validated;
}

=head2 log_it ($$;$)

 Log a message into the object. The messages are stored in the $object->{log} array reference. If the amount of messages exceeds $MAX_LOG_SIZE or $self->{config}{max_log_size} (if set), the older messages are shifted out of the log.
 Parameters: the message
             [optional] the severity (default - 'info')
 Returns: the shifted discarded message if any

=cut

sub log_it ($$;$) {

	my $self     = shift;
	my $message  = shift;
	my $severity = shift || 'info';

	$self->{log} ||= [];
	push(@{$self->{log}}, [
		time, $severity, $message
	]);
	shift @{$self->{log}} if @{$self->{log}} > $self->{config}{max_log_size};
}

=head2 create_payload ($)

 Creates an authorization request payload
 Arguments: the options hashref containing the sharepoint data
 Returns: the escaped payload

=cut

sub create_payload ($) {

	my $self = shift;

	my $payload = sprintf(
		$PATTERNS{payload},
		$self->{config}{sharepoint_client_id},
		$self->{config}{sharepoint_client_secret},
		$self->{config}{sharepoint_tenant_id},
		$self->{config}{sharepoint_principal_id},
		$self->{config}{sharepoint_host}
	);
	uri_escape($payload, "^A-Za-z0-9\-\._~\&\=");
}

=head2 update_token ($$)

 Updates the SharePoint Token
 Arguments: the options hashref containing sharepoint data
 Returns: 1 upon success
          undef upon failure

=cut

sub update_token ($) {

	my $self = shift;

	$self->{ua}             ||= LWP::UserAgent->new();
	$self->{token}{payload} ||= $self->create_payload();
	verbose "Getting a fresh token";
	my $token_response = $self->{ua}->post(
		$self->{config}{sharepoint_access_url},
		Content_Type => 'application/x-www-form-urlencoded',
		Content      => $self->{token}{payload}
	);
	unless ($token_response->is_success) {
		$self->log_it(
			"Updating token failed: " .
			Dumper decode_json($token_response->content),
			'error'
		);
		return undef;
	}
	my $json = decode_json($token_response->content);
	$self->{token}{ts}    = $json->{expires_on};
	$self->{token}{token} = $json->{access_token};
	$self->{token}{type}  = $json->{token_type};
	1;
}


=head2 init_token ($)

 Initializes a SharePoint token ( by calling ->update_token() ) and stores it in the $self->{config}{token_file}
 Parameters: none
 Returns: 1 if success
          undef if failure

=cut

sub init_token ($) {

	my $self = shift;

	my $token_file = $self->{config}{token_file};
	if (-f $token_file) {
		$self->log_it("Trying to use token file $token_file", 'debug');
		$self->{token} = retrieve $token_file;
		return undef if (
			time > $self->{token}{ts} - 1200
		) and ! $self->update_token();
	}
	else {
		return undef unless $self->update_token();
	}
	store $self->{token}, $token_file;
	$DEFAULT_SHAREPOINT_POST_PARAMS{Authorization} =
		"$self->{token}{type} $self->{token}{token}";
	1;
}

=head2 create_sharepoint_url ($$;@)

 Creates the SharePoint URL to operate against, filling the relevant pattern with the actual data.
 Parameters: the options hashref of the following keys
             pattern - the ready pattern (usually used in chunk upload) - or
             type - the type of the pattern
               (upload, download, list, makedir, delete) and
             subtype (for list only) - "files" or "folders"
             folder - the sharepoint folder/path to operate upon
             object - the sharepoint object to operate upon
 See %PATTERNS in the source code for more details on the URL construction.
 Returns: the filled URL string

=cut

sub create_sharepoint_url ($$;@) {

	my $self = shift;
	my $opts = shift;

	return undef unless $opts && ($opts->{pattern} || $opts->{type});
	my $folder   = $opts->{folder} || '';
	$folder      = '.' if $folder eq '/';
	my $object = $opts->{object} || '';
	my @extra_args = @_;
	my $pattern = $opts->{pattern};
	if (! $pattern) {
		if (! $PATTERNS{$opts->{type}}) {
			warn "Unknown type $opts->{type} of URL requested";
			return undef;
		}
		if (ref $PATTERNS{$opts->{type}}) {
			if (! $opts->{subtype} || ! $PATTERNS{$opts->{type}}->{$opts->{subtype}}) {
				warn "Pattern type $opts->{type} requires a valid subtype";
				return undef;
			}
			$pattern = $PATTERNS{$opts->{type}}->{$opts->{subtype}};
		}
		else {
			$pattern = $PATTERNS{$opts->{type}};
		}
	}
	$pattern =~
		s|Shared Documents|"Shared Documents/$self->{config}{base_subfolder}"|ge
		if $self->{config}{base_subfolder};
	my $url = sprintf(
		$pattern,
		$self->{config}{sharepoint_host},
		$self->{config}{sharepoint_site},
		$object // (),
		$folder, @extra_args,
	);

	$url;
}

=head2 try ($$$%)

 Tries to execute a SharePoint REST API call
 Parameters: the options hashref with the following parameters:
               action - mandatory, one of upload, download, list, makedir, delete,
                 chunk_upload_start, chunk_upload_continue, chunk_upload_finish
               retries - optional, number of retries defaults to $DEFAULT_RETRIES
             the url to try
             extra http header options hash:
               Accept         => 'application/json;odata=verbose',
               Content_Type   => 'application/json;odata=verbose',
               Authorization  => 'Bearer TOKEN_STRING',
             and for upload also:
               Content_Length => length($data),
               Content        => $data,
 Returns: the HTTP response if the API call was successful
          undef otherwise

=cut

sub try ($$$%) {

	my $self      = shift;
	my $opts      = shift;
	my $url       = shift;
	my %http_opts = @_;

	$self->{ua}      ||= LWP::UserAgent->new();
	$opts->{retries} ||= $DEFAULT_RETRIES;

	my $method = $opts->{action} eq 'download' || $opts->{action} eq 'list' ?
		'get' : 'post';
	while ($opts->{retries}) {
		unless ($self->init_token()) {
			$self->log_it("Failed to initialize token", "error");
			die  "Failed to initialize token: $self->{log}[-2][2]";
		}
		debug "Trying url $url";
		$http_opts{Authorization} ||= $DEFAULT_SHAREPOINT_POST_PARAMS{Authorization};
		my $response = $self->{ua}->$method($url, %http_opts);
		if ($response->is_success) {
			$self->log_it("Item $opts->{action} successful");
			return $response;
		}
		$opts->{retries}--;
		$self->log_it(
			"Couldn't $opts->{action} item ($opts->{retries} attempts remaining).\n" . $response->content, 'error'
		);
	}
	return undef;
}

=head2 get_chunk_pattern ($$)

 Selects correct pattern for uploading a chunk, depending on the stage of the upload.
 Parameters: the chunk's number (0..N)
             the number of total chunks (N)
 Returns: the start upload pattern for the first chunk
          the finish upload pattern for the last chunk
          the continue upload pattern for the rest
 Caveat: uses when() feature.

=cut

sub get_chunk_pattern ($$) {

	my $chunk_n      = shift;
	my $total_chunks = shift;

	my $pattern;
	for ($chunk_n) {
		when (0)             { $pattern = 'start';    }
		when ($total_chunks) { $pattern = 'finish';   }
		default              { $pattern = 'continue'; }
	}

	$PATTERNS{chunk}->{$pattern};
}

=head2 upload_in_chunks ($$$$$;$)

 Uploads a string in chunks, useful for uploading large volumes of data above the default SharePoint limit, usually 250000000 bytes.
 Parameters: the options hash with the number of retries as the only used key.
             the string scalar of data to upload
             the SharePoint object basename to create
             the SharePoint path to put the object in
             (optional) the chunk size. Defaults to either configured chunk size or to $DEFAULT_CHUNK_SIZE.
 Returns: the cumulative C<try()> response. If any of the tries fails aborts and returns 0.
 Caveat: the object must already be exist in SharePoint, even with zero size. See C<upload>.

=cut

sub upload_in_chunks ($$$$$;$) {

	my $self   = shift;
	my $opts   = shift;
	my $item   = shift;
	my $object = shift;
	my $folder = shift;
	my $chunk  = shift || $self->{config}{chunk_size} || $DEFAULT_CHUNK_SIZE;

	my $size            = length(ref $item ? $$item : $item);
	my $total_chunks    = int($size/$chunk);

	my $ug   = Data::UUID->new();
	my $guid = $ug->to_string($ug->create());
	my $r;
	for my $chunk_n (0..$total_chunks) {
		my $data = substr(
			(ref $item ? $$item : $item), 
			$chunk_n*$chunk, $chunk
		);
		my $pattern = get_chunk_pattern($chunk_n, $total_chunks);
		my $upload_url = $self->create_sharepoint_url({
			pattern => $pattern,
			object  => $object,
			folder  => $folder,
		}, $guid, $chunk_n ? $chunk_n * $chunk : ());
		$self->log_it("Chunk upload ($pattern) to $upload_url", 'debug');
		$r = $self->try(
			{
				action => "chunk_upload_$pattern",
				retries => $opts->{retries} || $self->{config}{retries},
			},
			$upload_url, (
				%DEFAULT_SHAREPOINT_POST_PARAMS,
				Content_Length => length($data),
				Content        => $data,
			)
		);
		return 0 unless $r;
	}
	$r;
}

=head2 upload ($$$$)

 Uploads a file or a string to SharePoint. Initiates the upload in chunks if necessary, generating the zero sized file for it before calling C<upload_in_chunks>
 Parameters: the options hash with
               type - "file" means we're uploading a file
               retries - the number of retries
             the SharePoint target. If it's a path ending with '/', basename of the file is being appended.
             the item - file or data string
 Returns: the HTTP response object if successful.
          0 when the upload fails or
            when the file is unreadable or
            when the upload is of a string and no target filename is specified.

=cut

sub upload ($$$$) {

	my $self   = shift;
	my $opts   = shift;
	my $target = shift;
	my $item   = shift;

	my ($object, $folder) = fileparse($target);
	$opts->{type} ||= '';
	if (! $object && $opts->{type} ne 'file') {
		warn "Cannot upload without target filename";
		return 0;
	}
	$object ||= basename($item);
	if ($opts->{type} eq 'file') {
		if (! -f $item) {
			warn "File $item does not exist, ignoring";
			return 0;
		}
		$item = read_file($item);
	}
	my $upload_url = $self->create_sharepoint_url({
		type   => 'upload',
		object => $object,
		folder => $folder,
	});
	if (length(ref $item ? $$item : $item) > $self->{config}{chunk_size}) {
		my $r = $self->try(
			{
				action => 'upload',
				retries => $opts->{retries} || $self->{config}{retries},
			},
			$upload_url, (
				%DEFAULT_SHAREPOINT_POST_PARAMS,
				Content_Length => 0,
				Content        => '',
			)
		);
		return 0 unless $r;
		$self->upload_in_chunks($opts, $item, $object, $folder);
	}
	else {
		$self->log_it("Upload to $upload_url", 'debug');
		return $self->try(
			{
				action => 'upload',
				retries => $opts->{retries} || $self->{config}{retries},
			},
			$upload_url, (
				%DEFAULT_SHAREPOINT_POST_PARAMS,
				Content_Length => length($item),
				Content        => ref $item ? $$item : $item,
			)
		) || 0;
	}
}

=head2 download ($$$;$)

 Downloads an object from SharePoint, optionally saving it into a file.
 Parameters: the options hashref
               save_file - the local path to save (or see target below)
               retries - the number of retries
             the SharePoint path to download
             (optional) the target local path to save. If target (or save_file value) is a directory, use basename of the SharePoint path for filename. The directory tree is created via C<write_file>.
 Returns: 0 if download failed
          path contents as a string scalar if string is requested
          saved path if a file save is requested

=cut

sub download ($$$;$) {

	my $self    = shift;
	my $opts    = shift;
	my $item    = shift;
	my $target  = shift || '';

	$opts->{save_file} = $target if $target;
	my $download_url = $self->create_sharepoint_url({
		type   => 'download',
		object => basename($item),
		folder  => dirname($item),
	});
	$self->log_it("Download from $download_url", 'debug');
	my $response = $self->try(
		{
			action  => 'download',
			retries => $opts->{retries} || $self->{config}{retries},
		},
		$download_url, %DEFAULT_SHAREPOINT_POST_PARAMS,
	);
	return 0 if ! defined $response;
	return $response->content unless $opts->{save_file};
	$opts->{save_file} .= "/" . basename($item) if -d $opts->{save_file};
	write_file($response->content, $opts->{save_file}, 1);
	return $opts->{save_file};
}

=head2 list ($$;$)

 Gets the contents of a given SharePoint folder. Note that you cannot list a file, you need to provide its path (event if it is root), and filter the results. Two API calls are issued, one to list files in the folders, one to list subfolders.
 Parameters: the options hashref
               path - the path to list
               retries - the number of retries
             path - (optional) - alternative way to specify path to list
 Returns: a decoded JSON structure of the REST API response or
          an empty list in case of failure.
 For the interpretation of the results for an actual listing, see the print_list_reports subroutine in the example SharePoint client provided in the package.

=cut

sub list ($$;$) {

	my $self = shift;
	my $opts = shift;
	my $path = shift || $opts->{path};

	my @results = ();
	for my $list_type (qw(files folders)) {
		my $list_url = $self->create_sharepoint_url({
			pattern => $PATTERNS{list}->{$list_type},
			object  => $path,
		});
		$self->log_it("Listing $list_url", 'debug');
		my $list_response = $self->try(
			{
				action => 'list',
				retries => $opts->{retries} || $self->{config}{retries},
			},
			$list_url, %DEFAULT_SHAREPOINT_POST_PARAMS,
		);
		next unless defined $list_response;
		my $json = decode_json($list_response->content);
		push(@results, @{$json->{d}{results}});
	}
	return \@results;
}

=head2 makedir ($$$)

 Creates a new folder in SharePoint.
 Parameters: the options hashref
               retries - the number of retries
             the folder to create
 Returns: the REST API response as returned by C<try()>

=cut

sub makedir ($$$) {

	my $self    = shift;
	my $opts    = shift;
	my $folder  = shift;

	my $mkdir_url = $self->create_sharepoint_url({
		type    => 'makedir',
		folder  => $folder,
	});
	$self->log_it("Creating folder $mkdir_url", 'debug');
	$self->try(
		{
			action => 'makedir',
			retries => $opts->{retries} || $self->{config}{retries},
		},
		$mkdir_url, %DEFAULT_SHAREPOINT_POST_PARAMS,
	);
}

=head2 delete ($$$)

 Deletes an item in SharePoint.
 Parameters: the options hashref
               retries - the number of retries
             the item to delete
 Returns: the REST API response as returned by C<try()>
 Note: any item will be deleted (put to Recycle Bin), even a non-empty folder. If a non-existent item is requested for deletion, the deletion will still return success, but the resulting response will have field $json->{d}{Recycle} set to "00000000-0000-0000-0000-000000000000"

=cut

sub delete ($$$) {

	my $self = shift;
	my $opts = shift;
	my $item = shift;

	my $delete_url = $self->create_sharepoint_url({
		type    => 'delete',
		object  => $item,
	});
	$self->log_it("Deleting item $delete_url", 'debug');
	$self->try(
		{
			action => 'delete',
			retries => $opts->{retries} || $self->{config}{retries},
		},
		$delete_url, %DEFAULT_SHAREPOINT_POST_PARAMS,
	);
}

=head2 move ($$$$)

 Moves an item in SharePoint
 Parameters: the options hashref
               retries - the number of retries
             the item to move
             the destination to move to
 Returns: the REST API response as returned by C<try()>

=cut

sub move ($$$$) {

	my $self   = shift;
	my $opts   = shift;
	my $item   = shift;
	my $target = shift;

	my $move_url = $self->create_sharepoint_url({
		type => 'move',
		object => $item,
		folder => $target,
	});
	$self->log_it("Moving item $item to $target", 'debug');
	$self->try(
		{
			action => 'move',
			retries => $opts->{retries} || $self->{config}{retries},
		},
		$move_url, %DEFAULT_SHAREPOINT_POST_PARAMS,
	);
}

=head2 copy ($$$$)

 Copies an item in SharePoint
 Parameters: the options hashref
               retries - the number of retries
             the item to copy
             the destination to copy to
 Returns: the REST API response as returned by C<try()>

=cut

sub copy ($$$$) {

	my $self   = shift;
	my $opts   = shift;
	my $item   = shift;
	my $target = shift;

	my $copy_url = $self->create_sharepoint_url({
		type => 'copy',
		object => $item,
		folder => $target,
	});
	$self->log_it("Copying item $item to $target", 'debug');
	$self->try(
		{
			action => 'copy',
			retries => $opts->{retries} || $self->{config}{retries},
		},
		$copy_url, %DEFAULT_SHAREPOINT_POST_PARAMS,
	);
}

=head1 AUTHOR

Roman Parparov, C<< <rparparov at vmware.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-sharepoint-simple at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SharePoint-Basic>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::SharePoint::Basic


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SharePoint-Basic>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-SharePoint-Basic>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-SharePoint-Basic>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-SharePoint-Basic/>

=item * Repository

L<https://github.com/vmware/perl-net-sharepoint-basic>

=item * MSDN SharePoint REST API

L<https://msdn.microsoft.com/en-us/library/office/jj860569.aspx>

=back

=head1 ACKNOWLEDGEMENTS

Special thanks to Andre Abramenko L<https://www.pilothouseconsulting.com/> for helping me figure out the REST API when I initially implemented it at VMware.

=head1 LICENSE AND COPYRIGHT

Copyright 2018 VMware.com

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Net::SharePoint::Basic

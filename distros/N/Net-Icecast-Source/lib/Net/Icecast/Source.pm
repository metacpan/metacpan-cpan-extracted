package Net::Icecast::Source;

use strict;
use warnings;

use Carp qw/croak/;
use IO::Socket::INET;
use IO::Handle;
use MIME::Base64;

######################

our $VERSION = '1.1';
our $BUF_SIZE = 1460; # how many bytes to read/transmit at a time

######################

=head1 NAME

Net::Icecast::Source - Icecast streaming source

=head1 SYNOPSIS

	use Net::Icecast::Source;
	my $source = new Net::Icecast::Source(
		username => 'revmischa',
		password => 'hackthegibson',
		server => '128.128.64.64',
		port => '8000',
		mount_point => '/source',
		mime_type => 'audio/mpeg',
		meta => {
			name => 'lol dongs radio fun land',
			description => 'party time all day',
			aim => 'lindenstacker',
			url => 'http://icecast.org',
		},
	);

	# attempt to connect to the streaming server
	$source->connect
		or die "Unable to connect to server: $!\n";
		
	# attempt to log in to the specified mountpoint
	$source->login
		or die "Incorrect username/password\n";

	# stream mp3
	my $sample;
	open $sample, "sample.mp3" or die $!;
	$source->stream_fh($sample);
	close $sample;
	
	# done, clean up
	$source->disconnect
	
=head1 DESCRIPTION

C<Net::Icecast::Source> is a simple module designed to make it easy to 
build programs which stream audio data to an Icecast2 server to be relayed.

=head1 CONSTRUCTOR

=over 4

=item new (%opts)

Create a new source instance. Options are: username, password, server, 
port, mount_point, meta, mime_type

=cut

sub new {
	my ($class, %opts) = @_;
	
	my $self = \%opts;
	return bless $self, $class;
}


=item connect

Connect to the server, use this before logging in. Returns success/failure

=cut

sub connect {
	my ($self) = @_;
	
	my $server = $self->{server} or croak "no server specified";
	my $port = $self->{port} || 8000;

	my $sock = IO::Socket::INET->new(
		PeerAddr => $server,
		PeerPort => $port,
		Proto    => 'tcp',
		Timeout  => 10,
	);
	
	$self->{sock} = $sock;
	return $sock;
}


=item login

Log in to the mount point and send metadata. Returns if login was successful or not

=cut

sub login {
	my ($self) = @_;
	
	my $password = $self->{password}
		or croak "no password specified";	
	my $username = $self->{username} || '';
	my $mount_point = $self ->{mount_point} || '/';
	my $mime_type = $self->{mime_type} || 'audio/mpeg';

	my $auth = "Authorization: Basic " . encode_base64("$username:$password");
	chomp $auth;
	my $meta = $self->_metadata_headers;
	my $req_method = qq/SOURCE $mount_point ICE\/1.0/;
	my $mime = "content-type: $mime_type";

	my @req = ($req_method, $auth, $mime);
	push @req, $meta if $meta;
	
	my $req = join("\r\n", @req) . "\r\n\r\n";

	$self->_write($req);
	
	my $ok = 0;
	while (my $line = $self->_read) {
		my ($status) = $line =~ /HTTP\/1.0 (\d\d\d)/;
		
		if ($status) {
			if ($status == 401) {
				$ok = 0;
			}  elsif ($status == 200) {
				$ok = 1;
			}
		}
				
		if ($line eq "\r\n") {
			last;
		}
	}
	
	$self->{logged_in} = $ok;			
	return $ok;
}


=item stream_fh($filehandle)

Read from $filehandle until EOF, passing through the raw data to the 
icecast server.

=cut

sub stream_fh {
	my ($self, $fh) = @_;
	
	my $sock = $self->{sock} or croak "Tried to stream while not connected to server";
	croak "Tried to stream while not logged in" unless $self->{logged_in};
	
	my $input = IO::Handle->new_from_fd($fh, "r");
	unless ($input) {
		warn "unable to create IO::Handle for filehandle $fh: $!\n";
		$sock->close;
		return 0;
	}
	
	my $buf;
	while (! $input->eof) {
		my $bytes = $input->sysread($buf, $BUF_SIZE);
		unless ($bytes) {
			# EOF
			last;
		}
				
		$sock->print($buf);
	}
	
	$input->close;
}


=item disconnect

Closes all sockets and disconnects

=cut

sub disconnect {
	my ($self) = @_;
	
	$self->{connected} = 0;
	$self->{logged_in} = 0;
	
	my $sock = $self->{sock} or return;
	
	$sock->shutdown(2); # done w socket
	$sock->close;
	delete $self->{sock};
}

#########


sub _metadata_headers {
	my $self = shift;
	
	my @headers;
	my $meta = $self->{meta} || {};
	foreach my $field (qw/name description url irc genre icq aim/) {
		my $val = $meta->{$field} or next;
		push @headers, "icy-$field: $val";
	}
	
	return join("\r\n", @headers);
}

sub _write {
	my ($self, $data) = @_;
	
	my $sock = $self->{sock};
	croak "Tried to write while not connected" unless $sock;
	
	$sock->syswrite($data);
}

sub _read {
	my ($self) = @_;
	
	my $sock = $self->{sock};
	croak "Tried to read while not connected" unless $sock;

	my $r = <$sock>;
	return $r;
}

1;
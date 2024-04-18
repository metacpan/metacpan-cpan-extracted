package Net::MitDK;

use strict;
use warnings;
our $VERSION = '0.05';
use Encode qw(encode decode);
use DateTime;
use MIME::Entity;
use MIME::Base64;
use IO::Lambda qw(:all);
use IO::Lambda::HTTP::Client;
use IO::Lambda::HTTP::UserAgent;
use HTTP::Request::Common;
use JSON::XS qw(encode_json decode_json);

sub new
{
	my ( $class, %opt ) = @_;
	my $self = bless {
		profile => 'default',
		ua      => IO::Lambda::HTTP::UserAgent->new,
		root    => 'https://gateway.mit.dk/view/client',
		mgr     => Net::MitDK::ProfileManager->new,
		session => {},
		config  => {},
		%opt,
	}, $class;

	$self->mgr->homepath( $opt{homepath}) if defined $opt{homepath};

	if ( defined $self->{profile}) {
		my ($config, $error) = $self->mgr->load( $self->profile );
		return (undef, $error) unless $config;
		$self->{config} = $config;
	}

	return $self;
}

sub config { $_[0]->{config} }

sub refresh_config
{
	my $self = shift;
	if ( $self->mgr->refresh_needed( $self->profile ) ) {
		my ($config, $error) = $self->mgr->load( $self->profile );
		return (undef, $error) unless $config;
		$self->{config} = $config;
	}
	return 1;
}

sub ua      { $_[0]->{ua}      }
sub root    { $_[0]->{root}    }
sub mgr     { $_[0]->{mgr}     }
sub token   { $_[0]->{config}->{token} }

sub profile
{
	return $_[0]->{profile} unless $#_;
	my ( $self, $profile ) = @_;
	return undef if $profile eq $self->{profile};

	my ($config, $error) = $self->mgr->load( $profile );
	return $error unless $config;

	$self->{session} = {};
	$self->{config}  = $config;
	$self->{profile} = $profile;

	return undef;
}

sub request
{
	my ($self, $method, $uri, $content, $options) = @_;

	my ($ok, $error) = $self->refresh_config;
	return lambda { undef, $error } unless $ok;

	my %extra;
	if ($method eq 'get' ) {
		$method = \&HTTP::Request::Common::GET;
		$options = $content;
	} else {
		$method = \&HTTP::Request::Common::POST;
		$extra{content} = encode_json($content);
		$extra{'content-type'} = 'application/json';
	}
	$options //= {};

	lambda {
		my $token = $self->config->{token};
		context $self->ua->request( $method->(
			$self->root . '/' . $uri,
			ngdptoken  => $token->{ngdp}->{access_token},
			mitdktoken => $token->{dpp}->{access_token},
			%extra
		));
	tail {
		my $response = shift;
		return (undef, $response) unless ref $response;

		my $json;
		unless ($response->is_success) {
			if ( $response->header('content-type') eq 'application/json') {
				eval { $json = decode_json($response->content) };
				goto PLAIN if $@;
				goto PLAIN if grep { ! exists $json->{$_} } qw(code message);
				my $err = "$json->{code}: $json->{message}";
				$err .= "(" . join(' ', @{$_->{fieldError}}) . ')'
					if $json->{fieldError} && ref($_->{fieldError}) eq 'ARRAY';
				return undef, $err;
			} else {
			PLAIN:
				return undef, $response->content
			}
		}

		return $response if $options->{raw};

		return undef, 'invalid content'
			unless $response->header('Content-Type') eq 'application/json';

		eval { $json = decode_json($response->content) };
		return undef, "invalid response ($@)"
			unless $json;

		if ( $json->{errorMessages} && ref($json->{errorMessages}) eq 'ARRAY') {
			$error = join("\n", map {
				my $err = "$_->{code}: $_->{message}";
				$err .= "(" . join(' ', @{$_->{fieldError}}) . ')'
					if $_->{fieldError} && ref($_->{fieldError}) eq 'ARRAY';
				$err
			} @{ $json->{errorMessages} });
			return undef, $error if length $error;
		}

		return $json;
	}};
}

sub get  { shift->request( get => @_ ) }
sub post { shift->request( post => @_ ) }

sub first_login
{
	my ($self, $json) = @_;
	return $self->authorization_refresh( $json->{refresh_token}, $json->{ngdp}->{refresh_token});
}

sub renew_lease
{
	my ($self) = @_;
	my $token = $self->config->{token};
	return $self->authorization_refresh( $token->{dpp}->{refresh_token}, $token->{ngdp}->{refresh_token});
}

sub update_config
{
	my $self = shift;
	return $self->mgr->save( $self->profile, $self->{config});
}

sub authorization_refresh
{
	my ($self, $dpp, $ngdp) = @_;
	return lambda {
		context $self->post('authorization/refresh?client_id=view-client-id-mobile-prod-1-id' => {
			dppRefreshToken  => $dpp,
			ngdpRefreshToken => $ngdp,
		});
	tail {
		my ($json, $error) = @_;
		return $json, $error unless $json;
		return undef, "bad response:".encode_json($json) unless exists $json->{dpp} and exists $json->{ngdp};

		$self->{config}->{token} = $json;
		return $self->update_config;
	}}
}

sub mailboxes
{
	my $self = shift;

	return lambda {
		return $self->{session}->{mailboxes} if $self->{session}->{mailboxes};

		context $self->get('mailboxes');
	tail {
		my ( $json, $error ) = @_;
		return ($json, $error) unless $json;

		($json) = grep { $_->{dataSource} eq 'DP_PUBLIC' } @{$json->{groupedMailboxes}->[0]->{mailboxes}};
		return (undef, "mailboxes: bad structure") unless $json;
		return $self->{session}->{mailboxes} = $json;
	}};
}

sub folders
{
	my $self = shift;

	return lambda {
		return $self->{session}->{folders} if $self->{session}->{folders};

		context $self-> mailboxes;
	tail {
		return @_ unless $_[0];

		context $self->post('folders/query' => {
			"mailboxes" => { DP_PUBLIC => $self->{session}->{mailboxes}->{id} }
		});
	tail {
		my ( $json, $errors ) = @_;
		return ($json, $errors) unless $json;
		my %folders;
		while ( my ( $k, $v ) = each %{$json->{folders}}) {
			$folders{$k} = $v->[0]->{id};
		}
		return (undef, "folders: bad structure") unless keys %folders;
		return $self->{session}->{folders} = \%folders;
	}}};
}


sub messages
{
	my ( $self, $offset, $limit ) = @_;
	return lambda {
		context $self-> folders;
	tail {
		return @_ unless $_[0];

		my $session = $self->{session};
		context $self->post('messages/query' => {
			size       => $limit,
			sortFields => ["receivedDateTime:DESC"],
			folders    => [{
				dataSource => 'DP_PUBLIC',
				foldersId  => [$session->{folders}->{INBOX}],
				mailboxId  => $session->{mailboxes}->{id},
				startIndex => $offset,
			}],
		});
	tail {
		@_
	}}};
}

sub list_all_messages
{
	my $self = shift;

	my $offset = 0;
	my $limit  = 100;

	my @ret;

	return lambda {
		context $self->messages($offset, $limit);
	tail {
		my ($json, $error) = @_;
		return ($json, $error) unless $json;

		push @ret, @{ $json->{results} };
		return \@ret if @{ $json->{results} } < $limit;

		$offset += $limit;
		context $self->messages($offset, $limit);
		again;
	}};
}

sub fetch_file
{
	my ( $self, $message, $document, $file ) = @_;
	return $self->get('DP_PUBLIC/' .
		"mailboxes/$self->{session}->{mailboxes}->{id}/" .
		"messages/$message->{id}/" .
		"documents/$message->{documents}->[$document]->{id}/" .
		"files/$message->{documents}->[$document]->{files}->[$file]->{id}/".
		"content",

		{raw => 1},
	);
}

sub fetch_message_and_attachments
{
	my ($self, $message, %opt) = @_;
	my @ret;
	my @errors;
	my $error_policy = $opt{error_policy} // 'default';

	return lambda {
		my @files;
		my ( $ndoc, $nfile ) = (0,0);
		for my $doc ( @{ $message->{documents} } ) {
			for my $file ( @{ $doc->{files} } ) {
				push @files, [ $ndoc, $nfile++ ];
			}
			$nfile = 0;
			$ndoc++;
		}
		return [] unless @files;

		($ndoc, $nfile) = @{ shift @files };
		context $self-> fetch_file($message, $ndoc, $nfile);
	tail {
		my ($resp, $error) = @_;
		unless ( defined $resp ) {
			if ( $error_policy eq 'strict') {
				return ($resp, $error);
			} elsif ( $error_policy eq 'warning') {
				push @errors, $error;
			} else {
				push @errors, $error;
				push @ret, [ $ndoc, $nfile, $error ];
			}
		} else {
			push @ret, [ $ndoc, $nfile, $resp->content ];
		}

		unless ( @files ) {
			# if at least one attachment is successful, treat errors as warnings
			return \@ret, undef, @errors if @ret;
			return undef, $errors[0];
		}
		($ndoc, $nfile) = @{ shift @files };

		context $self-> fetch_file($message, $ndoc, $nfile);
		again;
	}};
}

sub safe_encode
{
	my ($enc, $text) = @_;
	utf8::downgrade($text, 'fail silently please');
	return (utf8::is_utf8($text) || $text =~ /[\x80-\xff]/) ? encode($enc, $text) : $text;
}

sub assemble_mail
{
	my ( $self, $msg, $attachments ) = @_;

	my $sender = $msg->{sender}->{label};

	my $received = $msg->{receivedDateTime} // '';
	my $date;
	if ( $received =~ /^(\d{4})-(\d{2})-(\d{2})T(\d\d):(\d\d):(\d\d)/) {
		$date = DateTime->new(
			year   => $1,
			month  => $2,
			day    => $3,
			hour   => $4,
			minute => $5,
			second => $6,
		);
	} else {
		$date = DateTime->now;
	}
	$received = $date->strftime('%a, %d %b %Y %H:%M:%S %z');

	my $from = $self->config->{email_from} // 'noreply@mit.dk';
	my $mail = MIME::Entity->build(
		From          => ( safe_encode('MIME-Q', $sender) . " <$from>" ) ,
		To            => ( safe_encode('MIME-Q', $self->{session}->{mailboxes}->{ownerName}) . ' <' . ( $ENV{USER} // 'you' ) . '@localhost>' ),
		Subject       => safe_encode('MIME-Header', $msg->{label}),
		Data          => encode('utf-8', "Mail from $sender"),
		Date          => $received,
		Charset       => 'utf-8',
		Encoding      => 'quoted-printable',
		'X-Net-MitDK' => "v/$VERSION",
	);

	for ( @$attachments ) {
		my ( $ndoc, $nfile, $body ) = @$_;
		my $file = $msg->{documents}->[$ndoc]->{files}->[$nfile];
		my $fn   = $file->{filename};
		Encode::_utf8_off($body);

		my $entity = $mail->attach(
			Type     => $file->{encodingFormat},
			Encoding => 'base64',
			Data     => $body,
			Filename => $fn,
		);

		# XXX hack filename for utf8
		next unless $fn =~ m/[^\x00-\x80]/;
		$fn = Encode::encode('MIME-B', $fn);
		for ( 'Content-disposition', 'Content-type') {
			my $v = $entity->head->get($_);
			$v =~ s/name="(.*)"/name="$fn"/;
			$entity->head->replace($_, $v);
		}
	}

	return
		'From noreply@localhost ' .
		$date->strftime('%a %b %d %H:%M:%S %Y') . "\n" .
		$mail->stringify
		;
}

package
	Net::MitDK::ProfileManager;

use Fcntl ':seek', ':flock';
use JSON::XS qw(encode_json decode_json);

sub new
{
	my $self = bless {
		timestamps => {},
		homepath   => undef,
		readonly   => 0,
	}, shift;
	return $self;
}

sub _homepath
{

	if ( exists $ENV{HOME}) {
		return $ENV{HOME};
	} elsif ( $^O =~ /win/i && exists $ENV{USERPROFILE}) {
		return $ENV{USERPROFILE};
	} elsif ( $^O =~ /win/i && exists $ENV{WINDIR}) {
		return $ENV{WINDIR};
	} else {
		return '.';
	}
}

sub readonly { $#_ ? $_[0]->{readonly} = $_[1] : $_[0]->{readonly} }

sub homepath
{
	$#_ ? $_[0]->{homepath} = $_[1] : ($_[0]->{homepath} //  _homepath . '/.mitdk')
}

sub list
{
	my $self = shift;
	my $home = $self->homepath;

	return unless -d $home;
	my @list;
	for my $profile ( <$home/*.profile> ) {
		$profile =~ m[\/([^\/]+)\.profile] or next;
		push @list, $1;
	}
	return @list;
}

sub create
{
	my ($self, $profile, %opt) = @_;
	my $file = $self->homepath . "/$profile.profile";

	if ( -f $file ) {
		return 2 if $opt{ok_if_exists};
		return (undef, "Profile exists already");
	}

	return $self->save($profile, $opt{payload} // {} );
}

sub lock
{
	my $f = shift;
	return 1 if flock( $f, LOCK_NB | LOCK_EX);
	sleep(1);
	return 1 if flock( $f, LOCK_NB | LOCK_EX);
	sleep(1);
	return      flock( $f, LOCK_NB | LOCK_EX);
}

sub load
{
	my ($self, $profile ) = @_;
	my $file = $self->homepath . "/$profile.profile";

	return (undef, "No such profile") unless -f $file;
	local $/;
	open my $f, "<", $file or return (0, "Cannot open $file:$!");
	return (undef, "Cannot acquire lock on $file") unless lock($f);

	my $r = <$f>;
	close $f;

	my $json;
	eval { $json = decode_json($r) };
	return (undef, "Corrupted profile $file: $@") unless $json;

	$self->{timestamps}->{$profile} = time;

	return $json;
}

sub save
{
	my ($self, $profile, $hash) = @_;

	return (undef, "$profile is readonly") if $self->readonly;

	my $home = $self->homepath;
	unless ( -d $home ) {
		mkdir $home or return (undef, "Cannot create $home: $!");
		return (undef, "cannot chmod 0750 $home:$!") unless chmod 0750, $home;
		if ( $^O !~ /win32/i) {
			my (undef,undef,$gid) = getgrnam('nobody');
			return (undef, "no group `nobody`") unless defined $gid;
			return (undef, "cannot chown user:nobody $home:$!") unless chown $>, $gid, $home;
		}
	}

	my $json;
	my $encoder = JSON::XS->new->ascii->pretty;
	eval { $json = $encoder->encode($hash) };
	return (undef, "Cannot serialize profile: $!") if $@;

	my $file = "$home/$profile.profile";
	my $f;
	if ( -f $file ) {
		open $f, "+<", $file or return (undef, "Cannot create $file:$!");
		return (undef, "Cannot acquire lock on $file") unless lock($f);
		seek $f, 0, SEEK_SET;
		truncate $f, 0 or return (undef, "Cannot save $file:$!");
	} else {
		open $f, ">", $file or return (undef, "Cannot create $file:$!");
	}
	print $f $json or return (undef, "Cannot save $file:$!");
	close $f or return (undef, "Cannot save $file:$!");

	if ( $^O !~ /win32/i) {
		return (undef, "cannot chmod 0640 $file:$!") unless chmod 0640, $file;
		my (undef,undef,$gid) = getgrnam('nobody');
		return (undef, "no group `nobody`") unless defined $gid;
		return (undef, "cannot chown user:nobody $file:$!") unless chown $>, $gid, $file;
	}

	$self->{timestamps}->{$profile} = time;

	return 1;
}

sub remove
{
	my ($self, $profile) = @_;
	unlink $self->homepath . "/$profile.profile" or return (undef, "Cannot remove $profile:$!");
	return 1;
}

sub refresh_needed
{
	my ( $self, $profile ) = @_;
	return 0 unless exists $self->{timestamps}->{$profile};

	my $file = $self->homepath . "/$profile.profile";
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
	return 0 unless defined $mtime;

	return $mtime > $self->{timestamps}->{$profile};
}

1;

=pod

=head1 NAME

Net::MitDK - perl API for http://mit.dk/

=head1 DESCRIPTION

Read-only interface for MitDK. See README for more info.

=head1 AUTHOR

Dmitry Karasik <dmitry@karasik.eu.org>

=cut

package Net::Sieve;
use strict;
use warnings;

=head1 NAME

Net::Sieve - Implementation of managesieve protocol to manage sieve scripts

=head1 SYNOPSIS

  use Net::Sieve;

  my $SieveServer = Net::Sieve->new (
    server => 'imap.server.org',
    user => 'user',
    password => 'pass' ,
    );

  foreach my $script ( $SieveServer->list() ) {
    print $script->{name}." ".$script->{status}."\n";
  };

  my $name_script = 'test';

  # read
  print $SieveServer->get($name_script);

  # write
  my $test_script='
  require "fileinto";
  ## Place all these in the "Test" folder
  if header :contains "Subject" "[Test]" {
          fileinto "Test";
  }
  ';

  # other
  $SieveServer->put($name_script,$new_script);
  $SieveServer->activate($name_script);
  $SieveServer->deactivate();
  $SieveServer->delete($name_script);


=head1 DESCRIPTION

B<Net::Sieve> is a package for clients for the "MANAGESIEVE" protocol, which is an Internet Draft protocol for manipulation of "Sieve" scripts in a repository.  More simply, Net::Sieve lets you control your mail-filtering rule files on a mail server.

B<Net::Sieve> supports the use of "TLS" via the "STARTTLS" command. B<Net::Sieve> open the connexion to the sieve server, methods allow to list all scripts, activate or deactivate scripts, read, delete or put scripts. 

Most of code come from the great Phil Pennock B<sieve-connect> command-line tool L<http://people.spodhuis.org/phil.pennock/software/>.

See L<Net::Sieve::Script> to manipulate Sieve scripts content.

=cut

use Authen::SASL 2.11 qw(Perl); 
# 2.11: first version with non-broken DIGEST-MD5
#       Earlier versions don't allow server verification
#       NB: code still explicitly checks for a new-enough version, so
#           if you have an older version of Authen::SASL and know what you're
#           doing then you can remove this version check here.  I advise
#           against it, though.
# Perl: Need a way to ask which mechanism to send
use Authen::SASL::Perl::EXTERNAL; # We munge inside its private stuff.
use IO::Socket::INET6;
use IO::Socket::SSL 0.97; # SSL_ca_path bogus before 0.97
use MIME::Base64;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.11';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}


my %capa;
my %raw_capabilities;
my %capa_dosplit = map {$_ => 1} qw( SASL SIEVE );
# Key is permissably empty keyword, value if defined is closure to call with
# capabilities after receiving complete list, for verifying permissability.
# First param $sock, second \%capa, third \%raw_capabilities
my %capa_permit_empty = (
    # draft 7 onwards clarify that empty SASL is permitted, but is error
    # in absense of STARTTLS
    SASL    => sub {
        return if exists $_[1]{STARTTLS};
        # We die because there's no way to authenticate.
        # Spec states that after STARTTLS SASL must be non-empty
        warn "Empty SASL not permitted without STARTTLS\n";
        },
    SIEVE   => undef,
);
my $DEBUGGING = 1;

=head1 CONSTRUCTOR

=head2 new

 Usage : 
  my $SieveServer = Net::Sieve->new ( 
    server => 'imap.server.org', 
    user => 'user', 
    password => 'pass' );
 Returns :
  Net::Sieve object which contain current open socket 
 Argument :
  server      : default localhost
  port        : default 2000 
  user        : default logname or $ENV{USERNAME} or $ENV{LOGNAME}
  password    :
  net_domain  :
  sslkeyfile  : default search in /etc/ssl/certs
  sslcertfile : default search in /etc/ssl/certs
  autmech     : to force a particular authentication mechanism
  authzid     : request authorisation to act as the specified id
  realm       : pass realm information to the authentication mechanism
  ssl_verif   : default 0x01, set 0x00 to don't verify and allow self-signed cerificate
  notssl_verif: default 0x00, set 0x01 to don't verify and allow self-signed cerificate
  debug       : default 0, set 1 to have transmission logs
  dumptlsinfo : dump tls information

=cut

sub new
{
    my ($class, %param) = @_;

    my $self = bless ({}, ref ($class) || $class);

my $server = $param{server}||'localhost';
my $port = $param{port}||'2000';
my $user = $param{user};
my $password = $param{password};
my $net_domain = $param{net_domain}||AF_UNSPEC;
my $sslkeyfile =  $param{sslkeyfile};
my $sslcertfile =  $param{sslcertfile};
my $realm = $param{realm};
my $authmech = $param{autmech};
my $authzid = $param{authzid};
my $ssl_verify = 0x01;
   $ssl_verify = 0x01 if $param{ssl_verify};
   $ssl_verify = 0x00 if $param{ssl_verify} eq '0x00';
   $ssl_verify = 0x00 if $param{notssl_verify};
my $dump_tls_information = $param{dumptlsinfo};
$DEBUGGING = $param{debug};



my %ssl_options = (
        SSL_version     => 'SSLv23:!SSLv2:!SSLv3',
        SSL_cipher_list => 'ALL:!aNULL:!NULL:!LOW:!EXP:!ADH:@STRENGTH',
        SSL_verify_mode => $ssl_verify,
        SSL_ca_path     => '/etc/ssl/certs',
);

my $prioritise_auth_external = 0;
my ($forbid_clearauth, $forbid_clearchan) = (0, 0);

unless (defined $server) {
        $server = 'localhost';
        if (exists $ENV{'IMAP_SERVER'}
                        and $ENV{'IMAP_SERVER'} !~ m!^/!) {
                $server = $ENV{'IMAP_SERVER'};
                # deal with a port number.
                unless ($server =~ /:.*:/) { # IPv6 address literal
                        $server =~ s/:\d+\z//;
                }
        }
}

die "Bad server name\n"
        unless $server =~ /^[A-Za-z0-9_.-]+\z/;
die "Bad port specification\n"
        unless $port =~ /^[A-Za-z0-9_()-]+\z/;

unless (defined $user) {
        if ($^O eq "MSWin32") {
                # perlvar documents always "MSWin32" on Windows ...
                # what about 64bit windows?
                if (exists $ENV{USERNAME} and length $ENV{USERNAME}) {
                        $user = $ENV{USERNAME};
                } elsif (exists $ENV{LOGNAME} and length $ENV{LOGNAME}) {
                        $user = $ENV{LOGNAME};
                } else {
                        die "Unable to figure out a default user, sorry.\n";
                }
        } else {
                $user = getpwuid $>;
        }
        # this should handle the non-mswin32 case if 64bit _is_ different.
        die "Unable to figure out a default user, sorry!\n"
                unless defined $user;
}

if ((defined $sslkeyfile and not defined $sslcertfile) or
    (defined $sslcertfile and not defined $sslkeyfile)) {
        die "Need both a client key and cert for SSL certificate auth.\n";
}
if (defined $sslkeyfile) {
        $ssl_options{SSL_use_cert} = 1;
        $ssl_options{SSL_key_file} = $sslkeyfile;
        $ssl_options{SSL_cert_file} = $sslcertfile;
        $prioritise_auth_external = 1;
}


my $sock = IO::Socket::INET6->new(
        PeerHost        => $server,
        PeerPort        => $port,
        Proto           => 'tcp',
        Domain          => $net_domain,
        MultiHomed      => 1, # try multiple IPs (IPv4 works, v6 doesn't?)
);
unless (defined $sock) {
        my $extra = '';
        if ($!{EINVAL} and $net_domain != AF_UNSPEC) {
          $extra = " (Probably no host record for overriden IP version)\n";
        }
        die qq{Connection to "$server" [port $port] failed: $!\n$extra};
}

$sock->autoflush(1);
_debug("connection: remote host address is @{[$sock->peerhost()]}");

$self->{_sock} = $sock;

$self->_parse_capabilities();

$self->{_capa} = $raw_capabilities{SIEVE};

# New problem: again, Cyrus timsieved. As of 2.3.13, it drops the
# connection for an unknown command instead of returning NO. And
# logs "Lost connection to client -- exiting" which is an interesting
# way of saying "we dropped the connection". At this point, I give up
# on protocol-deterministic checks and fall back to version checking.
# Alas, Cyrus 2.2.x is still widely deployed because 2.3.x is the
# development series and 2.2.x is officially the stable series.
# This means that if they don't support NOOP by 2.3.14, I have to
# figure out how to decide what is safe and backtrack which version
# precisely was the first to send the capability response correctly.
my $use_noop = 1;
if (exists $capa{"IMPLEMENTATION"} and
      $capa{"IMPLEMENTATION"} =~ /^Cyrus timsieved v2\.3\.(\d+)-/ and
      $1 >= 13) {
      _debug("--- Cyrus drops connection with dubious log msg if send NOOP, skip that");
      $use_noop = 0;
      }

if (exists $capa{STARTTLS}) {
        $self->ssend("STARTTLS");
        $self->sget();
        die "STARTTLS request rejected: $_\n" unless /^OK\b/;
        IO::Socket::SSL->start_SSL($sock, %ssl_options) or do {
                my $e = IO::Socket::SSL::errstr();
                die "STARTTLS promotion failed: $e\n";
        };
        _debug("--- TLS activated here");
        if ($dump_tls_information) {
            print $sock->dump_peer_certificate();
            if ($DEBUGGING and
                exists $main::{"Net::"} and exists $main::{"Net::"}{"SSLeay::"}) {
                # IO::Socket::SSL depends upon Net::SSLeay
                # so this should be fairly safe, albeit messing
                # around behind IO::Socket::SSL's back.
                print STDERR Net::SSLeay::PEM_get_string_X509(
                    $sock->peer_certificate());
            }
        }
        $forbid_clearauth = 0;
        # Cyrus sieve might send CAPABILITY after STARTTLS without being
        # prompted for it.  This breaks the command-response model.
        # We can't just check to see if there's data to read or not, since
        # that will break if the next data is delayed (race condition).
        # There is no protocol-compliant method to determine this, short
        # of "wait a while, see if anything comes along; if not, send
        # CAPABILITY ourselves".  So, I broke protocol by sending the
        # non-existent command NOOP, then scan for the resulting NO.
        # This at least is stably deterministic. However, from draft 10
        # onwards, NOOP is a registered available extension which returns
        # OK.


       if ($use_noop) {
        my $noop_tag = "STARTTLS-RESYNC-CAPA";
           $self->ssend(qq{NOOP "$noop_tag"});
       #if ($capa{IMPLEMENTATION} =~ /dovecot/i) {
           $self->_parse_capabilities(
                    sent_a_noop => $noop_tag,
       #            until_see_no   => 0,
                   external_first => $prioritise_auth_external);
       } 
       else {
           $self->_parse_capabilities(
           #        until_see_no   => 1,
                   external_first => $prioritise_auth_external);
       }
        unless (scalar keys %capa) {
                $self->ssend("CAPABILITY");
                $self->_parse_capabilities(
                        external_first => $prioritise_auth_external);
        }
} elsif ($forbid_clearchan) {
        die "TLS not offered, SASL confidentiality not supported in client.\n";
}

my %authen_sasl_params;
$authen_sasl_params{callback}{user} = $user;
if (defined $authzid) {
        $authen_sasl_params{callback}{authname} = $authzid;
}
if (defined $realm) {
        # for compatibility, we set it as a callback AND as a property (below)
        $authen_sasl_params{callback}{realm} = $realm;
}


$authen_sasl_params{callback}{pass} = $password;


$self->closedie("Do not have an authentication mechanism list\n")
        unless ref($capa{SASL}) eq 'ARRAY';
if (defined $authmech) {
        $authmech = uc $authmech;
        if (grep {$_ eq $authmech} map {uc $_} @{$capa{SASL}}) {
                _debug("auth: will try requested SASL mechanism $authmech");
        } else {
                $self->closedie("Server does not offer SASL mechanism $authmech\n");
        }
        $authen_sasl_params{mechanism} = $authmech;
} else {
        $authen_sasl_params{mechanism} = $raw_capabilities{SASL};
}

my $sasl = Authen::SASL->new(%authen_sasl_params);
die "SASL object init failed (local problem): $!\n"
        unless defined $sasl;

my $secflags = 'noanonymous';
$secflags .= ' noplaintext' if $forbid_clearauth;
my $authconversation = $sasl->client_new('sieve', $server, $secflags)
        or die "SASL conversation init failed (local problem): $!\n";
if (defined $realm) {
        $authconversation->property(realm => $realm);
}
{
        my $sasl_m = $authconversation->mechanism()
                or die "Oh why can't I decide which auth mech to send?\n";
        if ($sasl_m eq 'GSSAPI') {
                _debug("-A- GSSAPI sasl_m <temp>");
                # gross hack, but it was bad of us to assume anything.
                # It also means that we ignore anything specified by the
                # user, which is good since it's Kerberos anyway.
                # (Major Assumption Alert!)
                $authconversation->callback(
                        user => undef,
                        pass => undef,
                );
        }

        my $sasl_tosend = $authconversation->client_start();
        if ($authconversation->code()) {
                my $emsg = $authconversation->error();
                $self->closedie("SASL Error: $emsg\n");
        }

        if (defined $sasl_tosend and length $sasl_tosend) {
                my $mimedata = encode_base64($sasl_tosend, '');
                my $mlen = length($mimedata);
                $self->ssend ( qq!AUTHENTICATE "$sasl_m" {${mlen}+}! );
                $self->ssend ( $mimedata );
        } else {
                $self->ssend ( qq{AUTHENTICATE "$sasl_m"} );
        }
        $self->sget();

        while ($_ !~ /^(OK|NO)(?:\s.*)?$/m) {
                my $challenge;
                if (/^"(.*)"\r?\n?$/) {
                        $challenge = $1;
                } else {
                        unless (/^{(\d+)\+?}\r?$/m) {
                                $self->sfinish ( "*" );
                                $self->closedie ("Failure to parse server SASL response.\n");
                        }
                        ($challenge = $_) =~ s/^{\d+\+?}\r?\n?//;
                }
                $challenge = decode_base64($challenge);

                my $response = $authconversation->client_step($challenge);
                if ($authconversation->code()) {
                        my $emsg = $authconversation->error();
                        $self->closedie("SASL Error: $emsg\n");
                }
                $response = '' unless defined $response; # sigh
                my $senddata = encode_base64($response, '');
                my $sendlen = length $senddata;
                $self->ssend ( "{$sendlen+}" );
                # okay, we send a blank line here even for 0 length data
                $self->ssend ( $senddata );
                $self->sget();
        }

        if (/^NO((?:\s.*)?)$/) {
                $self->closedie_NOmsg("Authentication refused by server");
        }
        if (/^OK\s+\(SASL\s+\"([^"]+)\"\)$/) {
                # This _should_ be pre_sent with server-verification steps which
                # in other profiles expect an empty response.  But Authen::SASL
                # doesn't let us confirm that we've finished authentication!
                # The assumption seems to be that the server only verifies us
                # so if it says "okay", we don't keep trying.
                my $final_auth = decode_base64($1);
                my $valid = $authconversation->client_step($final_auth);
                # With Authen::SASL before 2.11 (..::Perl 1.06),
                # Authen::SASL::Perl::DIGEST-MD5 module will complain at this
                # final step:
                #   Server did not provide required field(s): algorithm nonce
                # which is bogus -- it's not required or expected.
                # Authen::SASL 2.11 fixes this, with ..::Perl 1.06
                # We explicitly permit silent failure with the security
                # implications because we require a new enough version of
                # Authen::SASL at import time above and if someone removes
                # that check, then on their head be it.
                if ($authconversation->code()) {
                    my $emsg = $authconversation->error();
                    if ($Authen::SASL::Perl::VERSION >= 1.06) {
                        $self->closedie("SASL Error: $emsg\n");
                    }
                }
                if (defined $valid and length $valid) {
                        $self->closedie("Server failed final verification [$valid]");
                }
        }

}

    return $self;
};

# destructor
sub DESTROY {
  my $self = shift;

  $self->sfinish() if $self->{_sock};
}

#############
# public methods

=head1 METHODS

=head2 sock

 Usage    : my $sock = $ServerSieve->sock();
 Return   : open socket
 Argument : nothing
 Purpose  : access to socket

=cut

sub sock
{
    my $self = shift;
    return $self->{_sock};
}

=head2 capabilities

 Usage    : my $script_capa = $ServerSieve->capabilities();
 Return   : string with white space separator
 Argument : nothing
 Purpose  : retrieve sieve script capabilities

=cut

sub capabilities
{
    my $self = shift;
    return $self->{_capa};
}

=head2 list

 Usage    : 
  foreach my $script ( $ServerSieve->list() ) {
        print $script->{name}." ".$script->{status}."\n";
  };
 Return   : array of hash with names and status scripts for current user 
 Argument : nothing
 Purpose  : list available scripts on server

=cut

sub list
{
    my $self = shift;
    my @list_scripts;
    my $sock = $self->{_sock};
    $self->ssend("LISTSCRIPTS");
    $self->sget();
    while (/^\"/) {
         my $line =  $_;
         my $name = $1 if ($line =~ m/\"(.*?)\"/);
         my $status = ($line =~ m/ACTIVE/) ? 1 : 0;
         my %script = (name => $name, status => $status);
         push @list_scripts,\%script;
         $self->sget();
         }

    return @list_scripts;
}

=head2 put

 Usage    : $ServerSieve->put($name,$script);
 Return   : 1 on success, 0 on missing name or script
 Argument : name, script 
 Purpose  : put script on server

=cut

sub put
{
    my $self = shift;
    my $name = shift;
    my $script = shift;

    my $sock = $self->{_sock};

    my $size = length($script);
    return 0 if (!$size || !$name);

    $self->ssend('PUTSCRIPT "'.$name.'" {'.$size.'+}');
    $self->ssend('-noeol', $script);
    $self->ssend('');
    $self->sget();

    unless (/^OK((?:\s.*)?)$/) {
       warn "PUTSCRIPT(".$name.") failed: $_\n";
    }

    return 1;
}

=head2 get

 Usage    : my $script = $ServerSieve->get($name);
 Return   : 0 on missing name, string with script on success
 Argument : name 
 Purpose  : put script on server

=cut

sub get
{
    my $self = shift;
    my $name = shift;
    
    return 0 if (!$name);

    $self->ssend("GETSCRIPT \"$name\"");
    $self->sget();
        if (/^NO((?:\s.*)?)$/) {
                die_NOmsg($1, qq{Script "$name" not returned by server});
        }
        if (/^OK((?:\s.*)?)$/) {
                warn qq{Empty script "$name"?  Not saved.\n};
                return 0;
        }
        unless (/^{(\d+)\+?}\r?$/m) {
                die "QUIT:Failed to parse server response to GETSCRIPT";
        }
        my $contentdata = $_;
        $self->sget();
        while (/^$/) { $self->sget(); } # extra newline but only for GETSCRIPT?
        unless (/^OK((?:\s.*)?)$/) { 
                die_NOmsg($_, "Script retrieval not successful, not saving");
        }
        $contentdata =~ s/^{\d+\+?}\r?\n?//m;
        
    return $contentdata;
}

=head2 activate

 Usage    : $ServerSieve->activate($name);
 Return   : 0 on pb, 1 on success
 Argument : name 
 Purpose  : set named script active and switch other scripts to unactive

=cut

sub activate {
    my $self = shift;
    my $name = shift;

    $self->ssend("SETACTIVE \"$name\"");
    $self->sget();
    unless (/^OK((?:\s.*)?)$/) {
        warn "SETACTIVE($name) failed: $_\n";
        return 0;
    }

    return 1;
}

=head2 deactivate

 Usage    : $ServerSieve->deactivate();
 Return   : activate response
 Argument : nothing
 Purpose  : stop sieve processing, deactivate all scripts

=cut

sub deactivate {
    my $self = shift;
    
    return $self->activate("");
}

=head2 delete

 Usage    : $ServerSieve->delete($name);
 Return   : 0 on missing name, 1 on success
 Argument : name 
 Purpose  : delete script on server

=cut

sub delete {
    my $self = shift;
    my $name = shift;
    
    return 0 if (!$name);

    $self->ssend("DELETESCRIPT \"$name\"");
    $self->sget();
    unless (/^OK((?:\s.*)?)$/) {
        warn "DELETESCRIPT($name) failed: $_\n";
        return 0;
    }

    return 1;
}

###################
# private methods
#functions

sub _parse_capabilities
{
        my $self = shift;
        my $sock = $self->{_sock};
        local %_ = @_;
        my $external_first = 0;
        $external_first = $_{external_first} if exists $_{external_first};

        my @double_checks;
        %raw_capabilities = ();
        %capa = ();
        while (<$sock>) {
                chomp; s/\s*$//;
                _received() unless /^OK\b/;
                if (/^OK\b/) {
                        $self->sget('-firstline', $_);
                        last unless exists $_{sent_a_noop};
                        # See large comment below in STARTTLS explaining the
                        # resync problem to understand why this is here.
                        my $end_tag = $_{sent_a_noop};
                        unless (defined $end_tag and length $end_tag) {
                            # Default tag in absense of client-specified
                            # tag MUST be NOOP (2.11.2. NOOP Command)
                            $self->closedie("Internal error: sent_a_noop without tag\n");
                        }
                        # Play crude, just look for the tag anywhere in the
                        # response, honouring only word boundaries. It's our
                        # responsibility to make the tag long enough that this
                        # works without tokenising.
                        if ($_ =~ m/\b\Q${end_tag}\E\b/) {
                            return;
                        }
                        # Okay, that's the "server understands NOOP" case, for
                        # which the server should have advertised the
                        # capability prior to TLS (and so subject to
                        # tampering); we play fast and loose, so have to cover
                        # the NO case below too.
                } elsif (/^\"([^"]+)\"\s+\"(.*)\"$/) {
                        my ($k, $v) = (uc($1), $2);
                        unless (length $v) {
                            unless (exists $capa_permit_empty{$k}) {
                                warn "Empty \"$k\" capability spec not permitted: $_\n";
                                # Don't keep the advertised capability unless
                                # it has some value which is needed.  Eg,
                                # NOTIFY must list a mechanism to be useful.
                                next;
                            }
                            if (defined $capa_permit_empty{$k}) {
                                push @double_checks, $capa_permit_empty{$k};
                            }
                        }
                        if (exists $capa{$k}) {
                            # won't catch if the first instance was ignored for an
                            # impermissably empty value; by this point though we
                            # would already have issued a warning and the server
                            # is so fubar that it's not worth worrying about.
                            warn "Protocol violation.  Already seen capability \"$k\".\n" .
                                "Ignoring second instance and continuing.\n";
                            next;
                        }
                        $raw_capabilities{$k} = $v;
                        $capa{$k} = $v;
                        if (exists $capa_dosplit{$k}) {
                                $capa{$k} = [ split /\s+/, $v ];
                        }
                } elsif (/^\"([^"]+)\"$/) {
                        $raw_capabilities{$1} = '';
                        $capa{$1} = 1;
                } elsif (/^NO\b/) { 
                        #return if exists $_{until_see_no};
                        return if exists $_{sent_a_noop};
                        warn "Unhandled server line: $_\n"
                } elsif (/^BYE\b(.*)/) {
                    #closedie_NOmsg( $1,
                    die (
                        "Server said BYE when we expected capabilities.\n");
                } else {
                        warn "Unhandled server line: $_\n"
                }
        };

        die ( "Server does not return SIEVE capability, unable to continue.\n" )
            unless exists $capa{SIEVE};
        warn "Server does not return IMPLEMENTATION capability.\n"
            unless exists $capa{IMPLEMENTATION};

        foreach my $check_sub (@double_checks) {
            $check_sub->($sock, \%capa, \%raw_capabilities);
        }

        if (grep {lc($_) eq 'enotify'} @{$capa{SIEVE}}) {
            unless (exists $capa{NOTIFY}) {
                warn "enotify extension present, NOTIFY capability missing\n" .
                    "This violates MANAGESIEVE specification.\n" .
                    "Continuing anyway.\n";
            }
        }

        if (exists $capa{SASL} and $external_first
                        and grep {uc($_) eq 'EXTERNAL'} @{$capa{SASL}}) {
                # We do two things.  We shift the EXTERNAL to the head of the
                # list, suggesting that it's the server's preferred choice.
                # We then mess around inside the Authen::SASL::Perl::EXTERNAL
                # private stuff (name starts with an underscore) to bump up
                # its priority -- for some reason, the method which is not
                # interactive and says "use information already available"
                # is less favoured than some others.
                _debug("auth: shifting EXTERNAL to start of mechanism list");
                my @sasl = ('EXTERNAL');
                foreach (@{$capa{SASL}}) {
                        push @sasl, $_ unless uc($_) eq 'EXTERNAL';
                }
                $capa{SASL} = \@sasl;
                $raw_capabilities{SASL} = join(' ', @sasl);
                no warnings 'redefine';
                $Authen::SASL::Perl::EXTERNAL::{_order} = sub { 10 };
        }
}

sub _debug
{
        return unless $DEBUGGING;
        print STDERR "$_[0]\n";
}

sub _diag {
    my ($prefix, $data) = @_;
    $data =~ s/\r/\\r/g; $data =~ s/\n/\\n/g; $data =~ s/\t/\\t/g;
    $data =~ s/([^[:graph:] ])/sprintf("%%%02X", ord $1)/eg;
    _debug "$prefix $data";
}
sub _sent { my $t = defined $_[0] ? $_[0] : $_; _diag('>>>', $t) }
sub _received { my $t = defined $_[0] ? $_[0] : $_; _diag('<<<', $t) }

#sub _sent { $_[0] = $_ unless defined $_[0]; _debug ">>> $_[0]"; }
#sub _received { $_[0] = $_ unless defined $_[0]; _debug "<<< $_[0]"; }

# ######################################################################
# minor public routines

=head1 Minor public methods

=head2 ssend

 Usage : $self->ssend("GETSCRIPT \"$name\"");

=cut

sub ssend
{
        my $self = shift;
        my $sock = $self->{_sock};
        
        my $eol = "\r\n";
        if (defined $_[0] and $_[0] eq '-noeol') {
                shift;
                $eol = '';
        }
        foreach my $l (@_) {
                $sock->print("$l$eol");
# yes, the _debug output can have extra blank lines if supplied -noeol because
# they're already pre_sent.  Rather than mess around to tidy it up, I'm leaving
# it because it's _debug output, not UI or protocol text.
                _sent ( "$l$eol" );
        }
}

=head2 sget

 Usage: 
    $self->sget();
    unless (/^OK((?:\s.*)?)$/) {
        warn "SETACTIVE($name) failed: $_\n";
        return 0;
    }

=cut

sub sget
{
        my $self = shift;
        my $l = undef;
        my $sock = $self->{_sock};
        my $dochomp = 1;
        while (@_) {
            my $t = shift;
            next unless defined $t;
            if ($t eq '-nochomp') { $dochomp = 0; next; }
            if ($t eq '-firstline') {
                die "Missing sget -firstline parameter"
                unless defined $_[0];
                $l = $_[0];
                shift;
                next;
            }
            die "Unknown sget parameter [$t]";
        }
        $l = $sock->getline() unless defined $l;
        unless (defined $l) {
            _debug "... no line read, connection dropped?";
            die "Connection dropped unexpectedly when trying to read.\n";
        }
        if ($l =~ /{(\d+)\+?}\s*\n?\z/) {
                _debug("... literal string response, length $1");
                my $len = $1;
                if ($len == 0) {
                        my $discard = $sock->getline();
                } else {
                        while ($len > 0) {
                                my $extra = $sock->getline();
                                $len -= length($extra);
                                $l .= $extra;
                        }
                }
                $dochomp = 0;
        }
        if ($dochomp) {
                chomp $l; $l =~ s/\s*$//;
        }
        _received($l);
        if (defined wantarray) {
                return $l;
        } else {
                $_ = $l;
        }
}

=head2 sfinish

send LOGOUT

=cut

sub sfinish
{
        my $self = shift;
        my $sock = $self->{_sock};
        if (defined $_[0]) {
                $self->ssend($_[0]);
                $self->sget();
        }
        $self->ssend("LOGOUT");
        $self->sget();
        if (/^OK/) {
            undef $self->{_sock};
            return 1;
        };
}

=head2 closedie

send LOGOUT and die

=cut

sub closedie
{
        my $self = shift;
        my $sock = $self->{_sock};
        my $e = $!;
        $self->sfinish();
        $! = $e;
        die @_;
}

=head2 closedie_NOmsg

closedie whitout message

=cut

sub closedie_NOmsg
{
        my $self = shift;
        my $sock = $self->{_sock};
        my $suffix = shift;
        $self->sfinish();
	die $suffix;
}

=head2 die_NOmsg

die

=cut

sub die_NOmsg
{
        my $suffix = shift;
        my $msg = shift;
        if (length $suffix) {
                $msg .= ':' . $suffix . "\n";
        } else {
                $msg .= ".\n";
        }
        die $msg;
}


=head1 BUGS

I don't try plain text or client certificate authentication. 

You can debug TLS connexion with openssl :

   openssl s_client -connect your.server.org:2000 -tls1 -CApath /etc/apache/ssl.crt/somecrt.crt -starttls imap

See response in C<Verify return code:>

Or with gnutls-cli

   gnutls-cli -s -p 4190 --crlf --insecure your.server.org

Use Ctrl+D after STARTTLS to begin TLS negotiation

=head1 SUPPORT

Please report any bugs or feature requests to "bug-net-sieve at rt.cpan.org", or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Sieve>. I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Yves Agostini <yvesago@cpan.org>

=head1 COPYRIGHT

Copyright 2008-2012 Yves Agostini - <yvesago@cpan.org>

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

B<sieve-connect> source code is under a BSD-style license and re-licensed for Net::Sieve with permission of the author.

=head1 SEE ALSO

L<Net::Sieve::Script>

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value


package Net::SSH::Perl::AuthMgr;
use strict;
use warnings;

use Carp qw( croak );

use Net::SSH::Perl::Agent;
use Net::SSH::Perl::Auth;
use Net::SSH::Perl::Constants qw(
    SSH2_MSG_SERVICE_REQUEST
    SSH2_MSG_SERVICE_ACCEPT
    SSH2_MSG_EXT_INFO
    SSH2_MSG_USERAUTH_BANNER
    SSH2_MSG_USERAUTH_REQUEST
    SSH2_MSG_USERAUTH_SUCCESS
    SSH2_MSG_USERAUTH_FAILURE );

use Scalar::Util qw(weaken);

use vars qw( %AUTH_MAP );
%AUTH_MAP = ( password => 'Password',
              publickey => 'PublicKey',
             'keyboard-interactive' => 'KeyboardInt',
			 );

sub new {
    my $class = shift;
    my $ssh = shift;
    my $amgr = bless { ssh => $ssh }, $class;
    weaken $amgr->{ssh};
    $amgr->init(@_);
}

sub init {
    my $amgr = shift;
    my $ssh = $amgr->{ssh};
    my($packet);

    $ssh->debug("Sending request for user-authentication service.");
    $packet = $ssh->packet_start(SSH2_MSG_SERVICE_REQUEST);
    $packet->put_str("ssh-userauth");
    $packet->send;

    $packet = Net::SSH::Perl::Packet->read($ssh);
    if ($packet->type == SSH2_MSG_EXT_INFO) {
        $ssh->debug("SSH2_MSG_EXT_INFO received");
        my $num_ext = $packet->get_int32;
        while ($num_ext) {
            my $name = $packet->get_str;
            my $value = $packet->get_str;
            $ssh->debug("SSH Extension activated: $name=$value");
            $ssh->{$name} = $value;
            $num_ext--;
        }
        $packet = Net::SSH::Perl::Packet->read($ssh);
    }
    croak "Server denied SSH2_MSG_SERVICE_ACCEPT: ", $packet->type
        unless $packet->type == SSH2_MSG_SERVICE_ACCEPT;
    $ssh->debug("Service accepted: " . $packet->get_str . ".");

    if (!$ssh->config->get('identities_only')) {
    	$amgr->{agent} = Net::SSH::Perl::Agent->new(2);
    }

    $amgr->{service} = "ssh-connection";

    $amgr->send_auth_none;

    $amgr;
}

sub agent { $_[0]->{agent} }

sub send_auth_none {
    my $amgr = shift;
    my $ssh = $amgr->{ssh};
    $ssh->debug("Trying empty user-authentication request.");
    my $packet = $ssh->packet_start(SSH2_MSG_USERAUTH_REQUEST);
    $packet->put_str($ssh->config->get('user'));
    $packet->put_str("ssh-connection");
    $packet->put_str("none");
    $packet->send;
}

sub authenticate {
    my $amgr = shift;
    my $ssh = $amgr->{ssh};
    my($packet);

    my $valid = 0;
    $amgr->{_done} = 0;
    $amgr->register_handler(SSH2_MSG_USERAUTH_SUCCESS, sub {
        $valid++;
        $amgr->{_done}++
    });
    $amgr->register_handler(SSH2_MSG_USERAUTH_BANNER, sub {
        my $amgr = shift;
        my($packet) = @_;
        if ($amgr->{ssh}->config->get('interactive')) {
            print $packet->get_str, "\n";
        }
    });
    $amgr->register_handler(SSH2_MSG_USERAUTH_FAILURE, \&auth_failure);
    $amgr->register_error(
        sub { croak "userauth error: bad message during auth" } );
    $amgr->run( \$amgr->{_done} );

    $amgr->{agent}->close_socket if $amgr->{agent};

    $valid;
}

sub auth_failure {
    my $amgr = shift;
    my($packet) = @_;
    my $ssh = $amgr->{ssh};

    my $authlist = $packet->get_str;
    my $partial = $packet->get_int8;
    $ssh->debug("Authentication methods that can continue: $authlist.");

    my($found);
    for my $meth ( split /,/, $authlist ) {
        $found = 0;
        next if !exists $AUTH_MAP{$meth};
        my $auth = $amgr->{_auth_objects}{$meth};
        unless ($auth) {
            $auth = $amgr->{_auth_objects}{$meth} =
                Net::SSH::Perl::Auth->new($AUTH_MAP{$meth}, $ssh);
            $auth->mgr($amgr);
        }
        next unless $auth->enabled;
        $ssh->debug("Next method to try is $meth.");
        $found++;
        if ($auth->authenticate($amgr->{_auth_tried}{$meth}++)) {
            last;
        }
        else {
            $auth->enabled(0);
            delete $amgr->{_auth_objects}{$meth};
            $found = 0;
        }
    }

    $amgr->{_done} = 1 unless $found;
}

sub register_handler { $_[0]->{__handlers}{$_[1]} = $_[2] }
sub remove_handler { delete $_[0]->{__handlers}{$_[1]} }
sub register_error { $_[0]->{__error_handler} = $_[1] }
sub handler_for { $_[0]->{__handlers}{$_[1]} }
sub error_handler { $_[0]->{__error_handler} }

sub run {
    my $amgr = shift;
    my($end, @args) = @_;
    until ($$end) {
        my $packet = Net::SSH::Perl::Packet->read($amgr->{ssh});
        my $code = $amgr->handler_for($packet->type);
        unless (defined $code) {
            $code = $amgr->error_handler ||
                sub { croak "Protocol error: received type ", $packet->type };
        }
        $code->($amgr, $packet, @args);
    }
}

1;
__END__

=head1 NAME

Net::SSH::Perl::AuthMgr - Authentication manager/context for SSH-2

=head1 SYNOPSIS

    use Net::SSH::Perl::AuthMgr;
    my $amgr = Net::SSH::Perl::AuthMgr->new($ssh);
    $amgr->authenticate;

=head1 DESCRIPTION

I<Net::SSH::Perl::AuthMgr> manages authentication methods and auth
context for the SSH-2 authentication process. At its heart is a
dispatch mechanism that waits for incoming packets and responds as
necessary, based on a handler table that maps packet types to
code references.

You should never need to use I<AuthMgr> directly, as it will be
automatically invoked when you call I<login>.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut

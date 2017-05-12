package Net::SSH::Perl::Auth::KeyboardInteractive;

use strict;
use warnings;

use Exporter qw(import);
use Net::SSH::Perl::Constants qw(:msg2);
use Net::SSH::Perl::Util qw(_prompt);
use Scalar::Util qw(weaken);

use base qw(Net::SSH::Perl::Auth);

our @EXPORT_OK = qw(add_kbdint_handler del_kbdint_handler);

sub add_kbdint_handler {
    my ($ssh, $handles, $handler, $pos) = @_;
    my $handlers = $ssh->config->get('auth_kbd_interactive_handlers') || [];
    $pos = @$handlers unless (defined $pos);
    splice @$handlers, $pos, 0, {'handler' => $handler, 'handles' => $handles};
    $ssh->config->set('auth_kbd_interactive_handlers', $handlers);
    return $pos;
}

sub del_kbdint_handler {
    my ($ssh, $pos) = @_;
    my $handlers = $ssh->config->get('auth_kbd_interactive_handlers') or return;
    $pos = -1 unless (defined $pos);
    splice @$handlers, $pos, 1;
    return $pos;
}

sub _dispatch {
    my ($auth, $name, $instruction, $lang, $prompts) = @_;
    foreach (@{$auth->{'_handlers'}}) {
        return $_->{'handler'}
            if ($_->{'handles'}($auth, $name, $instruction, $lang, $prompts));
    }
    return;
}

sub new {
    my ($class, $ssh) = @_;
    my $auth = bless {'ssh' => $ssh}, $class;
    weaken($auth->{'ssh'});
    my $handlers = $ssh->config->get('auth_kbd_interactive_handlers') || [];
    @{$auth->{'_handlers'}} = map { {%$_} } @$handlers; # 1 level deep copy
    $auth->enabled($ssh->config->get('auth_kbd_interactive'));
    return $auth;
}

sub enabled {
    my $self = shift;
    $self->{'enabled'} = shift if (@_);
    return $self->{'enabled'};
}

sub add_handler {
    my ($self, $handles, $handler, $pos) = @_;
    $pos = @{$self->{'_handlers'}} unless (defined $pos);
    splice @{$self->{'_handlers'}}, $pos, 0,
           { 'handler' => $handler, 'handles' => $handles };
    return $pos;
}

sub del_handler {
    my ($self, $pos) = @_;
    return unless (@{$self->{'_handlers'}});
    $pos = -1 unless (defined $pos);
    splice @{$self->{'_handlers'}}, $pos, 1;
    return $pos;
}

sub authenticate {
    my $self = shift;
    my $ssh = $self->{'ssh'};

    return unless ($self->enabled);

    $self->mgr->register_handler(SSH2_MSG_USERAUTH_INFO_REQUEST, sub {
        my ($amgr, $pkt) = @_;
        $ssh->debug('auth keyboard-interactive: rcvd info req');
        my ($name, $instruction, $lang, $n_prompts) =
            ($pkt->get_str, $pkt->get_str, $pkt->get_str, $pkt->get_int32);
        $ssh->debug("auth info req: name='$name' instruction='$instruction' " .
                    "language='$lang' prompts=$n_prompts");
        my @prompts = map { [$pkt->get_str, $pkt->get_int8] } (1 .. $n_prompts);
        my $r_pkt = $ssh->packet_start(SSH2_MSG_USERAUTH_INFO_RESPONSE);
        $r_pkt->put_int32($n_prompts);
        if (my $h = _dispatch($self, $name, $instruction, $lang, \@prompts)) {
            $r_pkt->put_str(&$h($self, $name, $instruction, $lang, @$_))
                for (@prompts);
        } elsif ($ssh->config->get('interactive')) {
            print map { s/[[:cntrl:]]+//g; "$_\n" } grep { length }
                  ($name, $instruction);
            $r_pkt->put_str(_prompt($_->[0], undef, $_->[1])) for (@prompts);
        } elsif ($n_prompts != 0) {
            $ssh->debug('auth keyboard-interactive: cannot handle info req');
            # We're not in interactive mode so we can't prompt anybody
            # and we don't have a handler for this request, so we mark
            # ourselves disabled, and abandon the current info request
            # by sending a new, "none" method, auth request.
            $self->enabled(0);
            $r_pkt = $ssh->packet_start(SSH2_MSG_USERAUTH_REQUEST);
            $r_pkt->put_str($ssh->config->get('user'));	# user
            $r_pkt->put_str('ssh-connection');		# service name
            $r_pkt->put_str('none');			# method name
        }
        $r_pkt->send;
    });

    $ssh->debug('auth keyboard-interactive: send req');
    my $packet = $ssh->packet_start(SSH2_MSG_USERAUTH_REQUEST);
    $packet->put_str($ssh->config->get('user'));	# user
    $packet->put_str('ssh-connection');			# service name
    $packet->put_str('keyboard-interactive');		# method name
    $packet->put_str('');				# language
    $packet->put_str('');				# submethods
    $packet->send;

    return 1;
}

1;

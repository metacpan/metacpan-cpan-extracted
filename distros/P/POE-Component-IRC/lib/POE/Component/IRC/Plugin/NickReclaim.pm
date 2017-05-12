package POE::Component::IRC::Plugin::NickReclaim;
BEGIN {
  $POE::Component::IRC::Plugin::NickReclaim::AUTHORITY = 'cpan:HINRIK';
}
$POE::Component::IRC::Plugin::NickReclaim::VERSION = '6.88';
use strict;
use warnings FATAL => 'all';
use Carp;
use IRC::Utils qw(parse_user);
use POE::Component::IRC::Plugin qw(PCI_EAT_NONE);

sub new {
    my ($package) = shift;
    croak "$package requires an even number of arguments" if @_ & 1;
    my %args = @_;
    $args{ lc $_ } = delete $args{$_} for keys %args;

    if (!defined $args{poll} || $args{poll} !~ /^\d+$/) {
        $args{poll} = 30;
    }

    return bless \%args, $package;
}

sub PCI_register {
    my ($self, $irc) = @_;
    $irc->plugin_register( $self, 'SERVER', qw(001 433 nick quit) );
    $irc->plugin_register( $self, 'USER', qw(nick) );

    $self->{_desired_nick} = $irc->nick_name();
    return 1;
}

sub PCI_unregister {
    return 1;
}

sub U_nick {
    my $self = shift;
    my ($nick) = ${ $_[1] } =~ /^NICK +(.+)/i;

    if (!defined $self->{_temp_nick} || $self->{_temp_nick} ne $nick) {
        delete $self->{_temp_nick};
        $self->{_desired_nick} = $nick;
    }
    return PCI_EAT_NONE;
}

sub S_001 {
    my ($self, $irc) = splice @_, 0, 2;
    $self->{_reclaimed} = $irc->nick_name eq $self->{_desired_nick} ? 1 : 0;
    return PCI_EAT_NONE;
}

# ERR_NICKNAMEINUSE
sub S_433 {
    my ($self, $irc) = splice @_, 0, 2;
    my $offending = ${ $_[2] }->[0];

    if (!$irc->logged_in || $irc->nick_name() eq $offending) {
        my $temp_nick = "${offending}_";
        $self->{_temp_nick} = $temp_nick;

        $irc->yield('nick', $temp_nick);
    }

    $irc->delay_remove($self->{_alarm_id}) if defined $self->{_alarm_id};
    $self->{_alarm_id} = $irc->delay(
        ['nick', $self->{_desired_nick} ],
        $self->{poll}
    );

  return PCI_EAT_NONE;
}

sub S_quit {
    my ($self, $irc) = splice @_, 0, 2;
    my $who = parse_user(${ $_[0] });

    if ($who eq $irc->nick_name) {
        $irc->delay_remove($self->{_alarm_id}) if defined $self->{_alarm_id};
    }
    elsif (!$self->{_reclaimed} && $who eq $self->{_desired_nick}) {
        $irc->delay_remove($self->{_alarm_id}) if defined $self->{_alarm_id};
        $irc->yield('nick', $self->{_desired_nick});
    }

    return PCI_EAT_NONE;
}

sub S_nick {
    my ($self, $irc) = splice @_, 0, 2;
    my $old_nick = parse_user(${ $_[0] });
    my $new_nick = ${ $_[1] };

    if ($new_nick eq $irc->nick_name) {
        if ($new_nick eq $self->{_desired_nick}) {
            $self->{_reclaimed} = 1;
            $irc->delay_remove($self->{_alarm_id}) if defined $self->{_alarm_id};
        }
    }
    elsif ($old_nick eq $self->{_desired_nick}) {
        $irc->delay_remove($self->{_alarm_id}) if defined $self->{_alarm_id};
        $irc->yield('nick', $self->{_desired_nick});
    }

    return PCI_EAT_NONE;
}

1;

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::NickReclaim - A PoCo-IRC plugin for reclaiming
your nickname

=head1 SYNOPSIS

 use strict;
 use warnings;
 use POE qw(Component::IRC Component::IRC::Plugin::NickReclaim);

 my $nickname = 'Flibble' . $$;
 my $ircname = 'Flibble the Sailor Bot';
 my $ircserver = 'irc.blahblahblah.irc';
 my $port = 6667;

 my $irc = POE::Component::IRC->spawn(
     nick => $nickname,
     server => $ircserver,
     port => $port,
     ircname => $ircname,
 ) or die "Oh noooo! $!";

 POE::Session->create(
     package_states => [
         main => [ qw(_start) ],
     ],
 );

  $poe_kernel->run();

 sub _start {
     $irc->yield( register => 'all' );

     # Create and load our NickReclaim plugin, before we connect
     $irc->plugin_add( 'NickReclaim' =>
         POE::Component::IRC::Plugin::NickReclaim->new( poll => 30 ) );

     $irc->yield( connect => { } );
     return;
 }

=head1 DESCRIPTION

POE::Component::IRC::Plugin::NickReclaim - A
L<POE::Component::IRC|POE::Component::IRC> plugin automagically deals with
your bot's nickname being in use and reclaims it when it becomes available
again.

It registers and handles 'irc_433' events. On receiving a 433 event it will
reset the nickname to the 'nick' specified with C<spawn> or C<connect>,
appendedwith an underscore, and then poll to try and change it to the
original nickname. If someone in your channel who has the nickname you're
after quits or changes nickname, the plugin will try to reclaim it
immediately.

=head1 METHODS

=head2 C<new>

Takes one optional argument:

B<'poll'>, the number of seconds between nick change attempts, default is 30;

Returns a plugin object suitable for feeding to
L<POE::Component::IRC|POE::Component::IRC>'s C<plugin_add> method.

=head1 AUTHOR

Chris 'BinGOs' Williams

With amendments applied by Zoffix Znet

=head1 SEE ALSO

L<POE::Component::IRC|POE::Component::IRC>

=cut

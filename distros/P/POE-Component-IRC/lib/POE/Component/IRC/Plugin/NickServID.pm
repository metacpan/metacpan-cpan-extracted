package POE::Component::IRC::Plugin::NickServID;
BEGIN {
  $POE::Component::IRC::Plugin::NickServID::AUTHORITY = 'cpan:HINRIK';
}
$POE::Component::IRC::Plugin::NickServID::VERSION = '6.88';
use strict;
use warnings FATAL => 'all';
use Carp;
use IRC::Utils qw( uc_irc parse_user );
use POE::Component::IRC::Plugin qw( :ALL );

sub new {
    my ($package) = shift;
    croak "$package requires an even number of arguments" if @_ & 1;
    my %self = @_;

    die "$package requires a Password" if !defined $self{Password};
    return bless \%self, $package;
}

sub PCI_register {
    my ($self, $irc) = @_;
    $self->{nick} = $irc->{nick};
    $self->{irc} = $irc;
    $irc->plugin_register($self, 'SERVER', qw(isupport nick notice));
    return 1;
}

sub PCI_unregister {
    return 1;
}

# we identify after S_isupport so that pocoirc has a chance to turn on
# CAPAB IDENTIFY-MSG (if the server supports it) before the AutoJoin
# plugin joins channels
sub S_isupport {
    my ($self, $irc) = splice @_, 0, 2;
    $irc->yield(nickserv => "IDENTIFY $self->{Password}");
    return PCI_EAT_NONE;
}

sub S_nick {
    my ($self, $irc) = splice @_, 0, 2;
    my $mapping = $irc->isupport('CASEMAPPING');
    my $new_nick = uc_irc( ${ $_[1] }, $mapping );

    if ( $new_nick eq uc_irc($self->{nick}, $mapping) ) {
        $irc->yield(nickserv => "IDENTIFY $self->{Password}");
    }
    return PCI_EAT_NONE;
}

sub S_notice {
    my ($self, $irc) = splice @_, 0, 2;
    my $sender    = parse_user(${ $_[0] });
    my $recipient = parse_user(${ $_[1] }->[0]);
    my $msg       = ${ $_[2] };

    return PCI_EAT_NONE if $recipient ne $irc->nick_name();
    return PCI_EAT_NONE if $sender !~ /^nickserv$/i;
    return PCI_EAT_NONE if $msg !~ /now (?:identified|recognized)/;
    $irc->send_event_next('irc_identified');
    return PCI_EAT_NONE;
}

# ERR_NICKNAMEINUSE
sub S_433 {
    my ($self, $irc) = splice @_, 0, 2;
    my $offending = ${ $_[2] }->[0];
    my $reason    = ${ $_[2] }->[1];

    if ($irc->nick_name() eq $offending && $reason eq "Nickname is registered to someone else") {
        $irc->yield(nickserv => "IDENTIFY $self->{Password}");
    }

    return PCI_EAT_NONE;
}
1;

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::NickServID - A PoCo-IRC plugin which identifies with NickServ when needed

=head1 SYNOPSIS

 use POE::Component::IRC::Plugin::NickServID;

 $irc->plugin_add( 'NickServID', POE::Component::IRC::Plugin::NickServID->new(
     Password => 'opensesame'
 ));

=head1 DESCRIPTION

POE::Component::IRC::Plugin::NickServID is a L<POE::Component::IRC|POE::Component::IRC>
plugin. It identifies with NickServ on connect and when you change your nick,
if your nickname matches the supplied password.

B<Note>: If you have a cloak and you don't want to be seen without it, make sure
you don't join channels until after you've identified yourself. If you use the
L<AutoJoin plugin|POE::Component::IRC::Plugin::AutoJoin>, it will be taken
care of for you.

=head1 METHODS

=head2 C<new>

Arguments:

'Password', the NickServ password.

Returns a plugin object suitable for feeding to
L<POE::Component::IRC|POE::Component::IRC>'s plugin_add() method.

=head1 OUTPUT EVENTS

=head2 C<irc_identified>

This event will be sent when you have identified with NickServ. No arguments
are passed with it.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=cut

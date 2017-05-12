# $Id: Telnet.pm 35 2007-10-21 22:23:54Z maletin $
# $URL: http://svn.berlios.de/svnroot/repos/cpan-teamspeak/cpan/trunk/lib/Teamspeak/Telnet.pm $

package Teamspeak::Telnet;

use 5.004;
use strict;
use Carp;
use vars qw( $VERSION );
use Teamspeak::Telnet::Channel;
$VERSION = '0.6';
my @ISA = qw( Teamspeak );

## Module import.
use Net::Telnet;

sub connect {
    my $self = shift;
    my $t    = Net::Telnet->new(
        Timeout => $self->{timeout},
        errmode => [ \&my_die, $self, 'Telnet Timeout' ]
    );
    if ( !$t ) {
        $self->my_die("can't create Telnet-Instance");
        return undef;
    }
    $t->open( Host => $self->{host}, Port => $self->{port} )
        or do {
        $self->my_die("Telnet open $t->errmsg");
        return undef;
        };
    $t->waitfor('/\[TS\]$/');
    $self->{sock} = $t;
}    # connect

sub new {
    my ( $class, %arg ) = @_;
    bless {
        host    => $arg{host}    || 'localhost',
        port    => $arg{port}    || 51234,
        timeout => $arg{timeout} || 4,
        },
        ref($class) || $class;
}    # new

# Server List:
sub sl {
    my $self = shift;
    $self->{sock}->print('sl');
    my ($answer) = $self->{sock}->waitfor('/OK$/');
    return grep( /^\d+$/, split( /\n/, $answer ) );
}

# Select Server:
sub sel {
    my ( $self, $server_id ) = @_;
    $self->{sock}->print("sel $server_id");
    my ($answer) = $self->{sock}->waitfor('/OK$/');
    return 1;
}    # sel

# Superadmin LOGIN:
sub slogin {
    my ( $self, $login, $pwd ) = @_;
    $self->{sock}->print("slogin $login $pwd");
    $self->{sock}->waitfor('/OK$/');
    $self->{slogin} = $login;
    return 1;
}    # slogin

# normal LOGIN:
sub login {
    my ( $self, $login, $pwd ) = @_;
    $self->{sock}->print("login $login $pwd");
    $self->{sock}->waitfor('/OK$/');
    $self->{login} = $login;
    return 1;
}    # login

# Database userlist:
sub dbuserlist {
    my $self   = shift;
    my @result = ();
    if ( !$self->logged_in ) {
        $self->my_die("command needs login");
        return undef;
    }
    $self->{sock}->print('dbuserlist');
    my ( $answer, $match ) = $self->{sock}->waitfor('/(OK|ERROR,.*)$/');
    return @result if ( $match =~ /no data/ );
    my @lines = split( /\n/, $answer );
    shift @lines;    # First Line is empty
    my $fields = shift @lines;
    return unless $fields;
    my @fields = split( /\t/, $fields );

    foreach my $line (@lines) {
        my @r = split( /\t/, $line );
        my %args = map {
            $r[$_] =~ s/^"(.*)"$/$1/;
            $r[$_] =~ s/^(\d\d)-(\d\d)-(\d{4})/$3-$2-$1/;
            $fields[$_] => $r[$_]
        } 0 .. @r - 1;
        push( @result, {%args} );
    }
    return @result;
}    # dbuserlist

# dbuserid
sub dbuserid {
    my $self = shift;
    my $nick = shift;
    $self->{sock}->print( 'dbuserid ' . $nick );
    my ( $answer, $match ) = $self->{sock}->waitfor('/(OK|ERROR*)$/');
    if ( !defined $match or $match =~ /ERROR/ ) {
        $self->my_die($match);
        return undef;
    }
    return int($answer);
}    # dbuserid

# Database userdelete:
sub delete_user {
    my ( $self, $user_id ) = @_;
    $self->{sock}->print("dbuserdel $user_id");
    $self->{sock}->waitfor('/OK$/');
    return 1;
}    # delete_user

# Database useradd:
sub add_user {
    my ( $self, %args ) = @_;
    $args{admin} = 0 if $args{admin} != 1;
    $self->{sock}
        ->print("dbuseradd $args{user} $args{pwd} $args{pwd} $args{admin}");
    $self->{sock}->waitfor('/OK$/');
    return 1;
}    # add_user

# Channel List:
sub cl {
    my $self = shift;
    $self->{sock}->print('cl');
    my ( $answer, $match ) = $self->{sock}->waitfor('/(OK|ERROR.*)$/');
    if ( !defined $match or $match =~ /ERROR/ ) {
        $self->my_die($match);
        return undef;
    }
    my @lines = split( /\n/, $answer );
    shift @lines;    # First Line is empty
    my $fields = shift @lines;
    my @fields = split( /\t/, $fields );
    my @result = ();
    foreach my $line (@lines) {
        my @r = split( /\t/, $line );
        my %args = map {
            $r[$_] =~ s/^"(.*)"$/$1/;
            $r[$_] =~ s/^(\d\d)-(\d\d)-(\d{4})/$3-$2-$1/;
            $fields[$_] => $r[$_]
        } 0 .. @r - 1;
        my $ch = Teamspeak::Telnet::Channel->new(%args);
        $ch->{tsh} = $self;
        $self->{channel}{ $r[0] } = $ch;
    }
    return scalar keys %{ $self->{channel} };
}    # cl

# Player Information
sub pi {
    my $self     = shift;
    my $playerid = shift;
    $self->{sock}->print( 'pi ' . $playerid );
    my ( $answer, $match ) = $self->{sock}->waitfor('/(OK|ERROR.*)$/');
    if ( !defined $match or $match =~ /ERROR/ ) {
        $self->my_die($match);
        return undef;
    }
    my @lines = split( /\n/, $answer );
    shift @lines;    # First Line is empty
    my $fields = shift @lines;
    my @fields = split( /\t/, $fields );
    my @result = ();
    my $line   = shift @lines;
    my @r      = split( /\t/, $line );
    my %args   = map {
        $r[$_] =~ s/^"(.*)"$/$1/;
        $fields[$_] => $r[$_]
    } 0 .. @r - 1;
    return \%args;
}    # pi

# Player List:
sub pl {
    my $self = shift;
    $self->{sock}->print('pl');
    my ( $answer, $match ) = $self->{sock}->waitfor('/(OK|ERROR.*)$/');
    if ( !defined $match or $match =~ /ERROR/ ) {
        $self->my_die($match);
        return undef;
    }
    my @lines = split( /\n/, $answer );
    shift @lines;    # First Line is empty
    my $fields = shift @lines;
    my @fields = split( /\t/, $fields );
    my @result = ();
    foreach my $line (@lines) {
        my @r = split( /\t/, $line );
        my %args = map {
            $r[$_] =~ s/^"(.*)"$/$1/;
            $r[$_] =~ s/^(\d\d)-(\d\d)-(\d{4})/$3-$2-$1/;
            $fields[$_] => $r[$_]
        } 0 .. @r - 1;
        push( @result, {%args} );
    }
    return @result;
}    # pl

# Find Player(s):
sub fp {
    my $self = shift;
    my $nick = shift;
    if ( $nick =~ / / ) {

       # the nickname contains a space-char and we cannot escape that space
       # for the fp-command, so we use the output of pl to simulate the result
        my @plresult = $self->pl();
        if (@plresult) {
            my @result = ();
            foreach my $playerref (@plresult) {
                my %player = %{$playerref};
                if (   ( $player{nick} =~ /$nick/ )
                    || ( $player{loginname} =~ /$nick/ ) )
                {
                    my %args = (
                        p_id      => $player{p_id},
                        p_dbid    => 0,
                        c_id      => $player{c_id},
                        nickname  => $player{nick},
                        loginname => $player{loginname},
                        ip        => $player{ip}
                    );
                    if ( $player{loginname} )
                    { # player has an loginname, so he has a dbid too, but we dont get that via pl, so ask pi
                        my $piinforef = $self->pi( $player{p_id} );
                        if ($piinforef) {
                            my %piinfo = %{$piinforef};
                            $args{p_dbid} = $piinfo{p_dbid};
                        }
                    }
                    push( @result, \%args );
                }
            }
            return @result;
        }
        else {
            return undef;
        }
    }
    else {
        $self->{sock}->print( 'fp ' . $nick );
        my ( $answer, $match ) = $self->{sock}->waitfor('/(OK|ERROR.*)$/');
        if ( !defined $match or $match =~ /ERROR/ ) {
            $self->my_die($match);
            return undef;
        }
        my @lines = split( /\n/, $answer );
        shift @lines;    # First Line is empty
        my $fields = shift @lines;
        my @fields = split( /\t/, $fields );
        my @result = ();
        foreach my $line (@lines) {
            my @r = split( /\t/, $line );
            my %args = map {
                $r[$_] =~ s/^"(.*)"$/$1/;
                $fields[$_] => $r[$_]
            } 0 .. @r - 1;
            push( @result, {%args} );
        }
        return @result;
    }
}    # fp

# adds an IP ban to the banlist (optional with time)
sub banadd {
    my $self = shift;
    my $ip   = shift;
    my $time = shift;
    $self->{sock}->print( 'banadd ' . $ip . ' ' . $time );
    my ( $answer, $match ) = $self->{sock}->waitfor('/(OK|ERROR.*)$/');
    if ( !defined $match or $match =~ /ERROR/ ) {
        $self->my_die($match);
        return undef;
    }
    return 1;
}    # banadd

# bans the IP of a currently connected player
sub banplayer {
    my $self      = shift;
    my $player_id = shift;
    my $time      = shift;
    $self->{sock}->print( 'banplayer ' . $player_id . ' ' . $time );
    my ( $answer, $match ) = $self->{sock}->waitfor('/(OK|ERROR.*)$/');
    if ( !defined $match or $match =~ /ERROR/ ) {
        $self->my_die($match);
        return undef;
    }
    return 1;
}    # banplayer

# kick a player of the server
sub kick {
    my $self      = shift;
    my $player_id = shift;
    $self->{sock}->print( 'kick ' . $player_id );
    my ( $answer, $match ) = $self->{sock}->waitfor('/(OK|ERROR.*)$/');
    if ( !defined $match or $match =~ /ERROR/ ) {
        $self->my_die($match);
        return undef;
    }
    return 1;
}    # kick

# set attributes of virtual servers
sub serverset {
    my $self            = shift;
    my $attribute_name  = shift;
    my $attribute_value = shift;

    #?? surround the value with "" ?
    $self->{sock}
        ->print( 'serverset ' . $attribute_name . ' ' . $attribute_value );
    my ( $answer, $match ) = $self->{sock}->waitfor('/(OK|ERROR.*)$/');
    if ( !defined $match or $match =~ /ERROR/ ) {
        $self->my_die($match);
        return undef;
    }
    return 1;
}    # serverset

# gets the average packet loss
sub gapl {
    my $self = shift;
    my $port = shift;
    if   ($port) { $self->{sock}->print( 'gapl ' . $port ); }
    else         { $self->{sock}->print('gapl'); }
    my ( $answer, $match ) = $self->{sock}->waitfor('/(OK|ERROR.*)$/');
    if ( !defined $match or $match =~ /ERROR/ ) {
        $self->my_die($match);
        return undef;
    }
    $answer =~ /=([\d\.]+)%/;
    return $1;
}    # gapl

# move a player to a channel
sub mptc {
    my $self       = shift;
    my $channel_id = shift;
    my $player_id  = shift;
    $self->{sock}->print( 'mptc ' . $channel_id . ' ' . $player_id );
    my ( $answer, $match ) = $self->{sock}->waitfor('/(OK|ERROR.*)$/');
    if ( !defined $match or $match =~ /ERROR/ ) {
        $self->my_die($match);
        return undef;
    }
    return 1;
}    # mptc

# disconnect a user silently from the server
sub removeclient {
    my $self      = shift;
    my $player_id = shift;
    $self->{sock}->print( 'removeclient ' . $player_id );
    my ( $answer, $match ) = $self->{sock}->waitfor('/(OK|ERROR.*)$/');
    if ( !defined $match or $match =~ /ERROR/ ) {
        $self->my_die($match);
        return undef;
    }
    return 1;
}    # removeclient

# Message to selected virtual server:
sub msg {
    my $self = shift;
    my $text = shift;
    $self->{sock}->print( 'msg ' . $text );
    my ( $answer, $match ) = $self->{sock}->waitfor('/(OK|ERROR.*)$/');
    if ( !defined $match or $match =~ /ERROR/ ) {
        $self->my_die($match);
        return undef;
    }
    return 1;
}    # msg

# Message to a user of the selected virtual server:
sub msgu {
    my $self = shift;
    my $dbid = shift;
    my $text = shift;
    $self->{sock}->print( 'msgu ' . $dbid . ' ' . $text );
    my ( $answer, $match ) = $self->{sock}->waitfor('/(OK|ERROR.*)$/');
    if ( !defined $match or $match =~ /ERROR/ ) {
        $self->my_die($match);
        return undef;
    }
    return 1;
}    # msgu

# Disconnect:
sub disconnect {
    my $self = shift;
    $self->{sock}->print('quit');
    delete $self->{sock};
}

sub my_die {
    my ( $self, @msg ) = @_;
    $self->{err} = 1;
    @msg = ('unknown error') if ( !@msg );
    $self->{errmsg} = "@msg";
    carp "my_die @msg";
}

sub logged_in {
    my $self = shift;
    return 2 if ( defined $self->{slogin} );
    return 1 if ( defined $self->{login} );
    return 0;
}

sub channels {
    if ( defined $_[0]->{channel} and ref( $_[0]->{channel} ) eq 'HASH' ) {
        return keys( %{ $_[0]->{channel} } );
    }
    else {
        return undef;
    }
}    # channels

1;

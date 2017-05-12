# $Id: SQL.pm 35 2007-10-21 22:23:54Z maletin $
# $URL: http://svn.berlios.de/svnroot/repos/cpan-teamspeak/cpan/trunk/lib/Teamspeak/SQL.pm $

package Teamspeak::SQL;

use 5.004;
use strict;
use DBI;
use Teamspeak::SQL::Channel;
use vars qw( $VERSION );
$VERSION = '0.6';
my @ISA = qw( Teamspeak );

sub connect {
    my ( $self, $user, $pwd ) = @_;
    my $dsn;
    if ( $self->{d_file} ) {
        $dsn = "dbi:SQLite2:dbname=$self->{d_file}";
        $user = $pwd = '';
    }
    else {
        $dsn = "dbi:mysql:database=$self->{d_db}";
        $dsn .= ";hostname=$self->{d_host};port=$self->{d_port}";
    }
    my $m = DBI->connect( $dsn, $user, $pwd );
    $self->{db} = $m;
}    # connect

sub new {
    my ( $class, %arg ) = @_;
    my $s;
    if ( $arg{file} ) {
        $s = { d_file => $arg{file} };
    }
    else {
        $s = {
            d_host => $arg{host} || 'localhost',
            d_port => $arg{port} || 3306,
            d_db   => $arg{db}   || 'teamspeak',
        };
    }
    bless $s, ref($class) || $class;
}    # new

sub get_channel {
    my $self = shift;
    $self->{channel} = {};    # Forget old values.
    my $s = 'select * from ts2_channels';
    my $all = $self->{db}->selectall_hashref( $s, 'i_channel_id' );
    foreach my $c ( keys %$all ) {
        $all->{$c}{tsh} = $self;    # a channel belongs to a Teamspeak-Handle.
        $self->{channel}{$c} = bless( $all->{$c}, 'Teamspeak::Channel' );
    }
    return keys %{ $self->{channel} };
}    # get_channel

sub sl {
    my $self = shift;
    my $s    = 'select * from ts2_servers';
    return $self->{db}->selectall_hashref( $s, 'i_server_id' );
}    # sl

1;

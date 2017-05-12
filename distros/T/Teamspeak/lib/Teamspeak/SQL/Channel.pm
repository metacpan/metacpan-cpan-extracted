# $Id: Channel.pm 37 2008-03-09 01:10:00Z maletin $
# $URL: http://svn.berlios.de/svnroot/repos/cpan-teamspeak/cpan/trunk/lib/Teamspeak/SQL/Channel.pm $

package Teamspeak::SQL::Channel;
my @ISA = qw( Teamspeak::Channel );

my @_parameter = (
    's_channel_description',  'dt_channel_created',
    's_channel_name',         'i_channel_parent_id',
    'i_channel_codec',        'b_channel_flag_hierarchical',
    's_channel_topic',        'i_channel_order',
    's_channel_password',     'b_channel_flag_moderated',
    'b_channel_flag_default', 'i_channel_maxusers',
    'i_channel_server_id'
);

sub store {
    my $self = shift;
    my $sql
        = "update ts2_channels set "
        . join( ', ', map {"$_ = ?"} @_parameter )
        . " where i_channel_id = ?";
    my $rows_affected
        = $self->{dbh}->do( $sql, {}, map( { $self->{$_} } @_parameter ),
        $self->{i_channel_id} );
    if ( $rows_affected == 1 or $rows_affected == 0 ) {
        return 1;    # Even unmodified Channels report sucess.
    }
    else {
        $self->{err}    = 1;
        $self->{errstr} = "$rows_affected Channels modified.";
        return 0;  # should never happen, because i_channel_id is primary key.
    }
}    # Teamspeak::Channel::store

sub parameter {
    my $self = shift;
    return map { $_ =~ m/.+_channel_(.*)/; $1 } @_parameter;
}    # Teamspeak::Channel::parameter

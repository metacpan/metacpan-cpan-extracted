package Proc::Scoreboard;

$Proc::Scoreboard::VERSION = (split " ", '# 	$Id: Scoreboard.pm,v 1.1 2000/08/23 16:59:05 mkul Exp $	')[3];;

=head1 NAME

Proc::Scoreboard - interface scoreboard class

=head1 SYNOPSIS

 use Proc::Scoreboard;
 my $scoreboard = new Proc::Scoreboard ( ... );
 my @idList = $scoreboard->list ();
 $scoreboard->add    ( $id );
 $scoreboard->delete ( $id );
 $scoreboard->modify ( $id, %hash );

=head1 DESCRIPTION

Intertface class for scoreboard.

=cut

=head2 new

The constructor

=cut

sub new
{
    my ( $class, %params ) = @_;
    bless { %params }, $class;
}

=head2 add

 $sb->add ( $id );

add new board with id $id to scoreboard

=cut

sub add
{
}

=head2 delete

 $sb->delete ( $id );

delete board with id $id from scoreboard

=cut

sub delete
{
}

=head2 modify

 $db->modify ( $id, %hash );

modify board with id $id by passed parameters

=cut

sub modify
{
}

=head2 list

return list of all known scoreboards id's

=cut

sub list
{
    my $this = shift;
}

1;

__END__

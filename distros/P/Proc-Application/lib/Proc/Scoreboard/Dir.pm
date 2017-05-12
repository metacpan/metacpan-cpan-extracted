package Proc::Scoreboard::Dir;

$Proc::Scoreboard::VERSION = (split " ", '# 	$Id: Dir.pm,v 1.1 2000/09/18 11:19:43 mkul Exp $	')[3];;

=head1 NAME

Proc::Scoreboard - interface scoreboard class

=head1 SYNOPSIS

 use Proc::Scoreboard::Dir;
 my $scoreboard = new Proc::Scoreboard ( Directory => '/var/scoreboard' );
 my @idList = $scoreboard->list ();
 $scoreboard->add    ( $pid );
 $scoreboard->delete ( $pid );
 $scoreboard->modify ( $pid, %hash );

=head1 DESCRIPTION

Intertface class for scoreboard.

=cut

=head2 new

The constructor

=cut

use IO::Dir;
use IO::File;

sub new
{
    my ( $class, %params ) = @_;
    my $this = $class->SUPER::new ( %params );
    my $dirName = $this->{Directory} || die "You must pass Directory parameter for Proc::Scoreboard::Dir::new()";
    $this->{dir} = new IO::Dir ( $dirName ) || "Error open dir $dirName; $!";
    $this;
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
    $this->{dir}->rewind();
    my @result = $this->{dir}->read();
    @result;
}

1;

__END__

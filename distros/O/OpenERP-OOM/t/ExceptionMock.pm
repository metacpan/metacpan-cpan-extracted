package ExceptionMock;

use Moose;

has succeeded => (is => 'rw', isa => 'Bool', default => 0);
has transaction_fails => (is => 'ro', isa => 'Int', required => 1);
has other_fail => (is => 'ro', isa => 'Bool', default => 0);
has calls => (is => 'rw', isa => 'Int', default => 0);

sub run
{
    my $self = shift;
    return sub {
        $self->calls($self->calls + 1);
        print "call\n";
        if($self->calls <= $self->transaction_fails)
        {
            die '-- current transaction is aborted, commands ignored until end of transaction block --';
        }
        if($self->other_fail)
        {
            die 'Some other exception';
        }
        $self->succeeded(1);
    };
}


1;

package TM::Synchronizable::Null;

use Class::Trait 'base';
use Class::Trait qw(TM::Synchronizable);

sub source_in {
    my $self = shift;
    $self->{_ins}++;
}

sub source_out {
    my $self = shift;
    $self->{_outs}++;
}

1;



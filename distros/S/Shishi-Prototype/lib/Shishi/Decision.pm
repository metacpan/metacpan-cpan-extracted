package Shishi::Decision;
use Exporter;

use constant ACTION_FINISH   => 0;
use constant ACTION_REDUCE   => 1;
use constant ACTION_SHIFT    => 2;
use constant ACTION_CODE     => 3;
use constant ACTION_CONTINUE => 4;
use constant ACTION_FAIL     => 5;

@Shishi::Decision::ISA = qw( Exporter );
@Shishi::Decision::EXPORT = qw( ACTION_FINISH ACTION_REDUCE ACTION_CODE
ACTION_SHIFT ACTION_CONTINUE ACTION_FAIL);

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub next_node {
    my $self = shift;
    if (@_) { $self->{next_node} = shift } else { $self->{next_node} }
}

1;


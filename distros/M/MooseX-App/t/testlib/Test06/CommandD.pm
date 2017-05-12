package Test06::CommandD;

use Moose;
use MooseX::App::Command;
extends qw(Test06);

option 'list' => (
    isa         => 'ArrayRef[Str]',
    is          => 'rw',
);

option 'hash' => (
    isa         => 'HashRef[Str]',
    is          => 'rw',
);

sub run {
    my ($self) = @_;
    use Data::Dumper;
    {
      local $Data::Dumper::Maxdepth = 2;
      warn __FILE__.':line'.__LINE__.':'.Dumper($self);
    }
}

1;
package Test03::DifferentCommand;

use MooseX::App::Command;
extends qw(Test03CommandBase);

option 'hash' => (
    is            => 'rw',
    isa           => 'HashRef',
);

option 'integer' => (
    is            => 'rw',
    isa           => 'Int',
);

option 'list' => (
    is            => 'rw',
    isa           => 'ArrayRef',
);

option 'string' => (
    is            => 'rw',
    isa           => 'Str',
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
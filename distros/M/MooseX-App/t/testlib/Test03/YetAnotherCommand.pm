package Test03::YetAnotherCommand;

use MooseX::App::Command;
extends qw(Test03CommandBase);
with qw(MooseX::App::Role::Common);

option 'bool1' => (
    is            => 'rw',
    isa           => 'Bool',
    cmd_flag      => 'a',
);

option 'bool2' => (
    is            => 'rw',
    isa           => 'Bool',
    cmd_flag      => 'b',
    default       => 1,
);

option 'bool3' => (
    is            => 'rw',
    isa           => 'Bool',
    required      => 1,
    cmd_negate    => ['no-bool3'],
);

option 'value' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    default       => sub { return "hase" },
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
package Test03::AnotherCommand;

use MooseX::App::Command;
extends qw(Test03CommandBase);

use Moose::Util::TypeConstraints;

subtype 'Test03::Type::Custom1',
    as 'Int',
    where { $_ > 10 },
    message { "Must be greater than 10" };

subtype 'Test03::Type::Custom2',
    as 'ScalarRef';

coerce 'Test03::Type::Custom2',
    from 'Str',
    via { \$_ };

no Moose::Util::TypeConstraints;

option 'hash' => (
    is            => 'rw',
    isa           => 'HashRef',
);

option 'integer' => (
    is            => 'rw',
    isa           => 'Int',
);

option 'number' => (
    is            => 'rw',
    isa           => 'Num',
);

option 'custom1' => (
    is            => 'rw',
    isa           => 'Test03::Type::Custom1',
);

option 'custom2' => (
    is            => 'rw',
    isa           => 'Test03::Type::Custom2',
    coerce        => 1,
);

option 'split' => (
    is            => 'rw',
    isa           => 'ArrayRef[Str]',
    cmd_split     => qr/;/i,
);

option 'count' => (
    is            => 'rw',
    cmd_count     => 1,
);

option ['extra1','extra2'] => (
    is            => 'rw',
);

sub run {
    my ($self) = @_;
}

1;
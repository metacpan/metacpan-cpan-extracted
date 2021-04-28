use Test2::V0;

use Sub::Meta;

sub param {
    my @args = @_;
    return Sub::Meta::Param->new(@args)
}

my $parameters = Sub::Meta::Parameters->new(args => []);

is $parameters->slurpy, undef, 'slurpy';

is $parameters->set_slurpy('Str'), $parameters, 'set_slurpy / Str';
is $parameters->slurpy, param(type => 'Str');

is $parameters->set_slurpy(param(type => 'Int')), $parameters, 'set_slurpy / param(type => Int)';
is $parameters->slurpy, param(type => 'Int'), 'slurpy';

my $some = bless {}, 'Some';
is $parameters->set_slurpy($some), $parameters, 'set_slurpy / $some';
is $parameters->slurpy, param(type => $some), 'slurpy';

done_testing;

use
    if (!eval { require namespace::autoclean; 1 }),
    'Test::More', skip_all => "requires namespace::autoclean";
use
    if (!eval { require Sub::Identify; 1 }),
    'Test::More', skip_all => "requires Sub::Identify";
use Test::More;

BEGIN { $ENV{PERL_MOOS_XS_DISABLE} = 1 };

{
    package Foos;
    use Moos;
    use namespace::autoclean;
    has 'foo';
}

can_ok Foos => 'foo';

is(
    Sub::Identify::sub_fullname(Foos->can('foo')),
    'Foos::foo',
);

done_testing;



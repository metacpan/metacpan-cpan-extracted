use inc::Module::Install;

name            'Net-Journyx';
all_from        'lib/Net/Journyx.pm';

requires        'Moose' => '0.50';
requires        'MooseX::Role::Parameterized' => '0.03';
requires        'LWP::UserAgent';
requires        'URI';

requires        'XML::Compile';
requires        'XML::Compile::SOAP';

build_requires  'Test::More';
build_requires  'Test::MockObject';

features(
    'Date loading' => [
        -default => 0,
       recommends( 'DateTime')
    ],
);

WriteAll;


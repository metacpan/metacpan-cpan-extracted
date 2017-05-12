use inc::Module::Install;

name          ('Perl6-Signature');
license       ('MIT');
all_from      ('lib/Perl6/Signature.pm');
requires      ('Moose'             => 0.33,
               'Text::Balanced'    => 0,
               'Parse::RecDescent' => 0);

build_requires('Test::More'        => 0,
               'Test::Exception'   => 0);
#sign;

WriteAll;

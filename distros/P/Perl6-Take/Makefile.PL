use inc::Module::Install;

name('Perl6-Take');
license('MIT');
all_from('lib/Perl6/Take.pm');
build_requires(
        'Test::More'      =>'0.31',
        'Test::Exception' => 0,
);
sign;

auto_install;
WriteAll;

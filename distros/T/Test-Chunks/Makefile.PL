use inc::Module::Install;

name('Test-Chunks');
author('Brian Ingerson <ingy@cpan.org>');
abstract('A Data Driven Testing Framework');
license('perl');
version_from('lib/Test/Chunks.pm');

requires(qw(
    Test::Base 0.40
    perl 5.6.1
    Spiffy 0.24
    Test::More 0.54
));

check_nmake();

&WriteAll();

use inc::Module::Install;

name('Pointer');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Object Oriented Memory Pointers in Pure Perl');
version_from('lib/Pointer.pm');
license('perl');

requires(
    perl =>   '5.6.1',
    Spiffy => '0.23',
);

&WriteAll();

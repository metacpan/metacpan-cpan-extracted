use inc::Module::Install;

name('Spork-Hilite');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Hilite Code Snippets in Spork');
license('perl');
version_from('lib/Spork/Hilite.pm');

requires(qw(
    perl 5.6.1
    Spork 0
));

check_nmake();

&WriteAll();

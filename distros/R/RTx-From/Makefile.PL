use inc::Module::Install;
requires 'RT' => 0;

author('Jerrad Pierce <jpierce@cpan.org>');
abstract('Make it easier to find users and their tickets');
license('perl');

RTx('RTx-From');
WriteAll();

sub MY::postamble {
    package MY;
    "\npredist: all\n" .
    "\tpod2readme  lib/RTx/From.pm > README\n"
}

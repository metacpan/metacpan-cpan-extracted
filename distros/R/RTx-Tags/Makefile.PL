use inc::Module::Install;
#requires 'HTML::TagCloud' => 0;
requires 'RT' => 0;

author('Jerrad Pierce <jpierce@cpan.org>');
abstract('Tag cloud and simple searchable custom fields');
license('perl');

RTx('RTx-Tags');
WriteAll();

sub MY::postamble {
    package MY;
    "\npredist: all\n" .
    "\tpod2readme  lib/RTx/Tags.pm > README\n"
}

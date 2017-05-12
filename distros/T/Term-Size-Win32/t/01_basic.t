
use Test::More tests => 6;

BEGIN { use_ok('Term::Size::Win32'); }

@chars = Term::Size::Win32::chars;
ok(@chars == 2);

@chars1 = Term::Size::Win32::chars *STDERR;
is_deeply([@chars], [@chars1]);

$cols = Term::Size::Win32::chars;
is($cols, $chars[0]);

@pixels = Term::Size::Win32::pixels;
ok(@pixels==2);

$x = Term::Size::Win32::pixels;
ok($x == $pixels[0]);

diag("This terminal is $chars[0]x$chars[1] characters,"),
diag("  and $pixels[0]x$pixels[1] pixels.");

# TODO
# * this should test Term::Size::Win32::Win32 not Term::Size::Win32
# * not happy with these final messages

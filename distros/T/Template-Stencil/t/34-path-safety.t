#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Template::Stencil;

my $dir = File::Temp::tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/real.tmpl" or die $!;
print $fh 'real';
close $fh;

# A secret file one level above template_dir.
my $parent = File::Temp::tempdir(CLEANUP => 1);
mkdir "$parent/tpl" or die $!;
open $fh, '>', "$parent/secret.txt" or die $!;
print $fh 'SECRET';
close $fh;
open $fh, '>', "$parent/tpl/ok.tmpl" or die $!;
print $fh 'ok';
close $fh;

my $e = Template::Stencil::_engine_new("$parent/tpl", undef, 0, 1, 256);

# Absolute paths and traversal are never treated as files: the argument
# renders as literal source text instead of reading the file.
is(Template::Stencil::_engine_render($e, "$parent/secret.txt", {}),
   "$parent/secret.txt", 'absolute path not read (renders as text)');
is(Template::Stencil::_engine_render($e, '../secret.txt', {}),
   '../secret.txt', 'traversal not read (renders as text)');
is(Template::Stencil::_engine_render($e, 'ok', {}), 'ok',
   'safe name still resolves');

# Includes reject unsafe names outright.
eval { Template::Stencil::_engine_render($e,
    "{% include $parent/secret.txt %}", {}) };
like($@, qr/cannot find include/, 'absolute include rejected');
eval { Template::Stencil::_engine_render($e,
    '{% include ../secret.txt %}', {}) };
like($@, qr/cannot find include/, 'traversal include rejected');
eval { Template::Stencil::_engine_render($e,
    '{% include a/../../secret.txt %}', {}) };
like($@, qr/cannot find include/, 'embedded .. rejected');

# Backslash is a separator to the traversal scan on every platform, not
# just the one where the kernel would honour it.
eval { Template::Stencil::_engine_render($e,
    '{% include ..\\secret.txt %}', {}) };
like($@, qr/cannot find include/, 'backslash traversal rejected');
eval { Template::Stencil::_engine_render($e,
    '{% include a\\..\\..\\secret.txt %}', {}) };
like($@, qr/cannot find include/, 'embedded backslash .. rejected');
eval { Template::Stencil::_engine_render($e,
    '{% include \\secret.txt %}', {}) };
like($@, qr/cannot find include/, 'leading backslash rejected');

Template::Stencil::_engine_free($e);

done_testing;

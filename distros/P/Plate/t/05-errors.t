#!perl -T
use 5.020;
use warnings;
use Test::More tests => 49;

BEGIN {
    if ($ENV{AUTHOR_TESTING}) {
        require Devel::Cover;
        import Devel::Cover -db => 'cover_db', -coverage => qw(branch condition statement subroutine), -silent => 1, '+ignore' => qr'^t/';
    }
}

use Plate;

my $warned;
$SIG{__WARN__} = sub {
    $warned = 1;
    goto &diag;
};

END {
    unlink 't/tmp_dir/outer.pl';
    rmdir 't/tmp_dir/data';
    rmdir 't/tmp_dir';
}

like eval { Plate->new(invalid => 1) } // $@,
qr"^\QInvalid setting 'invalid' at ", "Can't set invalid settings";

like eval { Plate->new(cache_path => '/no/such/path/ exists') } // $@,
qr"^Can't create cache directory ", "Can't set invalid cache_path";

SKIP: {
    skip 'Test unwriteable cache_path, but / is writeable', 1 if -w '/';

    like eval { Plate->new(cache_path => '/') } // $@,
    qr"^Cache directory / is not writeable", "Can't set unwriteable cache_path";
}

like eval { Plate->new(path => '/no/such/path/ exists') } // $@,
qr"^Can't set path to ", "Can't set invalid path";

like eval { Plate->new(filters => 'not a hash') } // $@,
qr"^\QInvalid filters (not a hash reference) ", "Can't set invalid filters";

like eval { Plate->new(vars => ['not a hash']) } // $@,
qr"^\QInvalid vars (not a hash reference) ", "Can't set invalid vars";

like eval { Plate->new(package => 'Not:Valid') } // $@,
qr"^Invalid package name ", "Can't set invalid package name";

like eval { Plate->new(package => undef) } // $@,
qr"^Invalid package name ", "Can't set undefined package name";

like eval { Plate::does_exist('text', 'html') } // $@,
qr"^Can only be called as a subroutine from within a template", "Can't call Plate::does_exist outside a template";

like eval { Plate::can_serve('text', 'html') } // $@,
qr"^Can only be called as a subroutine from within a template", "Can't call Plate::can_serve outside a template";

like eval { Plate::filter('text', 'html') } // $@,
qr"^Can only be called as a subroutine from within a template", "Can't call Plate::filter outside a template";

my $plate = Plate->new(cache_code => undef);

like eval { $plate->set(filters => { -test => 'no::such_sub' }) } // $@,
qr"^Invalid filter name '-test' ", "Can't set invalid filter name";

like eval { $plate->set(filters => { test => 'no::such_sub' }) } // $@,
qr"^Invalid subroutine 'no::such_sub' for filter 'test' ", "Can't set invalid filter sub";

like eval { $plate->serve(undef) } // $@,
qr"^Template name is undefined ", "Can't serve undef";

ok !eval { $plate->define(err => <<'PLATE');
% No opening tag
</%def>
PLATE
}, 'Missing opening %def tag';
like $@, qr"^\QClosing </%def> tag without opening <%def...> tag at err line 2.
Plate compilation failed", 'Expected error';

ok !eval { $plate->define(err => <<'PLATE');
%% No closing tag
<%%def -missing>
PLATE
}, 'Missing closing %def tag';
like $@, qr"^\QOpening <%%def...> tag without closing </%%def> tag at err line 1.
Plate precompilation failed", 'Expected error';

ok !eval { $plate->define(err => <<'PLATE');
Check missing
<&& .missing &&>
<%%def .missing>
Defined too late
</%%def>
PLATE
}, 'Must declare %def blocks before use';
is 0+$!, 2, 'Expected errno';
like $@, qr"^\QCan't read .missing.plate: $! at err line 2.
Plate precompilation failed", 'Expected error';

$plate->define(err => <<'PLATE');
L1
<& .missing &>
PLATE
ok !eval { $plate->serve('err') }, "Can't include missing template";

SKIP: {
    skip 'Broken before v5.21.6 - RT#122695', 2 if $] < 5.021_006;

    is $@, "Can't read .missing.plate: $! at err line 2.\n", 'Expected error';

    eval { $plate->define(err => <<'PLATE') };
L1
<& _, oops &>
PLATE
    like $@, qr/^Bareword "oops" not allowed while "strict subs" in use at err line 2.\n/,
    'Correct line number';
}

$plate->define(err => <<'PLATE');
%% 0;
Defined only in precompilation
<%%def .missing>
</%%def>
<& .missing &>
PLATE
ok !eval { $plate->serve('err') }, "Can't use precompiled %def blocks during runtime";
is 0+$!, 2, 'Expected errno';
is $@, "Can't read .missing.plate: $! at err line 5.\n", 'Expected error';

$plate->set(cache_code => 1, filters => { gone => sub {''}, html => undef });
like eval { $plate->serve(\'<% 1 %>') } // $@,
qr"^No 'html' filter defined ", 'Invalid auto_filter';

$plate->define(err => '<% 1 |gone %>');
$plate->set(filters => { gone => undef });
like eval { $plate->serve('err') } // $@,
qr"^No 'gone' filter defined ", 'Deleted filter';

$plate->define(err => '<& err &>');
is eval { $plate->serve_with(\' ', 'err') } // $@,
qq'Call depth limit exceeded while calling "err" at err line 1.\n', 'Error on deep recursion';

$plate->set(max_call_depth => 9);
$plate->define(err => <<'PLATE');
% if (my $v = shift) {
<% $v |%><& err, @_ &>
% }
PLATE
is eval { $plate->serve('err', 1..8) } // $@,
'12345678', 'No error on shallow recursion';

is eval { $plate->serve('err', 1..9) } // $@,
qq'Call depth limit exceeded while calling "err" at err line 2.\n', 'Error on shallow recursion (set max_call_depth)';

rmdir 't/tmp_dir' or diag "Can't remove t/tmp_dir: $!" if -d 't/tmp_dir';
$plate->set(path => 't', cache_path => 't/tmp_dir', umask => 027);
rmdir 't/tmp_dir' or diag "Can't remove t/tmp_dir: $!";
like eval { $plate->serve('data/faulty') } // $@,
qr"^Can't create cache directory \./t/tmp_dir/data: ", 'Error creating cache directory';

$plate->set(path => undef);
like eval { $plate->serve('outer') } // $@,
qr"^Plate template 'outer' does not exist ", 'Missing cache file on undefined path';

$plate->set(path => 't');
if (open my $fh, '>', 't/tmp_dir/outer.pl' or diag "Can't create t/tmp_dir/outer.pl: $!") {
    close $fh;
}
like eval { $plate->serve('outer') } // $@,
qr"^Can't read t/outer\.plate: ", 'Missing template to reload from';

if (open my $fh, '>', 't/tmp_dir/outer.pl' or diag "Can't create t/tmp_dir/outer.pl: $!") {
    print $fh '{';
    close $fh;
}
$plate->set(path => 't/data');
like eval { $plate->serve('outer') } // $@,
qr/^syntax error /m, 'Error parsing cache file';

is delete $$plate{mod}{outer}, undef, "Don't keep stat of faulty cache file";

$plate->set(cache_code => 0, static => 1);
like eval { $plate->serve('outer') } // $@,
qr/^syntax error /m, 'Error parsing cache file (static mode)';

is delete $$plate{mod}{outer}, undef, "Don't keep stat of faulty cache file (static mode)";

chmod 0, 't/tmp_dir/outer.pl';
SKIP: {
    skip "Can't chmod 0 to test unreability", 4 if -r 't/tmp_dir/outer.pl';

    like eval { $plate->serve('outer') } // $@,
    qr"^Couldn't load \./t/tmp_dir/outer\.pl: ", 'Error reading cache file (static mode)';

    is delete $$plate{mod}{outer}, undef, "Don't keep stat of unreadable cache file (static mode)";

    $plate->set(static => undef);
    like eval { $plate->serve('outer') } // $@,
    qr"^Couldn't load \./t/tmp_dir/outer\.pl: ", 'Error reading cache file';

    is delete $$plate{mod}{outer}, undef, "Don't keep stat of unreadable cache file";
}

unlink 't/tmp_dir/outer.pl';
rmdir 't/tmp_dir' or diag "Can't remove t/tmp_dir: $!";
like eval { $plate->serve('outer') } // $@,
qr"^Can't write .*outer\.pl: ", 'Error writing cache file';

$plate->set(path => '', cache_path => '.');
like eval { $plate->serve('test') } // $@,
qr"^Can't read test\.plate: ", 'Error on non-existent template';

$plate->set(path => undef, cache_path => undef);
like eval { $plate->serve('test') } // $@,
qr"^Plate template 'test' does not exist ", 'Error on undefined path & cache_path';

$plate->set(path => undef, cache_path => 't/tmp_dir', umask => 0777);
SKIP: {
    skip "Can't chmod 0 to test unreability", 1 if -r 't/tmp_dir';

    like eval { $plate->set(path => 't/tmp_dir') } // $@,
    qr"^Can't set path to t/tmp_dir/: Not accessable", 'Error on inaccessable path';
}
rmdir 't/tmp_dir' or diag "Can't remove t/tmp_dir: $!";

$plate = Plate->new(path => 't/data');
$plate->define(line_test => "<& utf8 &>\nLine 2\n<& faulty &>\nLine 4\n");
like eval { $plate->serve('line_test') } // $@,
$] < 5.025_001
? qr'^Bareword "This" not allowed while "strict subs" in use at t.data.faulty\.plate line 2\.
Bareword "is" not allowed while "strict subs" in use at t.data.faulty\.plate line 2\.
Bareword "broken" not allowed while "strict subs" in use at t.data.faulty\.plate line 4\.
Plate compilation failed at line_test line 3\.
' : qr'^Bareword "This" not allowed while "strict subs" in use at t.data.faulty\.plate line 2\.
Plate compilation failed at line_test line 3\.
', 'Correct line number';

ok !$warned, 'No warnings';

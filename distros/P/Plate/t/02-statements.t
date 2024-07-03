#!perl -T
use 5.020;
use warnings;
use Test::More tests => 22;

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

my $plate = Plate->new;

is $plate->serve(\<<''),
% if (@_) {
args=<% scalar @_ %>
% } else {
no args
% }

'no args',
'Statement lines';

is $plate->serve(\<<'', 1..3),
%# This is a comment on line 1
% if (@_) {
args=<% scalar @_ %>
% } else { # This is a comment on line 4
no args
% }
% # This is a comment on line 7

'args=3',
'Comment lines';

is $plate->serve(\"% if (1) {\nYES\n% }"), $plate->serve(\"% if (1) {\nYES\n% }\n"), 'Ignore final newline if last line is a statement';

my $fail = eval { $plate->serve(\<<'') };
% if (1) {

is $fail, undef, 'Compilation failed';
like $@, qr/^Missing right curly or square bracket at .*^Plate compilation failed at /ms,
'Compilation failure message';

$fail = eval { $plate->serve(\<<'') };
%% if (1) {

is $fail, undef, 'Precompilation failed';
like $@, qr/^Missing right curly or square bracket at .*^Plate precompilation failed at /ms,
'Precompilation failure message';

$fail = eval { $plate->serve(\<<'') };
%% my $precomp_var;
% $precomp_var = 1;

is $fail, undef, 'Compilation failed';
like $@, qr'^Global symbol "\$precomp_var" requires explicit package name .*^Plate compilation failed at 'ms,
'Precompilation doesnt affect runtime';

eval { $plate->serve(\<<'') };
%# line 5 "nowhere"
%# line 23
% die 'oops';

is $@, "oops at nowhere line 23.\n", 'Replace line number and file name';

$plate->set(init => q{
    Plate::_local_args(__PACKAGE__, shift) if @_;
}, once => q{
    no strict 'vars';
}, keep_undef => 1);

$plate->define(empty => '');
is $plate->serve(\<<'', { empty => '', '@empty' => [''] }),
%%# Empty
<%% '' %%>\
<% $empty %>\
<% @empty %>\
<&& empty &&>\
%%# Empty

'',
'Empty template';

$plate->set(init => undef, once => undef);
is $plate->serve(\<<''),
<%perl>
my $var = 123;
if ($var) {
</%perl>
Yes
<%perl>
} else {
</%perl>
No
<%perl>
}
$var == 123 or warn '$var has changed';
</%perl>

'Yes',
'Execute %perl blocks';

$fail = eval { $plate->serve(\<<'') };
<%perl>

is $fail, undef, 'Compilation failed';
like $@, qr"^Opening <%perl...> tag without closing </%perl> tag at ",
'Compilation failure for missing closing tag';

$fail = eval { $plate->serve(\<<'') };
<%%perl>
Same Line </%%perl>

is $fail, undef, 'Precompilation failed';
like $@, qr"^Opening <%%perl...> tag without closing </%%perl> tag at ",
'Precompilation failure for missing closing tag';

is $plate->serve(\<<''),
<%%perl>
# This is precompiled
my $var = 123;
if ($var) {
</%%perl>
Yes
<%%perl>
} else {
</%%perl>
No
<%%perl>
}
$var == 123 or warn '$var has changed';
</%%perl>

'Yes',
'Execute %%perl blocks';

$fail = eval { $plate->serve(\<<'') };
</%%perl>

is $fail, undef, 'Precompilation failed';
like $@, qr"^Closing </%%perl> tag without opening <%%perl...> tag at ",
'Precompilation failure for missing opening tag';

is $plate->serve(\<<''), 4, 'Precompiled multi-line %% statements';
%% my $zero
%% = 0
%% ;
<% __LINE__ |%>

is $plate->serve(\<<''), '2247', 'Precompiled %% for loops';
%% for (1,2) {
<% __LINE__ |%>\
%%   if ($_ == 2) {
<% __LINE__ |%>\
%%   }
%% }
<% __LINE__ |%>

ok !$warned, 'No warnings';

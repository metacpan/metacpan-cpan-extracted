#!perl -T
use 5.020;
use warnings;
use Test::More tests => 9;

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
sub warnings_are(&$;$) {
    my($sub, $exp, $out) = @_;
    my @got;
    local $SIG{__WARN__} = sub {
        push @got, join '', @_;
    };
    my $ok = defined eval { $sub->() };
    $ok &&= @got == @$exp;
    $ok &&= $got[$_] =~ $$exp[$_] for 0..$#got;
    ok $ok, $out
        or do {
        if ($@) {
            diag $@;
        } else {
            diag "found warning: $_" for @got;
            diag "found no warnings" unless @got;
            diag "expected warning: $_" for @$exp;
            diag "expected no warnings" unless @$exp;
        }
    };
}
sub warning_lines_are(&$;$) {
    $_ = qr/^L$_ at .*? line $_\.$/ for @{$_[1]};
    &warnings_are;
}

my $plate = Plate->new(cache_code => undef);

warning_lines_are { $plate->serve(\<<'') } [4], 'Precompiled multi-line statements';
%% my $zero
%% = 0
%% ;
% warn "L4";

warning_lines_are { $plate->serve(\<<'') } [2,2,5], 'Precompiled for loop';
%% for (1,2) {
% warn "L2";
.
%%   if ($_ == 2) {
% warn "L5";
%%   }
%% }

warning_lines_are { $plate->serve(\<<'') } [5,7], 'Multi-line expressions';
<%
'Hi'
|html
%>
% warn "L5";
<% "\n\nthere.\n\nWazzup?\n\n" |%>
% warn "L7";

warning_lines_are { $plate->serve(\<<'') } [5,7], 'Precompiled multi-line expressions';
<%%
'Hi'
|html
%%>
% warn "L5";
<%% "\n\nthere.\n\nWazzup?\n\n" |%%>
% warn "L7";

$plate->define(empty => '');
warning_lines_are { $plate->serve(\<<'') } [1,5], 'Precompiled multi-line include template';
% warn "L1";
<&&
empty
&&>
% warn "L5";

warning_lines_are { $plate->serve(\<<'') } [1,5], 'Precompiled multi-line include content';
% warn "L1";
<&&
_
&&>
% warn "L5";

warning_lines_are { $plate->serve(\<<'') } [1,5], 'Precompiled multi-line include content with content';
% warn "L1";
<&&|
_
&&></&&>
% warn "L5";

warning_lines_are { $plate->serve(\<<'') } [1,5], 'Multi-line include precompiled expression';
% warn "L1";
<& <%%
'empty'
%%> &>
% warn "L5";

warning_lines_are { $plate->serve(\<<'') } [1,5,8], 'Within multi-line expression';
% warn "L1";
<%
# %>
<%
warn "L5";
''
%>
% warn "L8";


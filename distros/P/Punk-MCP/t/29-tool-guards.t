#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPApp;

my $pkg = 'T29::A';
my $t = mcp_app(qq{
    package ${pkg}::Controller::T;
    sub a { 'ran' }
    sub staff_only { my (\$c) = \@_;
        return (\$c->stash->{role} // '') eq 'staff' ? undef : [403, [], ['staff only']] }
    package $pkg;
    our \$NO   = sub { [403, ['Content-Type' => 'text/plain'], ['not for you']] };
    our \$DIES = sub { die "guard broke\\n" };
    our \$YES  = sub { return };
    our \$ARGS = sub { my (\$c) = \@_; (\$c->param('ok') // '') eq 'yes' ? undef : [400, [], ['say yes']] };
    plugin 'MCP' => { session => 0, page_size => 2 };
    mcp tool => a_open   => 'T#a';
    mcp tool => b_hidden => { guard => \$NO }   => 'T#a';
    mcp tool => c_open   => 'T#a';
    mcp tool => d_yes    => { guard => [\$YES, \$YES] } => 'T#a';
    mcp tool => e_dies   => { guard => \$DIES } => 'T#a';
    mcp tool => f_staff  => { guard => 'T#staff_only' } => 'T#a';
    mcp tool => g_args   => { guard => \$ARGS } => 'T#a';
    mcp tool => h_none   => { guard => 'none' } => 'T#a';
}, pkg => $pkg, pre => q{ $c->stash->{role} = $c->req->header('X-Role'); });

sub all_tools {
    my (@names, $cursor);
    for (1 .. 10) {
        my (undef, $r) = list_tools($t, $cursor);
        push @names, map { $_->{name} } @{ $r->{result}{tools} };
        $cursor = $r->{result}{nextCursor} or last;
    }
    return \@names;
}

is_deeply(all_tools(), [qw(a_open c_open d_yes h_none)],
    'tools whose guard refuses or dies are left out of the list, across pages');

my (undef, $r) = list_tools($t);
is_deeply([map { $_->{name} } @{ $r->{result}{tools} }], [qw(a_open c_open)],
    'a page is filled past a hidden tool');
my (undef, $r2) = list_tools($t, $r->{result}{nextCursor});
is($r2->{result}{tools}[0]{name}, 'd_yes', 'and the cursor carries on after it');

(undef, $r) = call_tool($t, 'b_hidden');
ok($r->{result}{isError}, 'calling a refused tool is a tool error');
is($r->{result}{content}[0]{text}, 'refused (403): not for you',
    "with the guard's status and words");

(undef, $r) = call_tool($t, 'e_dies');
is($r->{result}{content}[0]{text}, 'guard broke', 'a guard that dies refuses, with its message');

(undef, $r) = call_tool($t, 'd_yes');
is($r->{result}{content}[0]{text}, 'ran', 'every guard in a list passing runs the tool');
(undef, $r) = call_tool($t, 'h_none');
is($r->{result}{content}[0]{text}, 'ran', "guard => 'none' runs it");

(undef, $r) = call_tool($t, 'f_staff');
is($r->{result}{content}[0]{text}, 'refused (403): staff only',
    "a 'Controller#method' guard is resolved and run");
$t->request_header('X-Role' => 'staff');
is_deeply(all_tools(), [qw(a_open c_open d_yes f_staff h_none)],
    'it sees the request: a staff caller lists the staff tool');
(undef, $r) = call_tool($t, 'f_staff');
is($r->{result}{content}[0]{text}, 'ran', 'and can call it');

(undef, $r) = call_tool($t, 'g_args', { ok => 'no' });
is($r->{result}{content}[0]{text}, 'refused (400): say yes',
    "a call's guard sees the arguments");
(undef, $r) = call_tool($t, 'g_args', { ok => 'yes' });
is($r->{result}{content}[0]{text}, 'ran', 'and passes on them');

done_testing;

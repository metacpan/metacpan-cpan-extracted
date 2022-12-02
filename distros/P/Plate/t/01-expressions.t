#!perl -T
use 5.020;
use warnings;
use Test::More tests => 30;

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

my $plate = new Plate;

is $plate->serve(\'<% "<html> this & that" |%>'),
'<html> this & that',
'Unfiltered expression';

is $plate->serve(\'<% "<html> this & that" %>'),
'&lt;html&gt; this &amp; that',
'Automatically filtered expression';

is $plate->serve(\'<% "<html> this & that" |html %>'),
'&lt;html&gt; this &amp; that',
'Explicitly filtered expression';

is $plate->serve(\'<% "<html> this & that" | html | html %>'),
'&amp;lt;html&amp;gt; this &amp;amp; that',
'Double filtered expression';

is $plate->serve(\<<''),
<%filter bold>
<b><& _ &></b>
</%filter>
<% "<html> this & that" |bold %>\

'<b><html> this & that</b>',
'Custom filtered expression';

is $plate->serve(\<<''),
<%filter html>
<% $_[0] =~ y/<>/[]/r |%>
</%filter>
<% "<html> this & that" %>\

'[html] this & that',
'Custom replaced filter';

$plate->set(keep_undef => 1, chomp => undef);
is $plate->serve(\'<% undef |%>'),
undef,
'Undefined expression is kept';

$plate->set(keep_undef => undef, chomp => 1);
is $plate->serve(\'<% undef |html %>'),
'',
'Undefined expression is coerced to ""';

is $plate->serve(\<<''),
<%
  my $i = 7;
  $i * 3 % 4;
| %>

'1',
'Complex expression';

is $plate->serve(\"<% \@_ ? <%% 1 |%%> : <%% 2 |%%> |%>\\\n"),
'2',
'Precompiled expressions';

is $plate->serve(\'<%join ",",@_|%><%% "" %%>', 1..9),
'1,2,3,4,5,6,7,8,9',
'Passed arguments';

is $plate->serve(\"<one>\\\n<two>\n<three>\\\n"),
"<one><two>\n<three>",
'Remove escaped newlines';

is $plate->serve(\"<%\n%>hi5"),
'hi5',
'Empty expression';

is $plate->serve(\'<% "hi" %><% # comment %>5'),
'hi5',
'Comment expression';

is $plate->serve(\"hi<%#\nFirst line.\nSecond line.\n%>5"),
'hi5',
'Multi-line comment expression';

$plate->set(vars => {
        '$var' => \'String',
        '@var' => ['Array'],
        '%var' => {a => 'Hash'},
        obj    => \$plate,
        CONST  => 1,
        OBJECT => $plate,
    });
ok $plate->can_serve(\'<% $var %> <% "@var" %> <% $var{a} %> <% ref $obj %> <% CONST %> <% OBJECT %>'),
'Set & use vars (can_serve)';

is $plate->serve(\'<% $var %> <% "@var" %> <% $var{a} %> <% ref $obj %> <% CONST %> <% OBJECT eq $obj %>'),
'String Array Hash Plate 1 1',
'Set & use vars (serve)';

$plate->set(package => 'Some::Where');
is $plate->serve(\'<% $var %> <% $var[0] %> <% $Some::Where::var{a} %> <% Plate::Template::CONST %>'),
'String Array Hash 1',
'Set a new package name & use the same vars';

$plate->set(vars => { trim => sub { $_[0] =~ s/^\s+|\s+$//gr } });
is $plate->serve(\'<% trim "  Hello World\n" %>'),
'Hello World',
'Set & call a local function';

$plate->set(vars => { '$var' => undef });
is $plate->serve(\'<% $var %>'),
'',
'Remove a var';

$plate->set(vars => undef);
is $plate->serve(\'<% @var %>'),
'0',
'Remove all vars';

$plate->set(filters => { upper => sub { uc $_[0] } });
is $plate->serve(\'<% "Hello World" |upper %>'),
'HELLO WORLD',
'Add a filter by subroutine reference';

sub lower { lc $_[0] };
$plate->set(filters => { lower => 'lower' });
is $plate->serve(\'<% "Hello World" |lower %>'),
'hello world',
'Add a filter by subroutine name';

$plate->set(filters => { lower => sub { lcfirst $_[0] } });
is $plate->serve(\'<% "Hello World" |lower %>'),
'hello World',
'Replace a filter';

$plate->set(auto_filter => 'upper');
is $plate->serve(\'<% "Hello World" %>'),
'HELLO WORLD',
'Set a default filter';

$plate->set(auto_filter => undef);
is $plate->serve(\'<% "Hello World" %>'),
'Hello World',
'Remove auto_filter';

is $plate->serve(\<<''), "Hi5\n\n\nExtra\n\nLines\n\n\n7up", 'Multi-line expressions';
<%
'Hi'
|html
%>\
<% __LINE__ |%>
<% "\n\nExtra\n\nLines\n\n" |%>
<% __LINE__ |%>up\

is $plate->serve(\<<''), "Hi5\n\n\nExtra\n\nLines\n\n\n7up", 'Precompiled multi-line expressions';
<%%
'Hi'
|html
%%>\
<% __LINE__ |%>
<%% "\n\nExtra\n\nLines\n\n" |%%>
<% __LINE__ |%>up

$plate->set(filters => undef);
like eval { $plate->serve(\'<% 1 |html %>') } // $@,
qr"^No 'html' filter defined ", 'Remove all filters';

ok !$warned, 'No warnings';

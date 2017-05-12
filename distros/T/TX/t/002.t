use strict;
use warnings;
use Test::More qw/tests 3/;
#use Test::More qw/no_plan/;
use TX qw/include/;
use Config;

@ENV{qw/TEMPLATE_PATH TEMPLATE_DELIMITERS/}
  =('t/doesnt_exist'.$Config{path_sep}.'t/tmpl', '<% %>');

my $v='keep';

is include( 't1', {OUTPUT=>''}, v=>$v ), <<"EOF", 'default object';
=========
  ${v}
=========
  [t1]${v}[/t1]
=========
  [m1]${v}[/m1]
=========
  [m2]${v}[/m2]
=========
EOF

my $string=include
  ( {filename=>'huhu',
     template=>">>>\n<% OUT include 'lib#m3', {VMODE=>'KEEP'} %> <% \$V{x} %><<<\n"},
    {OUTPUT=>''}, v=>$v );
cmp_ok length($string), '==', 32, 'length should be 30 but is 32 (expected)';

undef $TX::TX;
$ENV{TEMPLATE_BINMODE}='utf8';

$string=include
  ( {filename=>'huhu',
     template=>">>>\n<% OUT include 'lib#m3', {VMODE=>'KEEP'} %> <% \$V{x} %><<<\n"},
    {OUTPUT=>''}, v=>$v );
cmp_ok length($string), '==', 30, 'length is now 30 (due to utf8 input mode)';


# Local Variables:
# mode: cperl
# End:

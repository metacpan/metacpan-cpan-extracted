use Test::More tests => 12;

use Regexp::Subst::Parallel;

#1
is(subst('a', 'a' => 'b'), 'b', "Basic");
#2
is(subst('arnold', qr/(arnold)/ => '$1 rimmer'), 'arnold rimmer', "Capture");
#3
is(subst('arnrim', qr/(arn)(rim)/ => '${1}old ${2}mer'), 'arnold rimmer', 
   "More sohistocated capture");
#4
is(subst('arnold', 'arn' => 'rim',
         'old' => 'mer'), 'rimmer', "Simple multiple");
#5
is(subst('merrim', 'mer' => 'rim',
         'rim' => 'mer'), 'rimmer', "Simple parallel");
#6
is(subst('<arnold> _rimmer_', qr/_(\w+)_/ => '<b>$1</b>',
         qr/<(\w+)>/ => '<i>$1</i>'), '<i>arnold</i> <b>rimmer</b>', 
   "Parallel capture");
#7
is(subst('foo', qr/(foo)/ => '\\$1'), '$1', "Backslashes 101");
#8
is(subst('foo', qr/(foo)/ => '\\\\$1'), '\\foo', "Backslashes 102");
#9
is(subst('foo', qr/(foo)/ => '\\\\\\$1'), '\\$1', "Backslashes 103");
#10
is(subst('foo', qr/(fo)/  => '\\${1}0'), '${1}0o', "Backslashes 104");
#11
is(subst('foo', qr/(fo)/  => '\\\\${1}0'), '\\fo0o', "Backslashes 105");
#12
is(subst('flam', qr/(?<!a)m/ => 'x', qr/m/ => 'g'), "flag", "Lookbehind");

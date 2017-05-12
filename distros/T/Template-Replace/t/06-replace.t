#!perl -T

use strict;
use warnings;
use Test::More 'no_plan';

use Template::Replace;
use FindBin;

use Data::Dumper;

#
# Prepare data directory ...
#
my $data_dir = "$FindBin::Bin/data";                       # construct path
$data_dir = $1 if $data_dir =~ m#^((?:/(?!\.\./)[^/]+)+)#; # un-taint
mkdir $data_dir unless -e $data_dir;                       # create if missing

#
# Cleanup beforehand ... no need for it so far!
#


#
# Let's have some prerequisites ...
#
my $tmpl;
my $str;
my $result;


#
# Testing tmpl->_replace() ...
#
$tmpl = Template::Replace->new(); # standard delimiters

$str = <<EOS
First line of template, with (\$ Variable1 \$) as variable.
<!--( Section1 )-->
This is Section1 with (\$Variable2|xml\$) as variable.
<!--( /Section1 )-->
<!--( Section2 )-->
This is Section2 with (\$Variable2\$) as variable.
<!--( /Section2 )-->
This is the last line of the template.
EOS
;

my $template_ref = $tmpl->parse($str);
ok( ref $template_ref eq 'HASH', 'parse() returns template hash reference' );

#diag( Dumper($template_ref) );

$result = $tmpl->replace({
	'Variable1' => '"Variable1"',
    'Section1'  => {
        'Variable2' => '"Variable2"',
    },
    'Section2'  => [
        { 'Variable2' => 'Variable2.0' },
        { 'Variable2' => 'Variable2.1' },
        { 'Variable2' => 'Variable2.2' },
    ],
});

#diag( Dumper($result) );

ok( $result eq <<EOS
First line of template, with "Variable1" as variable.
This is Section1 with &quot;Variable2&quot; as variable.
This is Section2 with Variable2.0 as variable.
This is Section2 with Variable2.1 as variable.
This is Section2 with Variable2.2 as variable.
This is the last line of the template.
EOS
, 'replace() with simple result');


#
# Cleanup ... no need for it so far!
#


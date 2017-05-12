#!perl -T

#
# TODO: Test comments!
#

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


#
# Testing tmpl->_parse_slices() ...
#
$tmpl = Template::Replace->new(); # standard delimiters

$str = <<EOS
<!--( Sec1 )-->
Bla (\$var1\$) bla.
<!--( /Sec1 )-->

Blub.<!--( Sec2 )-->
(\$var1\$)Hmm? (\$var1\$)<!--(/Sec2)-->
Oops <!--(Sec3)--><!--(Sec4)-->inline<!--(/Sec4)--><!--(/Sec3)-->.
<!--#
    1
    <!--(Sec4)-->
    2
    <!--(/Sec4)-->
#-->
More.
<!--( Sec1 )-->
Bla (\$ var1 | xml \$) blub.
<!--( /Sec1 )-->
End.
EOS
;

my $sliced_str = [
'<!--( Sec1 )-->
',
'Bla ',
'($var1$)',
' bla.
',
'<!--( /Sec1 )-->
',
'
Blub.',
'<!--( Sec2 )-->
',
'($var1$)',
'Hmm? ',
'($var1$)',
'<!--(/Sec2)-->
',
'Oops ',
'<!--(Sec3)-->',
'<!--(Sec4)-->',
'inline',
'<!--(/Sec4)-->',
'<!--(/Sec3)-->',
'.
',
'<!--#
    1
    <!--(Sec4)-->
    2
    <!--(/Sec4)-->
#-->
',
'More.
',
'<!--( Sec1 )-->
',
'Bla ',
'($ var1 | xml $)',
' blub.
',
'<!--( /Sec1 )-->
',
'End.
'
];

is_deeply( $tmpl->_slice_str($str), $sliced_str, 'Confirming $sliced_str.' );

my $root_parts = [
    { sec => 'Sec1', idx => 0 },
    "\nBlub.",
    { sec => 'Sec2', idx => 0 },
    'Oops ',
    { sec => 'Sec3', idx => 0 },
    ".\n",
    "More.\n",
    { sec => 'Sec1', idx => 1 },
    "End.\n",
];

my $sec1_0_parts = [
    'Bla ',
    { var => 'var1', filter => 'default' },
    " bla.\n",
];

my $sec1_1_parts = [
    'Bla ',
    { var => 'var1', filter => 'xml' },
    " blub.\n",
];

my $sec4_0_parts = [
    'inline',
];

my $parsed_slices = $tmpl->_parse_slices($tmpl->_slice_str($str));
#diag( Dumper($parsed_slices) );

is_deeply (
    $parsed_slices->{parts},
    $root_parts,
    'root parts'
);
is_deeply (
    $parsed_slices->{children}{'Sec1'}[0]{parts},
    $sec1_0_parts,
    'Sec1-0 parts'
);
is_deeply (
    $parsed_slices->{children}{'Sec1'}[1]{parts},
    $sec1_1_parts,
    'Sec1-1 parts'
);
ok( $parsed_slices->{children}{Sec2}[0]{children}{var1} == 2, 'Sec2 var1' );
is_deeply (
    $parsed_slices->{children}{Sec3}[0]{children}{Sec4}[0]{parts},
    $sec4_0_parts,
    'Sec4-0 parts'
);

eval {
    $tmpl->_parse_slices(
        $tmpl->_slice_str('($Bla$)<!--( Bla )--><!--(/Bla)-->')
    );
};
like( 
    $@,
    qr/'Bla' already used for a variable in 'root'/,
    'Section name already used for a variable'
);

eval {
    $tmpl->_parse_slices(
        $tmpl->_slice_str('<!--(Bla)--><!--(/Bla)-->($Bla$)')
    );
};
like(
    $@,
    qr/'Bla' already used for a section in 'root'/,
    'Variable name already used for a section'
);


#
# Cleanup ... no need for it so far!
#


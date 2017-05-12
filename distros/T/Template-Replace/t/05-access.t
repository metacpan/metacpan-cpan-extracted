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

my $test2 = <<EOS
# String template via ->parse()!
This should be '(\$Var\$)', same as '(\$/Var\$)',

On the other hand, this is '(\$Sec1/Var\$)',
which should be the same as '(\$/Sec1/Var\$)'.

Now, how about '(\$Sec2/Var\$)' (should be '(\$Sec2/0/Var\$)')?
Or '(\$Sec2/2/Var\$)'?
But this should be empty: '(\$Sec2/4/Var\$)'!

<!--( Sec1 )-->
This is Sec1, with its '(\$Var\$)'.
But this should be '(\$/Var\$)'.
And we can use '(\$/Sec2/Var\$)' too from Sec1,
or even '(\$/Sec2/2/Var\$)'!
<!--( /Sec1 )-->

Now, we are doing some iterations:
<!--( Sec2 )-->
This is '(\$Var\$)' (again: '(\$Var\$)') and '(\$../Var\$)'.
<!--( /Sec2 )-->

And what about nested sections? Let's try:

<!--( Sec3 )-->
Section 3 with '(\$Var\$)', and some iterations:
<!--( Sec4 )-->
'(\$Var\$)', '(\$../Var\$)' and '(\$../../Var\$)'.
<!--( /Sec4 )-->
<!--( /Sec3 )-->

This should use the XML filter: '(\$Test-XML|xml\$)'.
This should use the URI filter: '(\$ Test-URI | uri \$)'.
This should use the default filter: '(\$Test-URI|blablub\$)'.
This should also use the default filter: '(\$Test-URI|\$)'.
This is the test filter: '(\$VAR | test\$)'.
EOS
;

$tmpl->parse($test2);

#diag( Dumper($tmpl->{template}) );

=begin
diag 'Has Sec1:          ', $tmpl->has('Sec1');
diag 'Has /Sec2:         ', $tmpl->has('/Sec2');
diag 'Has Sec2/Var:      ', $tmpl->has('Sec2/Var');
diag 'Has Var:           ', $tmpl->has('Var');
diag 'Has /Var:          ', $tmpl->has('/Var');
diag 'Has Bla:           ', $tmpl->has('Bla');
diag 'Has /Sec2/Var/Bla: ', $tmpl->has('/Sec2/Var/Bla');
diag 'Has /Sec3/Sec4:    ', $tmpl->has('/Sec3/Sec4');
diag 'Has Sec1/0:        ', $tmpl->has('Sec1/0');
diag 'Has Sec1/1:        ', $tmpl->has('Sec1/1');
=cut

ok( ref $tmpl->has('Sec1') eq 'ARRAY', "->has('Sec1') is array ref" );
ok( ref $tmpl->has('/Sec2') eq 'ARRAY', "->has('/Sec2') is array ref" );
ok( $tmpl->has('Sec2/Var') == 2, "->has('Sec2/Var' is 2");
ok( $tmpl->has('Var') == 1, "->has('Var') is 1"); # TODO: should be 2 ...
ok( $tmpl->has('/Var') == 1, "->has('/Var') is 1"); # TODO: should be 2 ...
ok( !$tmpl->has('Bla'), "->has('Bla') has no result");
ok( !$tmpl->has('/Sec2/Var/Bla'), "->has('/Sec2/Var/Bla') has no result");
ok( ref $tmpl->has('Sec3/Sec4') eq 'ARRAY', "->has('Sec3/Sec4') is array ref");
ok( ref $tmpl->has('Sec1/0') eq 'HASH', "->has('Sec1/0') is hash ref");
ok( !$tmpl->has('Sec1/1'), "->has('Sec1/1') has no result");


#
# Cleanup ... no need for it so far!
#


#!perl

use strict ;
use lib qw(t) ;
use common ;

use File::Slurp ;
use Data::Dumper ;

my $tests = [

	{
		name	=> 'nested [- -]',
		skip	=> 0,
		opts	=> {
			pre_delim  => qr/\[\-/,
			post_delim => qr/\-\]/,
		},
		data	=> {
			widgets => [
				{
					title => "bart",
				},
		                {
					title => "marge",
				}
			],
		},
		template => <<TEMPLATE,
<table width="100%" border=1>
     [-start widgets-]
     <tr>
     <td>[-anchor-]</td>
     <td>
         <b>[-title-]</b>
         <br>[-description-]
     </td>
     <td>[-escaped_anchor-]</td>
     <td>[-options-]</td>
     </tr>
         [-end widgets-]
</table>
TEMPLATE

		expected => <<EXPECTED,
<table width="100%" border=1>
     
     <tr>
     <td></td>
     <td>
         <b>bart</b>
         <br>
     </td>
     <td></td>
     <td></td>
     </tr>
         
     <tr>
     <td></td>
     <td>
         <b>marge</b>
         <br>
     </td>
     <td></td>
     <td></td>
     </tr>
         
</table>
EXPECTED
	},
	{
		name	=> 'nested',
		skip	=> 0,
		data	=> {
			widgets => [
				{
					title => "bart",
				},
		                {
					title => "marge",
				}
			],
		},
		template => <<TEMPLATE,
<table width="100%" border=1>
     [%start widgets%]
     <tr>
     <td>[%anchor%]</td>
     <td>
         <b>[%title%]</b>
         <br>[%description%]
     </td>
     <td>[%escaped_anchor%]</td>
     <td>[%options%]</td>
     </tr>
         [%end widgets%]
</table>
TEMPLATE

		expected => <<EXPECTED,
<table width="100%" border=1>
     
     <tr>
     <td></td>
     <td>
         <b>bart</b>
         <br>
     </td>
     <td></td>
     <td></td>
     </tr>
         
     <tr>
     <td></td>
     <td>
         <b>marge</b>
         <br>
     </td>
     <td></td>
     <td></td>
     </tr>
         
</table>
EXPECTED
	},
	{
		name	=> 'nested ,',
		skip	=> 0,
		opts	=> {
		},
		data	=> {
			widgets => [
				{
					title => "bart",
				},
		                {
					title => "marge",
				}
			],
		},
		template => <<TEMPLATE,
,,,,,[%start widgets%]
,,,,,,,,,{[%title%]}
[% s %]
,,,,,,,,,[%end widgets%]
TEMPLATE

		expected => <<EXPECTED,
,,,,,
,,,,,,,,,{bart}

,,,,,,,,,
,,,,,,,,,{marge}

,,,,,,,,,
EXPECTED
	},
	{
		name	=> 'nested short',
		skip	=> 0,
		data	=> {
			widgets => [
				{
					title => "bart",
				},
		                {
					title => "marge",
				}
			],
		},
		template => <<TEMPLATE,
     [%start widgets%]
         <b>[%title%]</b>
         [%end widgets%]
TEMPLATE

		expected => <<EXPECTED,
     
         <b>bart</b>
         
         <b>marge</b>
         
EXPECTED
	},

] ;

template_tester( $tests ) ;

exit ;



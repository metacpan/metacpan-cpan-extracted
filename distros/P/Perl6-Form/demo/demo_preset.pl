use Perl6::Form { fill=>'*'};

print form
	'|{|||||||||||||||||||||||||}|',
    "Hi there!";

use Perl6::Form { fill=>'-'};

print form
	'{[{*}[}',
    "more\nof\nthe\nsame";

print form {fill=>''},
	'{[{*}[}',
    "overridden";

package Other;

print Perl6::Form::form
	'|{|||||||||||||||||||||||||}|',
     "Hi there!";

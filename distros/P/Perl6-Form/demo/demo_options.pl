use Perl6::Form {fill=>'*'};

$text = "Oh, my god, it's full of stars!";

print form "{]]]]]]]]][[[[[[[[[}",
             $text;

use Perl6::Form;

print form "{]]]]]]]]]]]][[[[[[[[[}",
     "But not here";


use Perl6::Form { fill=>'*' };

print form "{]]]]]]]]]]]][[[[[[[[[}",
     "And then here again";


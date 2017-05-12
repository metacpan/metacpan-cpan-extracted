use strict;
use warnings;

use Test::More tests => 5;

use Template::Caribou;

my $t = __PACKAGE__->new;

    is $t->render(sub{
        print "<hey>";
    }) => '&lt;hey>';
    
    is $t->render(sub{
        print ::RAW "<hey>";
    }) => '<hey>';

    # prints 'onetwo'
    is $t->render(sub{
        print "one";
        print "two";
    }) => 'onetwo';
    
    is $t->render(sub{
        print "one";
        return "ignored";
    }) => 'one';
    
    is $t->render(sub{
        return "foo";
    }) => 'foo';



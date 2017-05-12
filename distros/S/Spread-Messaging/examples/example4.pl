#
# File: example4.pl
# Date: 08-Feb-2007
# By  : Kevin Esteb
#
# This is a sending program. Capture an input line a send down the pike.
#

use Term::ReadLine;
use Spread::Messaging::Content;
use Spread::Messaging::Exception;

use strict;
use constant true  => -1;
use constant false =>  0;


main: {

    my $spread;
    my $term;
    my $done = false;
    my $buffer;

    eval {

        $spread = Spread::Messaging::Content->new();
        $term = Term::ReadLine->new("testing");

        $spread->join_group("test1");
        $spread->group("test1");

        while ($done == false) {

            $buffer = $term->readline("Prompt> ");
            $done = true if $buffer =~ /quit/i;

            $term->addhistory($buffer);
            $spread->message($buffer);
            $spread->send();

        }

    }; if (my $ex = $@) {

        my $ref = ref($ex);

        if ($ref && $ex->isa('Spread::Messaging::Exception')) {

            printf("Error: %s cased by: %s\n", $ex->errno, $ex->errstr);

        } else { warn $@; }

    }

}


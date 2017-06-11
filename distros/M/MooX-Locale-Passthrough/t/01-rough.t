#!perl

use 5.008001;

use strict;
use warnings FATAL => 'all';

use Test::More;

{
    package    #
      TestMXLP;

    use Moo;
    with "MooX::Locale::Passthrough";

    sub pure { shift->__("Hello world") }

    sub mayby_plural
    {
        my $self = shift;
        [$self->__n("Hello world", "Hello universe", 1), $self->__n("Hello world", "Hello universe", 2),];
    }

    sub ctx { shift->__p("Alabama", "Sweet home") }
}

my $tmxlp = TestMXLP->new();

is $tmxlp->pure, "Hello world", "Pure passed through";
is_deeply $tmxlp->mayby_plural, ["Hello world", "Hello universe"], "Singular and Plural passed through";
is $tmxlp->ctx, "Sweet home", "Ctx msg passed through";

done_testing();

#!/usr/bin/perl6
use v6;

my @names = qw(foo bar baz);

sub commify_series {
#    @_.perl.say;
    (@_ == 0) ?? ''                 !!
    (@_ == 1) ?? @_[0]              !!
    (@_ == 2) ?? join(" and ", @_)  !!
                 join(", ", @_[0 .. (@_-2)], "and " ~ @_[*-1]);
}

# TODO due to a parsing bug in Rakudo this ; is required here
;

say commify_series(|@names);
@names.pop;
say commify_series(|@names);
@names.pop;
say commify_series(|@names);

# TODO: this should also work, but then we have to enable the @_.perl.say in the sub
# say commify_series(@names);

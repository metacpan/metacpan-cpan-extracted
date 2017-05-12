use strict;
use warnings;

use Test::More;

no Params::Lazy 'caller_args';
use Params::Lazy lazy_test      => '^$;$',
                 lazy_return    => '^',
                 lazy_ampforce  => '^',
                 lazy_gotoforce => '^';

sub lazy_test {
    is(force($_[0]), $_[1], $_[2]);
}
sub lazy_return { return shift }
sub lazy_ampforce { &force }
sub lazy_gotoforce { goto &force }

sub {
    lazy_test
        $_[1],
        $_[0],
        "lazy_run \$_[1], 'foo'; returns foo"
}->('I am in $_[0]');

if ( $] >= 5.014 ) {
    lazy_test ${^GLOBAL_PHASE},
              ${^GLOBAL_PHASE},
              'lazy_return(${^GLOBAL_PHASE}) works';
}

BEGIN {
    if ( $] >= 5.014 ) {
        lazy_test ${^GLOBAL_PHASE},
              ${^GLOBAL_PHASE},
              'BEGIN{lazy_test(${^GLOBAL_PHASE})}';
    
        my $when = lazy_return ${^GLOBAL_PHASE};
        is(
            force $when,
            ${^GLOBAL_PHASE},
           'BEGIN{lazy_return(${^GLOBAL_PHASE})}'
        );
    }
}

if ( $] >= 5.016 ) {
    no  if $] <  5.016, strict  => 'subs';
    use if $] >= 5.016, feature => 'current_sub';
    sub {
        lazy_test __SUB__,
            __SUB__,
            'sub{lazy_test(__SUB__)}';
    }->();
}

# Crashes on 5.8.9-5.12.5
if ( $] >= 5.014 ) {
    "a" =~ /(.)/;
    my $lazy = lazy_return "foo" =~ /(foo)(?{is($^N, "foo", "the regex matched")})/;
    force($lazy);
    is($1, "foo", "...and \$1 got updated");
}

my $t = "&force works";
is(lazy_ampforce($t), $t, $t);
is(join(" ", lazy_ampforce(split " ", $t)), $t, $t);
$t = "goto &force works";
is(lazy_gotoforce($t), $t, $t);
is(join(" ", lazy_gotoforce(split " ", $t)), $t, $t);

done_testing;

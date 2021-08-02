use strict;
use warnings;
use lib 't/Pod-Coverage/lib';
use Test::More;

use Pod::Coverage::TrustMe ();

is( capture(q{ Pod::Coverage::TrustMe->new(package => 'Simple2')->print_report }), "Simple2 has a Pod coverage rating of 0.75\nThe following are uncovered:\n  naked\n", "Simple2 works with print_report");

is( capture(q{ Pod::Coverage::TrustMe->new(package => 'Simple7')->print_report }), "Simple7 has a Pod coverage rating of 0\nThe following are uncovered:\n  bar\n  foo\n", 'Simple7 works with print_report');

sub capture {
    my $code = shift;
    open(FH, ">test.out") or die "Couldn't open test.out for writing: $!";
    open(OLDOUT, ">&STDOUT");
    select(select(OLDOUT));
    open(STDOUT, ">&FH");

    eval $code;

    close STDOUT;
    close FH;
    open(STDOUT, ">&OLDOUT");
    open(FH, "<test.out") or die "Couldn't open test.out for reading: $!";
    my $result;
    { local $/; $result = <FH>; }
    close FH;
    unlink('test.out');
    return $result;
}

done_testing;

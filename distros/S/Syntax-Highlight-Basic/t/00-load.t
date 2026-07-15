#!perl

use 5.016;
use strict;
use warnings;

use Test::More tests => 7;

#===========================================================================
# Smoke Tests — module loads, basic API
#===========================================================================

Main:
{
    use_ok('Syntax::Highlight::Basic');
    use_ok('Syntax::Highlight::Basic::Parser');
    use_ok('Syntax::Highlight::Basic::Output::Pygments');
    use_ok('Syntax::Highlight::Basic::Output::HTML');
    use_ok('Syntax::Highlight::Basic::Output::Ansi');

    # Verify ->new returns an object
    my $shb = Syntax::Highlight::Basic->new();
    isa_ok($shb, 'Syntax::Highlight::Basic', 'new() returns a Syntax::Highlight::Basic object');

    # Verify highlight('') returns a defined string
    my $result = $shb->highlight('', undef);
    ok(!ref($result) && defined($result), 'highlight("") returns a defined string');
}

done_testing();
#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PodliteRun qw(run_perl);

sub program { join '', map { "$_\n" } @_ }

sub prints {
    my ( $name, $expected, @lines ) = @_;
    my $run = run_perl( program(@lines) );
    is( $run->{stdout}, $expected, $name ) or diag( $run->{stderr} );
}

# Defects of 1.00

prints( '=boundary ends with its line', "alive\n",
    'use Podlite;', '=head1 One', '', '=boundary', 'print "alive\n";', '=head1 Two' );

prints( '=include ends with its line', "alive\n",
    'use Podlite;', '=VERSION 1', '', '=include VERSION', 'print "alive\n";' );

prints( '=alias ends with its line', "alive\n",
    'use Podlite;', '=alias X word', 'print "alive\n";' );

prints( '=set ends with its line', "alive\n",
    'use Podlite;', '=set :numbered', 'print "alive\n";', '=head1 One' );

{
    my $run = run_perl( program( 'use Podlite;', '=alias ORG Acme', '#line 70 "generated.pl"', '',
        'die "stop";' ) );
    is( $run->{stderr}, "stop at generated.pl line 71.\n", '#line after a directive takes effect' );
}

prints( '=set continuation is stripped', "after\n",
    'use Podlite;', '=set :caption Product', '=    details', '=begin table', 'A | B', '=end table',
    'print "after\n";' );

prints( '=alias continuation is stripped', "after\n",
    'use Podlite;', '=alias X first', '=        second', '=head1 A<X>', '', 'print "after\n";' );

prints( '=alias continuation with a tab is stripped', "after\n",
    'use Podlite;', '=alias X first', "=\tsecond", '', 'print "after\n";' );

prints( 'an =alias continuation at another column stays Perl', "x=7\n",
    'use Podlite;', 'my $x', '    =alias X a', '  = 7;', 'print "x=$x\n";' );

# Behaviour kept from 1.00

prints( '=config with a continuation', "after\n",
    'use Podlite;', '=config head1 :numbered', '=   :folded', 'print "after\n";' );

done_testing();

#!/usr/bin/perl

# Created for https://github.com/matisse/Perl-Metrics-Simple/issues/12

use strict;
use warnings;

use English qw(-no_match_vars);
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Perl::Metrics::Simple;

use Test::More tests => 5;

test_modifier( after => q{foo} );

test_modifier( after => q{'foo'} );

test_modifier( after => q{"foo"} );

test_modifier( after => q< qq[foo] > );

test_modifier( after => q{some::package::foo} );

exit;

sub test_modifier {
    my ( $modifier, $modificand ) = @_;
    my $code = qq[
		$modifier $modificand => sub {
			return "modified";
		};
	];

    # diag $code;
    my $analyzer = Perl::Metrics::Simple->new;
    my $analysis = eval { $analyzer->analyze_files( \$code ) } or diag $EVAL_ERROR;
    isa_ok( $analysis, 'Perl::Metrics::Simple::Analysis' );
}


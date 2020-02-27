package main;

use strict;
use warnings;

use Test::More 0.88;

require_ok 'PPIx::QuoteLike::Constant'
    or BAIL_OUT $@;

require_ok 'PPIx::QuoteLike::Utils'
    or BAIL_OUT $@;

require_ok 'PPIx::QuoteLike::Token'
    or BAIL_OUT $@;

require_ok 'PPIx::QuoteLike::Token::Control'
    or BAIL_OUT $@;

require_ok 'PPIx::QuoteLike::Token::Delimiter'
    or BAIL_OUT $@;

require_ok 'PPIx::QuoteLike::Token::Interpolation'
    or BAIL_OUT $@;

require_ok 'PPIx::QuoteLike::Token::String'
    or BAIL_OUT $@;

require_ok 'PPIx::QuoteLike::Token::Structure'
    or BAIL_OUT $@;

require_ok 'PPIx::QuoteLike::Token::Unknown'
    or BAIL_OUT $@;

require_ok 'PPIx::QuoteLike::Token::Whitespace'
    or BAIL_OUT $@;

require_ok 'PPIx::QuoteLike'
    or BAIL_OUT $@;

my $ms = eval { PPIx::QuoteLike->new( q<''> ) };
isa_ok $ms, 'PPIx::QuoteLike'
    or BAIL_OUT $@;

require_ok 'PPIx::QuoteLike::Dumper';

my $dmp = eval { PPIx::QuoteLike::Dumper->new( q<''> ) };
isa_ok $dmp, 'PPIx::QuoteLike::Dumper'
    or BAIL_OUT $@;

foreach my $class ( qw{
	PPI::Token::Quote
	PPI::Token::QuoteLike::Backtick
	PPI::Token::QuoteLike::Command
	PPI::Token::QuoteLike::Readline
	PPI::Token::HereDoc
    } ) {
    my $obj = bless {}, $class;
    # Force scalar context so returning nothing is interpreted as a
    # false value.
    ok scalar PPIx::QuoteLike::Utils::is_ppi_quotelike_element( $obj ),
	"$class is a quotelike element"
	or BAIL_OUT;
}

foreach my $class ( qw{
    PPI::Token::QuoteLike::Words
    PPI::Token::QuoteLike::Regexp
    } ) {
    my $obj = bless {}, $class;
    ok !PPIx::QuoteLike::Utils::is_ppi_quotelike_element( $obj ),
	"$class is not a quotelike element"
	or BAIL_OUT;
}

foreach my $class ( Fubar => [] ) {
    ok !PPIx::QuoteLike::Utils::is_ppi_quotelike_element( $class ),
	"$class is not a quotelike element"
	or BAIL_OUT;
}

done_testing;

1;

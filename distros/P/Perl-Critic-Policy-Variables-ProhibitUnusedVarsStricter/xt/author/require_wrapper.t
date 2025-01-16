package main;

use 5.006001;

use strict;
use warnings;

use PPI::Document 1.281;
use Perl::Critic::Utils qw{ is_function_call is_method_call };
use Test::More 0.88;	# Because of done_testing();

note <<'EOD';

Because we make little sub-PPI::Document objects to sort out stuff that
is opaque to PPI itself, there are PPI methods that have to be called
via wrapper methods for things to work out. A failure here means that
one of the methods that should be wrapped was called directly.

EOD

open my $fh, '<:encoding(utf-8)', 'MANIFEST'
    or plan skip_all => "Unable to open MANIFEST: $!";
{
    local $_ = undef;	# while (<>) ... does not localize $_.

    while ( <$fh> ) {
	chomp;
	s/ \t .* //smx;
	m| \A lib/ .* \.pm \z |smx
	    or next;
	require_wrapper( $_,
	    ppi	=> '_get_derived_ppi_document',
	    parent	=> '_get_parent_element,_element_is_in_lexical_scope_after_statement_containing',
	);
    }
}

sub require_wrapper {
    my ( $file, %arg ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $arg{$_} = { map { $_ => 1 } split qr< \s* , \s* >smx, $arg{$_} }
	for keys %arg;
    my $ppi = PPI::Document->new ( $file )
	or return fail "Unable to make PPI::Document for $file";
    my $pass = 1;
    WORD_LOOP:
    foreach my $sub_elem ( @{ $ppi->find( 'PPI::Token::Word' ) || [] } ) {
	is_method_call( $sub_elem )
	    or is_function_call( $sub_elem )
	    or next;
	$arg{ my $sub_name = $sub_elem->content() }
	    or next;
	my $caller_elem = $sub_elem;
	while ( $caller_elem = $caller_elem->statement() ) {
	    $caller_elem->isa( 'PPI::Statement::Sub' )
		or next;
	    my $caller_name = $caller_elem->name()
		or next;
	    $arg{$sub_name}{$caller_name}
		or $pass = fail format_miscall( $file, $sub_elem, $caller_name )
		or diag possible_wrappers( $sub_elem, $arg{$sub_name} );
	    next WORD_LOOP;
	} continue {
	    $caller_elem = $caller_elem->parent()
		or last;
	}
	$pass = fail format_miscall( $file, $sub_elem, 'mainline' )
	    or diag possible_wrappers( $sub_elem, $arg{$sub_name} );
    }
    $pass
	and pass $file;
    return $pass;
}

sub format_miscall {
    my ( $file, $sub_elem, $caller_name ) = @_;
    return sprintf '%s called in sub %s in %s at line %d column %d',
	$sub_elem->content(), $caller_name, $file,
	$sub_elem->logical_line_number(),
	$sub_elem->column_number();
}

sub possible_wrappers {
    my ( $wrapped, $hash ) = @_;
    my @arg = sort keys %{ $hash }
	or die 'BUG - no wrappers specified';
    @arg == 1
	and return "Wrapper for $wrapped(): $arg[0]()";
    return "Wrappers for $wrapped(): " . join ', ', map { "$_()" } @arg;
}

done_testing;

1;

# ex: set textwidth=72 :

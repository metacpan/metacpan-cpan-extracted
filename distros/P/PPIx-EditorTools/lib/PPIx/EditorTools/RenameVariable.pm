package PPIx::EditorTools::RenameVariable;

# ABSTRACT: Lexically replace a variable name in Perl code

use 5.008;
use strict;
use warnings;
use Carp;

use base 'PPIx::EditorTools';
use Class::XSAccessor;

our $VERSION = '0.18';

=pod

=head1 NAME

PPIx::EditorTools::RenameVariable - Lexically replace a variable name in Perl code

=head1 SYNOPSIS

    my $munged = PPIx::EditorTools::RenameVariable->new->rename(
        code        => $code,
        line        => 15,
        column      => 13,
        replacement => 'stuff',
    );
    my $code_as_strig = $munged->code;
    my $code_as_ppi   = $munged->ppi;
    my $location      = $munged->element->location;

=head1 DESCRIPTION

This module will lexically replace a variable name.

=head1 METHODS

=over 4

=item new()

Constructor. Generally shouldn't be called with any arguments.

=item rename( ppi => PPI::Document $ppi, line => Int, column => Int, replacement => Str )
=item rename( code => Str $code, line => Int, column => Int, replacement => Str )
=item rename( code => Str $code, line => Int, column => Int, to_camel_case => Bool, [ucfirst => Bool] )
=item rename( code => Str $code, line => Int, column => Int, from_camel_case => Bool, [ucfirst => Bool] )

Accepts either a C<PPI::Document> to process or a string containing
the code (which will be converted into a C<PPI::Document>) to process.
Renames the variable found at line, column with that supplied in the C<replacement>
parameter and returns a C<PPIx::EditorTools::ReturnObject> with the
new code available via the C<ppi> or C<code> accessors, as a
C<PPI::Document> or C<string>, respectively. The C<PPI::Token> found at
line, column is available via the C<element> accessor.

Instead of specifying an explicit replacement variable name, you may
choose to use the C<to_camel_case> or C<from_camel_case> options that automatically
convert to/from camelCase. In that mode, the C<ucfirst> option will force
uppercasing of the first letter.

You can not specify a replacement name and use the C<to/from_camel_case>
options.

Croaks with a "no token" exception if no token is found at the location.
Croaks with a "no declaration" exception if unable to find the declaration.

=back

=cut

sub rename {
	my ( $self, %args ) = @_;
	$self->process_doc(%args);
	my $column = $args{column} || croak "column required";
	my $line   = $args{line}   || croak "line required";
	my $location = [ $line, $column ];
	my $replacement = $args{replacement};
	if ( ( $args{to_camel_case} or $args{from_camel_case} )
		and defined $replacement )
	{
		croak("Can't accept both replacement name and to_camel_case/from_camel_case");
	} elsif ( not $args{to_camel_case}
		and not $args{from_camel_case}
		and not defined $replacement )
	{
		croak("Need either 'replacement' or to/from_camel_case options");
	}

	my $doc = $self->ppi;
	my $token = PPIx::EditorTools::find_token_at_location( $doc, $location );

	die "no token found" unless defined $token;

	my $declaration = PPIx::EditorTools::find_variable_declaration($token);
	die "no declaration" unless defined $declaration;

	$doc->index_locations;

	my $scope = $declaration;
	while ( not $scope->isa('PPI::Document')
		and not $scope->isa('PPI::Structure::Block') )
	{
		$scope = $scope->parent;
	}

	my $token_str = $token->content;
	my $varname   = $token->symbol;
	if ( not defined $replacement ) {
		if ( $args{from_camel_case} ) {
			$replacement = _from_camel_case( $varname, $args{ucfirst} );
		} else { # $args{to_camel_case}
			$replacement = _to_camel_case( $varname, $args{ucfirst} );
		}
		if ( $varname eq $replacement ) {
			return PPIx::EditorTools::ReturnObject->new(
				ppi     => $doc,
				element => $token
			);
		}
	}

	#warn "VARNAME: $varname";

	# TODO: This could be part of PPI somehow?
	# The following string of hacks is simply for finding symbols in quotelikes and regexes
	my $type = substr( $varname, 0, 1 );
	my $brace = $type eq '@' ? '[' : ( $type eq '%' ? '{' : '' );

	my @patterns;
	if ( $type eq '@' or $type eq '%' ) {
		my $accessv = $varname;
		$accessv =~ s/^\Q$type\E/\$/;
		@patterns = (
			quotemeta( _curlify($varname) ),
			quotemeta($varname),
			quotemeta($accessv) . '(?=' . quotemeta($brace) . ')',
		);
		if ( $type eq '%' ) {
			my $slicev = $varname;
			$slicev =~ s/^\%/\@/;
			push @patterns, quotemeta($slicev) . '(?=' . quotemeta($brace) . ')';
		} elsif ( $type eq '@' ) {
			my $indexv = $varname;
			$indexv =~ s/^\@/\$\#/;
			push @patterns, quotemeta($indexv);
		}
	} else {
		@patterns = (
			quotemeta( _curlify($varname) ),
			quotemeta($varname) . "(?![\[\{])"
		);
	}
	my %unique;
	my $finder_regexp = '(?:' . join( '|', grep { !$unique{$_}++ } @patterns ) . ')';

	$finder_regexp = qr/$finder_regexp/; # used to find symbols in quotelikes and regexes
	                                     #warn $finder_regexp;

	$replacement =~ s/^\W+//;

	$scope->find(
		sub {
			my $node = $_[1];
			if ( $node->isa("PPI::Token::Symbol") ) {
				return 0 unless $node->symbol eq $varname;

				# TODO do this without breaking encapsulation!
				$node->{content} = substr( $node->content(), 0, 1 ) . $replacement;
			}

			# This used to be a simple "if". Patrickas: "[elsif] resolves this
			# issue but it may introduce other bugs since I am not sure I
			# understand the code that follows it."
			# See Padre trac ticket #655 for the full comment. Remove this
			# comment if there are new bugs resulting from this change.
			elsif ( $type eq '@' and $node->isa("PPI::Token::ArrayIndex") ) { # $#foo
				return 0
					unless substr( $node->content, 2 ) eq substr( $varname, 1 );

				# TODO do this without breaking encapsulation!
				$node->{content} = '$#' . $replacement;
			} elsif ( $node->isa("PPI::Token") ) { # the case of potential quotelikes and regexes
				my $str = $node->content;
				if ($str =~ s{($finder_regexp)([\[\{]?)}<
				        if ($1 =~ tr/{//) { substr($1, 0, ($1=~tr/#//)+1) . "{$replacement}$2" }
				        else              { substr($1, 0, ($1=~tr/#//)+1) . "$replacement$2" }
				    >ge
					)
				{

					# TODO do this without breaking encapsulation!
					$node->{content} = $str;
				}
			}
			return 0;
		},
	);

	return PPIx::EditorTools::ReturnObject->new(
		ppi     => $doc,
		element => $token,
	);
}

# converts a variable name to camel case and optionally converts the
# first character to upper case
sub _to_camel_case {
	my $var     = shift;
	my $ucfirst = shift;
	my $prefix;
	if ( $var =~ s/^(\W*_)// ) {
		$prefix = $1;
	}
	$var =~ s/_([[:alpha:]])/\u$1/g;
	$var =~ s/^([^[:alpha:]]*)([[:alpha:]])/$1\u$2/ if $ucfirst;
	$var = $prefix . $var if defined $prefix;
	return $var;
}

sub _from_camel_case {
	my $var     = shift;
	my $ucfirst = shift;
	my $prefix;
	if ( $var =~ s/^(\W*_?)// ) {
		$prefix = $1;
	}
	if ($ucfirst) {
		$var = lcfirst($var);
		$var =~ s/([[:upper:]])/_\u$1/g;
		$var =~ s/^([^[:alpha:]]*)([[:alpha:]])/$1\u$2/;
	} else {
		$var =~ s/^([^[:alpha:]]*)([[:alpha:]])/$1\l$2/;
		$var =~ s/([[:upper:]])/_\l$1/g;
	}
	$var = $prefix . $var if defined $prefix;
	return $var;
}


sub _curlify {
	my $var = shift;
	if ( $var =~ s/^([\$\@\%])(.+)$/${1}{$2}/ ) {
		return ($var);
	}
	return ();
}

1;

__END__

=head1 SEE ALSO

This class inherits from C<PPIx::EditorTools>.
Also see L<App::EditorTools>, L<Padre>, and L<PPI>.

=cut

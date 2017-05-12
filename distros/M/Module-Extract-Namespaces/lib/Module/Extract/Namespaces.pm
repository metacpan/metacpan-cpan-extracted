package Module::Extract::Namespaces;
use strict;

use warnings;
no warnings;

use subs qw();
use vars qw($VERSION);

$VERSION = '1.02';

use Carp qw(croak);
use File::Spec::Functions qw(splitdir catfile);
use PPI;

=head1 NAME

Module::Extract::Namespaces - extract the package declarations from a module

=head1 SYNOPSIS

	use Module::Extract::Namespaces;

	# in scalar context, extract first package namespace
	my $namespace  = Module::Extract::Namespaces->from_file( $filename );
	if( Module::Extract::Namespaces->error ) { ... }

	# in list context, extract all namespaces
	my @namespaces = Module::Extract::Namespaces->from_file( $filename );
	if( Module::Extract::Namespaces->error ) { ... }

	# can do the Perl 5.12 package syntax with possible versions
	# in list context, extract all namespaces and versions as duples
	my @namespaces = Module::Extract::Namespaces->from_file( $filename, 1 );
	if( Module::Extract::Namespaces->error ) { ... }


=head1 DESCRIPTION

This module extracts package declarations from Perl code without
running the code.

It does not extract:

=over 4

=item * packages declared dynamically (e.g. in C<eval>)

=item * packages created as part of a fully qualified variable name

=back

=head2 Class methods

=over 4

=item from_module( MODULE, [ @DIRS ] )

Extract the namespaces declared in MODULE. In list context, it returns
all of the namespaces, including possible duplicates. In scalar
context it returns the first declared namespace.

You can specify a list of directories to search for the module. If you
don't, it uses C<@INC> by default.

If it cannot find MODULE, it returns undef in scalar context and the
empty list in list context.

On failure it returns nothing, but you have to check with C<error> to
see if that is really an error or a file with no namespaces in it.

=cut

sub from_module {
	my( $class, $module, @dirs ) = @_;

	@dirs = @INC unless @dirs;
	$class->_clear_error;

	my $absolute_path = $class->_module_to_file( $module, @dirs );
	unless( defined $absolute_path ) {
		$class->_set_error( "Did not find module [$module] in [@dirs]!" );
		return;
		}

	if( wantarray ) { my @a = $class->from_file( $absolute_path ) }
	else            { scalar  $class->from_file( $absolute_path ) }
	}

sub _module_to_file {
	my( $class, $module, @dirs ) = @_;

	my @module_parts = split /\b(?:::|')\b/, $module;
	$module_parts[-1] .= '.pm';
	
	foreach my $dir ( @dirs ) {
		unless( -d $dir ) {
			carp( "The path [$dir] does not appear to be a directory" );
			next;
			}
		my @dir_parts = splitdir( $dir );
		my $path = catfile( @dir_parts, @module_parts );
		next unless -e $path;
		return $path;
		}

	return;
	}
	
sub _rel2abs {

	}

=item from_file( FILENAME [,WITH_VERSIONS] )

Extract the namespaces declared in FILENAME. In list context, it
returns all of the namespaces, including possible duplicates. In
scalar context it returns the first declared namespace.

If FILENAME does not exist, it returns undef in scalar context and the
empty list in list context.

On failure it returns nothing, but you have to check with C<error> to
see if that is really an error or a file with no namespaces in it.

=cut

sub from_file {
	my( $class, $file, $with_versions ) = @_;

	$class->_clear_error;

	unless( -e $file ) {
		$class->_set_error( "File [$file] does not exist!" );
		return;
		}

	my $Document = $class->get_pdom( $file );
	return unless $Document;

	my $method = $with_versions ?
		'get_namespaces_and_versions_from_pdom'
		:
		'get_namespaces_from_pdom'
		;

	my @namespaces = $class->$method( $Document );

	if( wantarray ) { @namespaces }
	else            { $namespaces[0] }
	}


=back

=head2 Subclassable hooks

=over 4

=item $class->pdom_base_class()

Return the base class for the PDOM. This is C<PPI> by default. If you
want to use something else, you'll have to change all the other PDOM
methods to adapt to the different interface.

This is the class name to use with C<require> to load the module that
while handle the parsing.

=cut

sub pdom_base_class { 'PPI' }

=item $class->pdom_document_class()

Return the class name to use to create the PDOM object. This is
C<PPI::Document>.

=cut


sub pdom_document_class { 'PPI::Document' }

=item get_pdom( FILENAME )

Creates the PDOM from FILENAME. This depends on calls to
C<pdom_base_class> and C<pdom_document_class>.

=cut

sub get_pdom {
	my( $class, $file ) = @_;

	my $pdom_class = $class->pdom_base_class;

	eval "require $pdom_class";

	my $Document = eval {
		my $pdom_document_class = $class->pdom_document_class;

		my $d = $pdom_document_class->new( $file );
		die $pdom_document_class->errstr unless $d;

		$class->pdom_preprocess( $d );
		$d;
		};

	if( $@ ) {
		$class->_set_error( "Could not get PDOM for $file: $@" );
		return;
		}

	$Document;
	}

=item $class->pdom_preprocess( PDOM )

Override this method to play with the PDOM before extracting the
package declarations.

By default, it strips Pod and comments from the PDOM.

=cut

sub pdom_preprocess {
	my( $class, $Document ) = @_;

	eval {
		$class->pdom_strip_pod( $Document );
		$class->pdom_strip_comments( $Document );
		};

	return 1;
	}

=item $class->pdom_strip_pod( PDOM )

Strips Pod documentation from the PDOM.

=cut

sub pdom_strip_pod      { $_[1]->prune('PPI::Token::Pod') }

=item $class->pdom_strip_comments( PDOM )

Strips comments from the PDOM.

=cut

sub pdom_strip_comments { $_[1]->prune('PPI::Token::Comment') }

=item $class->get_namespaces_from_pdom( PDOM )

Extract the namespaces from the PDOM. It returns a list of package
names in the order that it finds them in the PDOM. It does not
remove duplicates (do that later if you like).

=cut

BEGIN {

if( $PPI::VERSION <= 1.215 ) {
	no warnings 'redefine';
	sub PPI::Statement::Package::__LEXER__normal { '' }
	sub PPI::Lexer::_continues {
		package PPI::Lexer;
		my ($self, $Statement, $Token) = @_;
		# my $self      = shift;
		# my $Statement = _INSTANCE(shift, 'PPI::Statement') or die "Bad param 1";
		# my $Token     = _INSTANCE(shift, 'PPI::Token')     or die "Bad param 2";

		# Handle the simple block case
		# { print 1; }
		if (
			$Statement->schildren == 1
			and
			$Statement->schild(0)->isa('PPI::Structure::Block')
		) {
			return '';
		}

		# Alrighty then, there are only six implied end statement types,
		# ::Scheduled blocks, ::Sub declarations, ::Compound, ::Package, ::Given, and ::When
		# statements.
		unless ( ref($Statement) =~ /\b(?:Scheduled|Sub|Compound|Given|When|Package)$/ ) {
			return 1;
		}

		if ( $Statement->isa('PPI::Statement::Package') ) {
			# This should be one of the following
			# package Foo;
			# package Foo VERSION;
			# package Foo BLOCK
			# package Foo VERSION BLOCK
			my @schildren = $Statement->schildren;

			if ( $schildren[-1]->isa('PPI::Structure::Block') ) {
				return 0;
			}

			return 1;
		}

		# Of these five, ::Scheduled, ::Sub, ::Given, and ::When follow the same
		# simple rule and can be handled first.
		my @part      = $Statement->schildren;
		my $LastChild = $part[-1];
		unless ( $Statement->isa('PPI::Statement::Compound') ) {
			# If the last significant element of the statement is a block,
			# then a scheduled statement is done, no questions asked.
			return ! $LastChild->isa('PPI::Structure::Block');
		}

		# Now we get to compound statements, which kind of suck (to lex).
		# However, of them all, the 'if' type, which includes unless, are
		# relatively easy to handle compared to the others.
		my $type = $Statement->type;

		if ( $type eq 'if' ) {
			# This should be one of the following
			# if (EXPR) BLOCK
			# if (EXPR) BLOCK else BLOCK
			# if (EXPR) BLOCK elsif (EXPR) BLOCK ... else BLOCK

			# We only implicitly end on a block
			unless ( $LastChild->isa('PPI::Structure::Block') ) {
				# if (EXPR) ...
				# if (EXPR) BLOCK else ...
				# if (EXPR) BLOCK elsif (EXPR) BLOCK ...
				return 1;
			}

			# If the token before the block is an 'else',
			# it's over, no matter what.
			my $NextLast = $Statement->schild(-2);
			if (
				$NextLast
				and
				$NextLast->isa('PPI::Token')
				and
				$NextLast->isa('PPI::Token::Word')
				and
				$NextLast->content eq 'else'
			) {
				return '';
			}

			# Otherwise, we continue for 'elsif' or 'else' only.
			if (
				$Token->isa('PPI::Token::Word')
				and (
					$Token->content eq 'else'
					or
					$Token->content eq 'elsif'
				)
			) {
				return 1;
			}

			return '';
		}

		if ( $type eq 'label' ) {
			# We only have the label so far, could be any of
			# LABEL while (EXPR) BLOCK
			# LABEL while (EXPR) BLOCK continue BLOCK
			# LABEL for (EXPR; EXPR; EXPR) BLOCK
			# LABEL foreach VAR (LIST) BLOCK
			# LABEL foreach VAR (LIST) BLOCK continue BLOCK
			# LABEL BLOCK continue BLOCK

			# Handle cases with a word after the label
			if (
				$Token->isa('PPI::Token::Word')
				and
				$Token->content =~ /^(?:while|until|for|foreach)$/
			) {
				return 1;
			}

			# Handle labelled blocks
			if ( $Token->isa('PPI::Token::Structure') && $Token->content eq '{' ) {
				return 1;
			}

			return '';
		}

		# Handle the common "after round braces" case
		if ( $LastChild->isa('PPI::Structure') and $LastChild->braces eq '()' ) {
			# LABEL while (EXPR) ...
			# LABEL while (EXPR) ...
			# LABEL for (EXPR; EXPR; EXPR) ...
			# LABEL for VAR (LIST) ...
			# LABEL foreach VAR (LIST) ...
			# Only a block will do
			return $Token->isa('PPI::Token::Structure') && $Token->content eq '{';
		}

		if ( $type eq 'for' ) {
			# LABEL for (EXPR; EXPR; EXPR) BLOCK
			if (
				$LastChild->isa('PPI::Token::Word')
				and
				$LastChild->content =~ /^for(?:each)?\z/
			) {
				# LABEL for ...
				if (
					(
						$Token->isa('PPI::Token::Structure')
						and
						$Token->content eq '('
					)
					or
					$Token->isa('PPI::Token::QuoteLike::Words')
				) {
					return 1;
				}

				if ( $LastChild->isa('PPI::Token::QuoteLike::Words') ) {
					# LABEL for VAR QW{} ...
					# LABEL foreach VAR QW{} ...
					# Only a block will do
					return $Token->isa('PPI::Token::Structure') && $Token->content eq '{';
				}

				# In this case, we can also behave like a foreach
				$type = 'foreach';

			} elsif ( $LastChild->isa('PPI::Structure::Block') ) {
				# LABEL for (EXPR; EXPR; EXPR) BLOCK
				# That's it, nothing can continue
				return '';

			} elsif ( $LastChild->isa('PPI::Token::QuoteLike::Words') ) {
				# LABEL for VAR QW{} ...
				# LABEL foreach VAR QW{} ...
				# Only a block will do
				return $Token->isa('PPI::Token::Structure') && $Token->content eq '{';
			}
		}

		# Handle the common continue case
		if ( $LastChild->isa('PPI::Token::Word') and $LastChild->content eq 'continue' ) {
			# LABEL while (EXPR) BLOCK continue ...
			# LABEL foreach VAR (LIST) BLOCK continue ...
			# LABEL BLOCK continue ...
			# Only a block will do
			return $Token->isa('PPI::Token::Structure') && $Token->content eq '{';
		}

		# Handle the common continuable block case
		if ( $LastChild->isa('PPI::Structure::Block') ) {
			# LABEL while (EXPR) BLOCK
			# LABEL while (EXPR) BLOCK ...
			# LABEL for (EXPR; EXPR; EXPR) BLOCK
			# LABEL foreach VAR (LIST) BLOCK
			# LABEL foreach VAR (LIST) BLOCK ...
			# LABEL BLOCK ...
			# Is this the block for a continue?
			if ( _INSTANCE($part[-2], 'PPI::Token::Word') and $part[-2]->content eq 'continue' ) {
				# LABEL while (EXPR) BLOCK continue BLOCK
				# LABEL foreach VAR (LIST) BLOCK continue BLOCK
				# LABEL BLOCK continue BLOCK
				# That's it, nothing can continue this
				return '';
			}

			# Only a continue will do
			return $Token->isa('PPI::Token::Word') && $Token->content eq 'continue';
		}

		if ( $type eq 'block' ) {
			# LABEL BLOCK continue BLOCK
			# Every possible case is covered in the common cases above
		}

		if ( $type eq 'while' ) {
			# LABEL while (EXPR) BLOCK
			# LABEL while (EXPR) BLOCK continue BLOCK
			# LABEL until (EXPR) BLOCK
			# LABEL until (EXPR) BLOCK continue BLOCK
			# The only case not covered is the while ...
			if (
				$LastChild->isa('PPI::Token::Word')
				and (
					$LastChild->content eq 'while'
					or
					$LastChild->content eq 'until'
				)
			) {
				# LABEL while ...
				# LABEL until ...
				# Only a condition structure will do
				return $Token->isa('PPI::Token::Structure') && $Token->content eq '(';
			}
		}

		if ( $type eq 'foreach' ) {
			# LABEL foreach VAR (LIST) BLOCK
			# LABEL foreach VAR (LIST) BLOCK continue BLOCK
			# The only two cases that have not been covered already are
			# 'foreach ...' and 'foreach VAR ...'

			if ( $LastChild->isa('PPI::Token::Symbol') ) {
				# LABEL foreach my $scalar ...
				# Open round brace, or a quotewords
				return 1 if $Token->isa('PPI::Token::Structure') && $Token->content eq '(';
				return 1 if $Token->isa('PPI::Token::QuoteLike::Words');
				return '';
			}

			if ( $LastChild->content eq 'foreach' or $LastChild->content eq 'for' ) {
				# There are three possibilities here
				if (
					$Token->isa('PPI::Token::Word')
					and (
						($STATEMENT_CLASSES{ $Token->content } || '')
						eq
						'PPI::Statement::Variable'
					)
				) {
					# VAR == 'my ...'
					return 1;
				} elsif ( $Token->content =~ /^\$/ ) {
					# VAR == '$scalar'
					return 1;
				} elsif ( $Token->isa('PPI::Token::Structure') and $Token->content eq '(' ) {
					return 1;
				} elsif ( $Token->isa('PPI::Token::QuoteLike::Words') ) {
					return 1;
				} else {
					return '';
				}
			}

			if (
				($STATEMENT_CLASSES{ $LastChild->content } || '')
				eq
				'PPI::Statement::Variable'
			) {
				# LABEL foreach my ...
				# Only a scalar will do
				return $Token->content =~ /^\$/;
			}

			# Handle the rare for my $foo qw{bar} ... case
			if ( $LastChild->isa('PPI::Token::QuoteLike::Words') ) {
				# LABEL for VAR QW ...
				# LABEL foreach VAR QW ...
				# Only a block will do
				return $Token->isa('PPI::Token::Structure') && $Token->content eq '{';
			}
		}

		# Something we don't know about... what could it be
		PPI::Exception->throw("Illegal state in '$type' compound statement");
	}
	}

}


sub get_namespaces_from_pdom {
	my( $class, $Document ) = @_;

	my @array = $class->_get_namespaces_from_pdom( $Document );
	map { $_->[0] } @array;
	}

=item $class->get_namespaces_and_versions_from_pdom( PDOM )

This extracts version information if the package statement uses the
Perl 5.12 syntax:

	package NAME VERSION BLOCK

Extract the namespaces from the PDOM. It returns a list anonymous
arrays of package names and versions in the order that it finds them
in the PDOM. It does not remove duplicates (do that later if you like).

=cut

sub get_namespaces_and_versions_from_pdom {
	my( $class, $Document ) = @_;

	my @array = $class->_get_namespaces_from_pdom( $Document );
	}

sub _get_namespaces_from_pdom {
	my( $class, $Document ) = @_;

	my $package_statements = $Document->find(
		sub {
			$_[1]->isa('PPI::Statement::Package')
				?
			defined eval { $_[1]->namespace }
				:
			0
			}
		) || [];

	my @namespaces = eval {
		map {
			 #                 $1                $2
			/package \s+ (\w+(?:::\w+)*) (?:\s* (\S+))? \s* (?:;|\{) /x;
			[ $1, $2 ]
			} @$package_statements
		};

	#print STDERR "Got namespaces @namespaces\n";

	@namespaces;
	}

=item $class->error

Return the error from the last call to C<get_modules>.

=cut

BEGIN {
my $Error = '';

sub _set_error   { $Error = $_[1]; }

sub _clear_error { $Error = '' }

sub error        { $Error }
}

=back

=head1 TO DO

* Add caching based on file digest?

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/module-extract-namespaces.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

This module was partially funded by The Perl Foundation
(www.perlfoundation.org) and LogicLAB (www.logiclab.dk), both of whom
provided travel assistance to the 2008 Oslo QA Hackathon where I
created this module.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2014, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;

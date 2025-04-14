use v5.10;

package Module::Extract::Use;
use strict;

use warnings;
no warnings;

our $VERSION = '1.054';

=encoding utf8

=head1 NAME

Module::Extract::Use - Discover the modules a module explicitly uses

=head1 SYNOPSIS

	use Module::Extract::Use;

	my $extor = Module::Extract::Use->new;

	my @modules = $extor->get_modules( $file );
	if( $extor->error ) { ... }

	my $details = $extor->get_modules_with_details( $file );
	foreach my $detail ( @$details ) {
		printf "%s %s imports %s\n",
			$detail->module, $detail->version,
			join ' ', @{ $detail->imports }
		}

=head1 DESCRIPTION

Extract the names of the modules used in a file using a static
analysis. Since this module does not run code, it cannot find dynamic
uses of modules, such as C<eval "require $class">. It only reports modules
that the file loads directly or are in the import lists for L<parent>
or L<base>.

The module can handle the conventional inclusion of modules with either
C<use> or C<require> as the statement:

	use Foo;
	require Foo;

	use Foo 1.23;
	use Foo qw(this that);

It now finds C<require> as an expression, which is useful to lazily
load a module once (and may be faster):

	sub do_something {
		state $rc = require Foo;
		...
		}

Additionally, it finds module names used with C<parent> and C<base>,
either of which establish an inheritance relationship:

	use parent qw(Foo);
	use base qw(Foo);

In the case of namespaces found in C<base> or C<parent>, the value of
the C<direct> method is false. In all other cases, it is true. You
can then skip those namespaces:

	my $details = $extor->get_modules_with_details( $file );
	foreach my $detail ( @$details ) {
		next unless $detail->direct;

		...
		}

This module does not discover runtime machinations to load something,
such as string evals:

	eval "use Foo";

	my $bar = 'Bar';
	eval "use $bar";

If you want that, you might consider L<Module::ExtractUse> (a confusingly
similar name).

=cut

=over 4

=item new

Makes an object. The object doesn't do anything just yet, but you need
it to call the methods.

=cut

sub new {
	my $class = shift;

	my $self = bless {}, $class;

	$self->init;

	$self;
	}

=item init

Set up the object. You shouldn't need to call this yourself.

=cut

sub init {
	$_[0]->_clear_error;
	}

=item get_modules( FILE )

Returns a list of namespaces explicity use-d in FILE. Returns the
empty list if the file does not exist or if it can't parse the file.

Each used namespace is only in the list even if it is used multiple
times in the file. The order of the list does not correspond to
anything so don't use the order to infer anything.

=cut

sub get_modules {
	my( $self, $file ) = @_;

	$self->_clear_error;

	my $details = $self->get_modules_with_details( $file );

	my @modules = map { $_->module } @$details;

	@modules;
	}

=item get_modules_with_details( FILE )

Returns a list of hash references, one reference for each namespace
explicitly use-d in FILE. Each reference has keys for:

	namespace - the namespace, always defined
	version   - defined if a module version was specified
	imports   - an array reference to the import list
	pragma    - true if the module thinks this namespace is a pragma
	direct    - false if the module name came from parent or base

Each used namespace is only in the list even if it is used multiple
times in the file. The order of the list does not correspond to
anything so don't use the order to infer anything.

=cut

sub get_modules_with_details {
	my( $self, $file ) = @_;

	$self->_clear_error;

	my $modules = $self->_get_ppi_for_file( $file );
	return [] unless defined $modules;

	$modules;
	}

sub _get_ppi_for_file {
	my( $self, $file ) = @_;

	unless( -e $file ) {
		$self->_set_error( ref( $self ) . ": File [$file] does not exist!" );
		return;
		}

	require PPI;

	my $Document = eval { PPI::Document->new( $file ) };
	unless( $Document ) {
		$self->_set_error( ref( $self ) . ": Could not parse file [$file]" );
		return;
		}

	# this handles the
	#   use Foo;
	#   use Bar;
	my $regular_modules = $self->_regular_load( $Document );

	# this handles
	#   use parent qw(...)
	my $isa_modules      = $self->_isa_load( $regular_modules );

	# this handles
	#   my $rc = require Foo;
	my $expression_loads = $self->_expression_load( $Document );

	my @modules = map { @$_ }
		$regular_modules,
		$isa_modules,
		$expression_loads
		;

	return \@modules;
	}

sub _regular_load {
	my( $self, $Document ) = @_;

	my $modules = $Document->find(
		sub {
			$_[1]->isa( 'PPI::Statement::Include' )
			}
		);

	return [] unless $modules;

	my %Seen;
	my @modules =
		grep { ! $Seen{ $_->{module} }++ && $_->{module} }
		map  {
			my $hash = bless {
				direct  => 1,
				content => $_->content,
				pragma  => $_->pragma,
				module  => $_->module,
				imports => [ $self->_list_contents( $_->arguments ) ],
				version => eval{ $_->module_version->literal || ( undef ) },
				}, 'Module::Extract::Use::Item';
			} @$modules;

	\@modules;
	}

sub _isa_load {
	my( $self, $modules ) = @_;
	my @isa_modules =
		map {
			my $m = $_;
			map {
				bless {
					content => $m->content,
					pragma  => '',
					direct  => 0,
					module  => $_,
					imports => [],
					version => undef,
					}, 'Module::Extract::Use::Item';
				} @{ $m->imports };
			}
		grep { $_->module eq 'parent' or $_->module eq 'base' }
		@$modules;

	\@isa_modules;
	}

sub _expression_load {
	my( $self, $Document ) = @_;

	my $in_statements = $Document->find(
		sub {
			my $sib;
			$_[1]->isa( 'PPI::Token::Word' ) &&
			$_[1]->content eq 'require' &&
			( $sib = $_[1]->snext_sibling() ) &&
			$sib->isa( 'PPI::Token::Word' )
			}
		);

	return [] unless $in_statements;

	my @modules =
		map {
			bless {
				content => $_->parent->content,
				pragma  => undef,
				direct  => 1,
				module  => $_->snext_sibling->content,
				imports => [],
				version => undef,
				}, 'Module::Extract::Use::Item';
			}
		@$in_statements;

	\@modules;
	}

BEGIN {
package Module::Extract::Use::Item;

sub direct  { $_[0]->{direct}  }
sub content { $_[0]->{content} }
sub pragma  { $_[0]->{pragma}  }
sub module  { $_[0]->{module}  }
sub imports { $_[0]->{imports} }
sub version { $_[0]->{version} }
}

sub _list_contents {
	my( $self, $node ) = @_;

	eval {
		if( ! defined $node ) {
			return;
			}
		elsif( $node->isa( 'PPI::Token::QuoteLike::Words' ) ) {
			( $node->literal )
			}
		elsif( $node->isa( 'PPI::Structure::List' ) ) {
			my $nodes = $node->find( sub{ $_[1]->isa( 'PPI::Token::Quote' ) } );
			map { $_->string } @$nodes;
			}
		elsif( $node->isa( 'PPI::Token::Quote' ) ) {
			( $node->string );
			}
	};

	}

=item error

Return the error from the last call to C<get_modules>.

=cut

sub _set_error   { $_[0]->{error} = $_[1]; }

sub _clear_error { $_[0]->{error} = '' }

sub error        { $_[0]->{error} }

=back

=head1 TO DO

=head1 SEE ALSO

L<Module::ScanDeps>, L<Module::Extract>

=head1 SOURCE AVAILABILITY

The source code is in Github:

	https://github.com/briandfoy/module-extract-use

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2008-2025, brian d foy C<< <briandfoy@pobox.com> >>. All rights reserved.

This project is under the Artistic License 2.0.

=cut

1;

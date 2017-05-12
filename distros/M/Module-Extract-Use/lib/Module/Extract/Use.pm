package Module::Extract::Use;
use strict;

use warnings;
no warnings;

use subs qw();
use vars qw($VERSION);

$VERSION = '1.043';

=encoding utf8

=head1 NAME

Module::Extract::Use - Pull out the modules a module explicitly uses

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
that the file loads directly. Modules loaded with C<parent> or C<base>,
for instance, will will be in the import list for those pragmas but
won't have separate entries in the data this module returns.

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

Returns a list of namespaces explicity use-d in FILE. Returns undef if the
file does not exist or if it can't parse the file.

Each used namespace is only in the list even if it is used multiple times
in the file. The order of the list does not correspond to anything so don't
use the order to infer anything.

=cut

sub get_modules {
	my( $self, $file ) = @_;

	$self->_clear_error;

	my $details = $self->get_modules_with_details( $file );
	return unless defined $details;

	my @modules =
		map { $_->{module} }
		@$details;
	}

=item get_modules_with_details( FILE )

Returns a list of hash references, one reference for each namespace
explicitly use-d in FILE. Each reference has keys for:

	namespace - the namespace, always defined
	version   - defined if a module version was specified
	imports   - an array reference to the import list
	pragma    - true if the module thinks this namespace is a pragma

Each used namespace is only in the list even if it is used multiple
times in the file. The order of the list does not correspond to
anything so don't use the order to infer anything.

=cut

sub get_modules_with_details {
	my( $self, $file ) = @_;

	$self->_clear_error;

	my $modules = $self->_get_ppi_for_file( $file );
	return unless defined $modules;

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

	my $modules = $Document->find(
		sub {
			$_[1]->isa( 'PPI::Statement::Include' )  &&
				( $_[1]->type eq 'use' || $_[1]->type eq 'require' )
			}
		);

	return unless $modules;

	my %Seen;
	my @modules =
		grep { ! $Seen{ $_->{module} }++ && $_->{module} }
		map  {
			my $hash = bless {
				content => $_->content,
				pragma  => $_->pragma,
				module  => $_->module,
				imports => [ $self->_list_contents( $_->arguments ) ],
				version => eval{ $_->module_version->literal || ( undef ) },
				}, 'Module::Extract::Use::Item';
			} @$modules;

	return \@modules;
	}

BEGIN {
package Module::Extract::Use::Item;

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

=over 4

=item * Make it recursive, so it scans the source for any module that it finds.

=back

=head1 SEE ALSO

L<Module::ScanDeps>

=head1 SOURCE AVAILABILITY

The source code is in Github:

	git://github.com/briandfoy/module-extract-use.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2008-2017, brian d foy C<< <bdfoy@cpan.org> >>. All rights reserved.

This project is under the Artistic License 2.0.

=cut

1;

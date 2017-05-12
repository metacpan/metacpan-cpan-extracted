use utf8;
use v5.10;

package Module::Extract::DeclaredMinimumPerl;
use strict;

use warnings;
no warnings;

use subs qw();
use vars qw($VERSION);

$VERSION = '1.02';

=head1 NAME

Module::Extract::DeclaredMinimumPerl - Extract the version of Perl a module declares

=head1 SYNOPSIS

	use Module::Extract::DeclaredMinimumPerl;

	my $extor = Module::Extract::DeclaredMinimumPerl->new;

	my $version = $extor->get_minimum_declared_perl( $file );
	if( $extor->error ) { ... }

=head1 DESCRIPTION

Extract the largest declared Perl version and returns it as a
version object. For instance, in a script you might have:

  use v5.16;
  
This module will extract that C<v5.16> and return it. 

This module tries to handle any format that PPI will recognize, passing
them through version.pm to normalize them.

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

Set up the object. You shouldn't need to call this yourself. You can
override it though!

=cut

sub init {
	$_[0]->_clear_error;
	}

=item get_minimum_declared_perl( FILE )

Extracts all of the declared minimum versions for Perl, sorts them,
and returns the largest a version object.

=cut

sub get_minimum_declared_perl {
	my( $self, $file ) = @_;

	$self->_clear_error;

	my $versions = $self->_get_ppi_for_file( $file );
	return unless defined $versions;

	my @sorted = sort {
		eval { version->parse( $b->{version} ) }
		  <=>
		eval { version->parse( $a->{version} ) }
		} @$versions;

	eval { version->parse( $sorted[0]->{version} ) };
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
	my @versions =
		grep { $_->{version_literal} }
		map  {
			my $literal = $_->version_literal;
			$literal =~ s/\s//g;
			$literal = undef unless length $literal;
			my $hash = {
				version         => $_->version,
				version_literal => ( $literal // $_->version ), #/
				};
			} @$modules;

	return \@versions;
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

L<Module::Extract::Use>

=head1 SOURCE AVAILABILITY

The source code is in Github: git://github.com/briandfoy/Module-Extract-DeclaredMinimumPerl.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2014, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;

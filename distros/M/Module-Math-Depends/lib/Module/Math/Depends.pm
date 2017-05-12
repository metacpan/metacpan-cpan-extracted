package Module::Math::Depends;

=pod

=head1 NAME

Module::Math::Depends - Convenience object for manipulating module dependencies

=head1 DESCRIPTION

This is a small convenience module created originally as part of
L<Module::Inspector> but released seperately, in the hope that people
might find it useful in other contexts.

=head1 METHODS

=cut

use 5.005;
use strict;
use Carp         ();
use version      ();
use Params::Util qw{_CLASS _HASH _INSTANCE};

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Constructors

=head2 new

  my $deps = Module::Math::Depends->new;

Creates a new, empty, dependency set.

=cut

sub new {
	bless {}, $_[0];
}

=head2 from_hash

  my $deps = Module::Math::Depends->from_hash( \%modules );

Creates a new dependency set from a raw hashref of modules names
and versions.

=cut

sub from_hash {
	my $self = shift()->new;
	my $hash = _HASH(shift)
		or Carp::croak("Did not provide a HASH reference");

	# Add the deps
	foreach my $module ( keys %$hash ) {
		$self->add_module( $module => $hash->{$module} );
	}

	$self;
}





#####################################################################
# Main Methods

=head2 add_module

  $deps->add_module( 'My::Module' => '1.23' );

Adds a single module dependency to the set.

Returns true, or dies on error.

=cut

sub add_module {
	my $self    = shift;
	my $name    = _CLASS(shift)
		or Carp::croak("Invalid module name provided");
	my $version = defined($_[0])
		? ref($_[0])
			? _INSTANCE(shift, 'version')
			: version->new(shift)
		: version->new(0);
	unless ( defined $version ) {
		Carp::croak("Invalid version provided");
	}
	if ( $self->{$name} ) {
		if ( $version > $self->{$name} ) {
			$self->{$name} = $version;
		}
	} else {
		$self->{$name} = $version;
	}
	return 1;
}

=head2 merge

  $my_deps->merge( $your_deps );

The C<merge> method takes another dependency set and merges it into the
current one, taking the highest version where both sets contain a module.

Returns true or dies on error.

=cut

sub merge {
	my $self = shift;
	my $from = _INSTANCE(shift, 'Module::Math::Depends')
		or Carp::croak("Did not provide a Module::Math::Depends object");
	foreach my $name ( sort keys %$from ) {
		if ( $self->{$name} ) {
			if ( $from->{$name} > $self->{$name} ) {
				$self->{$name} = $from->{$name};
			}
		} else {
			$self->{$name} = $from->{$name};
		}
	}
	return 1;
}

=pod

=head2 as_string

  print $depends->as_string;

Converts the dependency set to a simple printable string.

=cut

sub as_string {
	my $self = shift;
	join '', map { "$_: $self->{$_}\n" } sort keys %$self;
}

1;

=pod

=head1 SUPPORT

This module is stored in an Open Repository at the following address.

L<http://svn.ali.as/cpan/trunk/Module-Math-Depends>

Write access to the repository is made available automatically to any
published CPAN author, and to most other volunteers on request.

If you are able to submit your bug report in the form of new (failing)
unit tests, or can apply your fix directly instead of submitting a patch,
you are B<strongly> encouraged to do so as the author currently maintains
over 100 modules and it can take some time to deal with non-Critcal bug
reports or patches.

This will guarentee that your issue will be addressed in the next
release of the module.

If you cannot provide a direct test or fix, or don't have time to do so,
then regular bug reports are still accepted and appreciated via the CPAN
bug tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Math-Depends>

For other issues, for commercial enhancement or support, or to have your
write access enabled for the repository, contact the author at the email
address above.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

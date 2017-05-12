package Test::DatabaseRow::Result;

use strict;
use warnings;

our $VERSION = "2.01";

use Carp qw(croak);

## constructor #########################################################

# emulate moose somewhat by calling a _coerce_and_verify_XXX method
# if one exists
sub new {
  my $class = shift;
  my $self = bless {}, $class;
  while (@_) {
    my $key = shift;
    my $value = shift;
    my $method = $self->can("_coerce_and_verify_$key");
    $self->{ $key } = $method ? $method->($self,$value) : $value;
  }
  return $self;
}

## accessors ############################################################

# has is_error => ( is => "ro", isa => "Bool", default => 0,
#                   predicate => 'has_error' )
sub is_error {
	my $self = shift;
	$self->{is_error} ||= 0;
	return $self->{is_error};
}
sub has_is_error { my $self = shift; return exists $self->{is_error} }

# has diag => ( is => "rw", isa => "ArrayRef",  default => sub {[]},
#               predicate => "has_diag",
#               traits => ['Array'], handles => { add_diag => 'push' })
sub diag {
	my $self = shift;
	$self->{diag} ||= [];
	return $self->{diag};
}
sub has_diag { my $self = shift; return exists $self->{diag} }
sub _coerce_and_verify_diag {
	my $self = shift;
	my $diag = shift;
	croak "Invalid argument to diag" unless ref($diag) eq "ARRAY";
	return $diag;
}
sub add_diag {
	my $self = shift;
	push @{ $self->diag }, @_;
	return;
}

## methods #############################################################

sub pass_to_test_builder {
	my $self = shift;
	my $description = shift;

  # get the test builder singleton
  my $tester = Test::Builder->new();

 	my $result = $tester->ok($self->is_success, $description);
 	$tester->diag($_) foreach @{ $self->diag };
 	return $result;
}

sub is_success {
	my $self = shift;
	return !$self->is_error;
}

1;

__END__


=head1 NAME

Test::DatabaseRow::Result - represent the result of some db testing

=head1 SYNOPSIS

  use Test::More tests => 1;
  use Test::DatabaseRow::Result;

	# create a test results
  my $result_object = Test::DatabaseRow::Result->new(
  	is_error => 1,
  	diag => [ "The WHAM overheaded!" ]
	);

  # have those results render to Test::Builder
  $result_object->pass_to_test_builder("fire main gun");

=head1 DESCRIPTION

This module is used by Test::DatabaseRow::Object to represent
the result of a test.

=head2 Accessors

These are the read only accessors of the object.  They may be
(optionally) set at object creation time by passing their name
and value to the constructor.

Each accessor may be queried by prefixing its name with the
C<has_> to determine

=over

=item is_error

Boolean representing if this is an error or not.

=item diag

An arrayref containing diagnostic error strings that can
help explain any error.

=back

=head2 Methods

=over

=item new(...)

Simple constructor.  Passing arguments to the constructor sets
the values of the accessors.

=item add_diag( @diagnostics )

Adds extra diagnostics to the C<diag> array.

=item pass_to_test_builder( $description )

Causes this test to render itself out using C<Test::Builder>

=item is_success

Returns true if and only if C<is_error> is false.

=back

=head1 BUGS

Bugs (and requests for new features) can be reported though the
CPAN RT system:
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-DatabaseRow>

Alternatively, you can simply fork this project on github and
send me pull requests.  Please see <http://github.com/2shortplanks/Test-DatabaseRow>

=head1 AUTHOR

Written by Mark Fowler B<mark@twoshortplanks.com>

Copyright Mark Fowler 2011.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::DatabaseRow::Object>, L<Test::DatabaseRow>, L<Test::Builder>, L<DBI>

=cut
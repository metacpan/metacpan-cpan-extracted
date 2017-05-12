#!/usr/bin/perl
package MooseX::Role::Matcher;
our $VERSION = '0.05';

use MooseX::Role::Parameterized;
use List::Util qw/first/;
use List::MoreUtils qw/any all/;

=head1 NAME

MooseX::Role::Matcher - generic object matching based on attributes and methods

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  package Person;
  use Moose;
  with 'MooseX::Role::Matcher' => { default_match => 'name' };

  has name  => (is => 'ro', isa => 'Str');
  has age   => (is => 'ro', isa => 'Num');
  has phone => (is => 'ro', isa => 'Str');

  package main;
  my @people = (
      Person->new(name => 'James', age => 22, phone => '555-1914'),
      Person->new(name => 'Jesse', age => 22, phone => '555-6287'),
      Person->new(name => 'Eric',  age => 21, phone => '555-7634'),
  );

  # is James 22?
  $people[0]->match(age => 22);

  # which people are not 22?
  my @not_twenty_two = Person->grep_matches([@people], '!age' => 22);

  # do any of the 22-year-olds have a phone number ending in 4?
  Person->any_match([@people], age => 22, phone => qr/4$/);

  # does everyone's name start with either J or E?
  Person->all_match([@people], name => [qr/^J/, qr/^E/]);

  # find the first person whose name is 4 characters long (using the
  # default_match of name)
  my $four = Person->first_match([@people], sub { length == 4 });

=head1 DESCRIPTION

This role adds flexible matching and searching capabilities to your Moose
class. It provides a match method, which tests attributes and methods of your
object against strings, regexes, or coderefs, and also provides several class
methods for using match on lists of objects.

=head1 PARAMETERS

MooseX::Role::Matcher is a parameterized role (see
L<MooseX::Role::Parameterized>). The parameters it takes are:

=over

=item default_match

Which attribute/method to test against by default, if none are specified
explicitly. Setting default_match to 'foo' allows using
C<< $obj->match('bar') >> rather than C<< $obj->match(foo => 'bar') >>.

=item allow_missing_methods

If set to true, matching against a method that doesn't exist is treated as though matching against undef. Otherwise, the match call dies.

=back

=cut

parameter default_match => (
    isa => 'Str',
);

parameter allow_missing_methods => (
    isa => 'Bool',
);

role {
my $p = shift;
my $default = $p->default_match;
my $allow_missing_methods = $p->allow_missing_methods;

method _apply_to_matches => sub {
    my $class = shift;
    my $on_match = shift;
    my @list = @{ shift() };
    my @matchers = @_;
    $on_match->(sub { $_->match(@matchers) }, @list);
};

=head1 METHODS

=head2 first_match

  my $four = Person->first_match([@people], sub { length == 4 });

Class method which takes an arrayref of objects in the class that consumed this
role, and calls C<match> on each object in the arrayref, passing it the
remaining arguments, and returns the first object for which match returns true.

=cut

method first_match => sub {
    my $class = shift;
    $class->_apply_to_matches(\&first, @_);
};

=head2 grep_matches

  my @not_twenty_two = Person->grep_matches([@people], '!age' => 22);

Class method which takes an arrayref of objects in the class that consumed this
role, and calls C<match> on each object in the arrayref, passing it the
remaining arguments, and returns the each object for which match returns true.

=cut

method grep_matches => sub {
    my $class = shift;
    my $grep = sub { my $code = shift; grep { $code->() } @_ };
    $class->_apply_to_matches($grep, @_);
};

=head2 any_match

  Person->any_match([@people], age => 22, number => qr/4$/);

Class method which takes an arrayref of objects in the class that consumed this
role, and calls C<match> on each object in the arrayref, passing it the
remaining arguments, and returns true if any C<match> calls return true,
otherwise returns false.

=cut

method any_match => sub {
    my $class = shift;
    $class->_apply_to_matches(\&any, @_);
};

=head2 all_match

  Person->all_match([@people], name => [qr/^J/, qr/^E/]);

Class method which takes an arrayref of objects in the class that consumed this
role, and calls C<match> on each object in the arrayref, passing it the
remaining arguments, and returns false if any C<match> calls return false,
otherwise returns true.

=cut

method all_match => sub {
    my $class = shift;
    $class->_apply_to_matches(\&all, @_);
};

method _match => sub {
    my $self = shift;
    my $value = shift;
    my $seek = shift;

    # first check seek types that could match undef
    if (!defined $seek) {
        return !defined $value;
    }
    elsif (ref($seek) eq 'CODE') {
        local $_ = $value;
        return $seek->();
    }
    elsif (ref($seek) eq 'ARRAY') {
        for (@$seek) {
            return 1 if $self->_match($value => $_);
        }
        return 0;
    }
    # then bail out if we still have an undef value
    elsif (!defined $value) {
        return 0;
    }
    # and now check seek types that would error with an undef value
    elsif (ref($seek) eq 'Regexp') {
        return $value =~ $seek;
    }
    elsif (ref($seek) eq 'HASH') {
        return 0 unless blessed($value) &&
                        $value->does('MooseX::Role::Matcher');
        return $value->match(%$seek);
    }
    return $value eq $seek;
};

=head2 match

  $person->match(age => 22);

This method provides the majority of the functionality of this role. It accepts
a hash of arguments, with keys being the methods (usually attributes) of the
object to be tested, and values being things to test against them. Possible
types of values are:

=over

=item SCALAR

Returns true if the result of the method is equal to (C<eq>) the value of the
scalar, otherwise returns false.

=item REGEXP

Returns true if the result of the method matches the regexp, otherwise returns
false.

=item CODEREF

Calls the coderef with C<$_> set to the result of the method, returning true if
the coderef returns true, and false otherwise.

=item UNDEF

Returns true if the method returns undef, or if the object doesn't have a
method by this name, otherwise returns false.

=item ARRAYREF

Matches the result of the method against each element in the arrayref as
described above, returning true if any of the submatches return true, and false
otherwise.

=item HASHREF

If the method does not return an object which does MooseX::Role::Matcher,
returns false. Otherwise, returns the result of calling C<match> on the
returned object, with the contents of the hashref as arguments.

=back

Method names can also be given with a leading '!', which inverts that test. The first key can be omitted from the argument list if it is the method name passed to the default_match parameter when composing this role.

=cut

method match => sub {
    my $self = shift;
    unshift @_, $default if @_ % 2 == 1;
    my %args = @_;

    # All the conditions must be true for true to be returned. Return
    # immediately if a false condition is found.
    for my $matcher (keys %args) {
        my ($invert, $name) = $matcher =~ /^(!)?(.*)$/;
        confess blessed($self) . " has no method named $name"
            unless $self->can($name) || $allow_missing_methods;
        my $value = $self->can($name) ? $self->$name : undef;
        my $seek = $args{$matcher};

        my $matched = $self->_match($value => $seek) ? 1 : 0;

        if ($invert) {
            return 0 if $matched;
        }
        else {
            return 0 unless $matched;
        }
    }

    return 1;
};

};

no MooseX::Role::Parameterized;

=head1 AUTHOR

  Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008-2009 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=head1 TODO

Better error handling/reporting

=head1 SEE ALSO

L<Moose>

L<MooseX::Role::Parameterized>

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-moosex-role-matcher at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Role-Matcher>.

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc MooseX::Role::Matcher

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Role-Matcher>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Role-Matcher>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Role-Matcher>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Role-Matcher>

=back

=cut

1;
use 5.14.0;
package Router::Dumb::Route;
{
  $Router::Dumb::Route::VERSION = '0.005';
}
use Moose;
# ABSTRACT: just one dumb route for use in a big dumb router

use Router::Dumb::Match;

use namespace::autoclean;



has target => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);


has parts => (
  isa => 'ArrayRef[Str]',
  required => 1,
  traits   => [ 'Array' ],
  handles  => {
    parts      => 'elements',
    part_count => 'count',
    get_part   => 'get',
  },
);


sub path {
  my ($self) = @_;
  my $path = join q{/}, $self->parts;
  return $path // '';
}


sub normalized_path {
  my ($self) = @_;

  return '' unless my @parts = $self->parts;

  my $i = 1;
  return join q{/}, map { /^:/ ? (':' . $i++) : $_ } @parts;
}


has is_slurpy => (
  is   => 'ro',
  isa  => 'Bool',
  lazy => 1,
  init_arg => undef,
  default  => sub { $_[0]->part_count && $_[0]->get_part(-1) eq '*' },
);


has has_params => (
  is   => 'ro',
  isa  => 'Bool',
  lazy => 1,
  init_arg => undef,
  default  => sub { !! (grep { /^:/ } $_[0]->parts) },
);


has constraints => (
  isa => 'HashRef',
  default => sub {  {}  },
  traits  => [ 'Hash' ],
  handles => {
    constraint_names => 'keys',
    constraint_for   => 'get',
  },
);

sub BUILD {
  my ($self) = @_;

  confess "multiple asterisk parts in route"
    if (grep { $_ eq '*' } $self->parts) > 1;

  my %seen;
  $seen{$_}++ for grep { $_ =~ /^:/ } $self->parts;
  my @repeated = grep { $seen{$_} > 1 } keys %seen;
  confess "some path match names were repeated: @repeated" if @repeated;

  my @bad_constraints;
  for my $key ($self->constraint_names) {
    push @bad_constraints, $key unless $seen{ ":$key" };
  }

  if (@bad_constraints) {
    confess "constraints were given for unknown names: @bad_constraints";
  }
}

sub _match {
  my ($self, $matches) = @_;
  $matches //= {};

  return Router::Dumb::Match->new({
    route   => $self,
    matches => $matches,
  });
}


sub check {
  my ($self, $str) = @_;

  return $self->_match if $str eq join(q{/}, $self->parts);

  my %matches;

  my @in_parts = split m{/}, $str;
  my @my_parts = $self->parts;

  PART: for my $i (keys @my_parts) {
    my $my_part = $my_parts[ $i ];

    if ($my_part ne '*' and $my_part !~ /^:/) {
      return unless $my_part eq $in_parts[$i];
      next PART;
    }

    if ($my_parts[$i] eq '*') {
      $matches{REST} = join q{/}, @in_parts[ $i .. $#in_parts ];
      return $self->_match(\%matches);
    }

    confess 'unreachable condition' unless $my_parts[$i] =~ /^:(.+)/;

    my $name  = $1;
    my $value = $in_parts[ $i ];
    if (my $constraint = $self->constraint_for($name)) {
      return unless $constraint->check($value);
    }
    $matches{ $name } = $value;
  }

  return $self->_match(\%matches);
}

1;

__END__

=pod

=head1 NAME

Router::Dumb::Route - just one dumb route for use in a big dumb router

=head1 VERSION

version 0.005

=head1 OVERVIEW

Router::Dumb::Route objects represent paths that a L<Router::Dumb> object can
route to.  They are usually created by calling the
C<L<add_route|Router::Dumb/add_route>> method on a router.

=head1 ATTRIBUTES

=head2 target

The route's target is a string that can be used, for example, to give a file
path or URL for the resource to which the user should be directed.  Its meaning
is left up to Router::Dumb's user.

=head2 parts

The C<parts> attribute is an arrayref of strings that make up the route.

=head2 constraints

The C<constraints> attribute holds a hashref of L<Moose type
constraints|Moose::Meta::TypeConstraint> objects, up to one for each
placeholder.

=head1 METHODS

=head2 parts

This method returns a list of the contents of the C<parts> attribute.

=head2 part_count

=head2 get_part

  my $part = $route->get_part( $n );

This returns the string located at position C<$n> in the parts array.

=head2 path

This returns the C</>-joined list of path parts, or the empty string if
C<parts> is empty.

=head2 normalized_path

This method behaves like C<path>, but placeholder parts are replaced with
numbers so that, for example, instead of returning C<foo/:bar/baz/:quux> we
would return C<foo/:1/baz/:2>.  This normalization is used to prevent route
collision.

=head2 is_slurpy

This method returns true if the path ends in the slurpy C<*>.

=head2 has_params

This method returns true if any of the route's path parts is a placeholder
(i.e., starts with a colon).

=head2 constraint_names

This method returns a list of all the placeholders for which a constraint is
registered.

=head2 constraint_for

  my $tc = $route->constraint_for( $placeholder_name );

=head2 check

  my $match_or_undef = $route->check( $str );

This is the method used by the router to see if each route will accept the
string.  If it matches, it returns a L<match object|Router::Dumb::Match>.
Otherwise, it returns false.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

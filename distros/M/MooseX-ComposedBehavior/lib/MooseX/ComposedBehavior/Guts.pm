package MooseX::ComposedBehavior::Guts 0.005;
use MooseX::Role::Parameterized 0.21;
# ABSTRACT: the gooey, meaty bits that help MooseX::ComposedBehavior work

#pod =head1 OVERVIEW
#pod
#pod MooseX::ComposedBehavior::Guts contains a bunch of code that is used by
#pod L<MooseX::ComposedBehavior> to get its job done.  It is basically a hack, and
#pod relying on any part of its interface would be a I<terrible> idea.
#pod
#pod Reading the source, on the other hand, might be useful in understanding what
#pod the heck is going on, especially if you encounter weird problem.
#pod
#pod =cut

use Moose::Util::TypeConstraints;

parameter stub_method_name => (
  isa => 'Str',
  required => 1,
);

parameter method_name => (
  isa => 'Str',
  required => 1,
);

subtype 'MooseX::ComposedBehavior::Stub::_MethodList',
  as 'ArrayRef[Str|CodeRef]';

coerce 'MooseX::ComposedBehavior::Stub::_MethodList',
  from 'CodeRef', via { [$_] },
  from 'Str',     via { [$_] };

parameter also_compose => (
  isa    => 'MooseX::ComposedBehavior::Stub::_MethodList',
  coerce => 1,
);

parameter compositor => (
  isa => 'CodeRef',
  required => 1,
);

parameter context => (
  isa       => enum([ qw(list scalar) ]),
  predicate => 'forces_context',
);

parameter method_order => (
  isa     => enum([ qw(standard reverse) ]),
  default => 'standard',
);

role {
  my ($p) = @_;

  my $wantarray = $p->forces_context ? ($p->context eq 'list' ? 1 : 0) : undef;

  my $stub_name = $p->stub_method_name;
  method $stub_name => sub { };

  my $method_name  = $p->method_name;
  my $compositor   = $p->compositor;
  my $also_compose = $p->also_compose;
  my $reverse      = $p->method_order eq 'reverse';

  method $method_name => sub {
    my $self    = shift;

    my $results = [];

    my $wantarray = defined $wantarray ? $wantarray : wantarray;

    my @methods = Class::MOP::class_of($self)
                ->find_all_methods_by_name($stub_name);

    @methods = reverse @methods if $reverse;

    foreach my $method (@methods) {
      my @array;
      $wantarray ? (@array = $method->{code}->execute($self, \@_, $results))
                 : (scalar $method->{code}->execute($self, \@_, $results));
    }

    if (defined $also_compose) {
      for my $also_method (@$also_compose) {
        push @$results, ($wantarray
          ? [ $self->$also_method(@_) ] : scalar $self->$also_method(@_));
      }
    }

    return $compositor->($self, \@$results);
  }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::ComposedBehavior::Guts - the gooey, meaty bits that help MooseX::ComposedBehavior work

=head1 VERSION

version 0.005

=head1 OVERVIEW

MooseX::ComposedBehavior::Guts contains a bunch of code that is used by
L<MooseX::ComposedBehavior> to get its job done.  It is basically a hack, and
relying on any part of its interface would be a I<terrible> idea.

Reading the source, on the other hand, might be useful in understanding what
the heck is going on, especially if you encounter weird problem.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

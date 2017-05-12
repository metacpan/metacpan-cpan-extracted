package MouseX::Traits;
use Mouse::Role;

our $VERSION   = '0.1102';

has '_trait_namespace' => (
    init_arg => undef,
    isa      => 'Str',
    is       => 'bare',
);

my $transform_trait = sub {
    my ($class, $name) = @_;
    return $1 if $name =~ /^[+](.+)$/;

    my $namespace = $class->meta->find_attribute_by_name('_trait_namespace');
    my $base;
    if($namespace->has_default){
        $base = $namespace->default;
        if(ref $base eq 'CODE'){
            $base = $base->();
        }
    }

    return $name unless defined $base;
    return join '::', $base, $name;
};


my $anon_serial = 0;

sub with_traits {
    my ($class, @traits) = @_;

    $class->does(__PACKAGE__)
        or Carp::confess("We can't interact with traits for a class ($class) "
                       . "that does not do MouseX::Traits");

    my $meta = $class->meta;
    if (@traits) {
        # resolve traits
        @traits = map {
            my $orig = $_;
            if(!ref $orig){
                my $transformed = $transform_trait->($class, $orig);
                Mouse::Util::load_class($transformed);
            }
            else {
                $orig;
            }
        } @traits;

        $meta = $meta->create(
            'MouseX::Traits::__ANON__::' . ++$anon_serial,
            superclasses => [ $class ],
            roles        => \@traits,
            cache        => 1,
        );
    }

    return $meta->name;
}

sub new_with_traits {
    my $class = shift;

    my $args   = $class->BUILDARGS(@_);
    my $traits = delete $args->{traits} || [];

    my $new_class = $class->with_traits(ref $traits ? @$traits : $traits );
    return $new_class->meta->new_object($args);
}

no Mouse::Role;
1;

__END__

=head1 NAME

MouseX::Traits - automatically apply roles at object creation time

=head1 SYNOPSIS

Given some roles:

  package Role;
  use Mouse::Role;
  has foo => ( is => 'ro', isa => 'Int' required => 1 );

And a class:

  package Class;
  use Mouse;
  with 'MouseX::Traits';

Apply the roles to the class at C<new> time:

  my $class = Class->with_traits('Role')->new( foo => 42 );

Then use your customized class:

  $class->isa('Class'); # true
  $class->does('Role'); # true
  $class->foo; # 42

=head1 DESCRIPTION

Often you want to create components that can be added to a class
arbitrarily.  This module makes it easy for the end user to use these
components.  Instead of requiring the user to create a named class
with the desired roles applied, or apply roles to the instance
one-by-one, he can just create a new class from yours with
C<with_traits>, and then instantiate that.

There is also C<new_with_traits>, which exists for compatibility
reasons.  It accepts a C<traits> parameter, creates a new class with
those traits, and then insantiates it.

   Class->new_with_traits( traits => [qw/Foo Bar/], foo => 42, bar => 1 )

returns exactly the same object as

   Class->with_traits(qw/Foo Bar/)->new( foo => 42, bar => 1 )

would.  But you can also store the result of C<with_traits>, and call
other methods:

   my $c = Class->with_traits(qw/Foo Bar/);
   $c->new( foo => 42 );
   $c->whatever( foo => 1234 );

And so on.

=head1 METHODS

=over 4

=item B<< $class->with_traits( @traits ) >>

Return a new class with the traits applied.  Use like:

=item B<< $class->new_with_traits(%args, traits => \@traits) >>

C<new_with_traits> can also take a hashref, e.g.:

  my $instance = $class->new_with_traits({ traits => \@traits, foo => 'bar' });

=back

=head1 ATTRIBUTES YOUR CLASS GETS

This role will add the following attributes to the consuming class.

=head2 _trait_namespace

You can override the value of this attribute with C<default> to
automatically prepend a namespace to the supplied traits.  (This can
be overridden by prefixing the trait name with C<+>.)

Example:

  package Another::Trait;
  use Mouse::Role;
  has 'bar' => (
      is       => 'ro',
      isa      => 'Str',
      required => 1,
  );

  package Another::Class;
  use Mouse;
  with 'MouseX::Traits';
  has '+_trait_namespace' => ( default => 'Another' );

  my $instance = Another::Class->new_with_traits(
      traits => ['Trait'], # "Another::Trait", not "Trait"
      bar    => 'bar',
  );
  $instance->does('Trait')          # false
  $instance->does('Another::Trait') # true

  my $instance2 = Another::Class->new_with_traits(
      traits => ['+Trait'], # "Trait", not "Another::Trait"
  );
  $instance2->does('Trait')          # true
  $instance2->does('Another::Trait') # false

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 ORIGINAL AUTHORS and CONTRIBUTORS

The MouseX::Traits is originated from MooseX::Traits, which is
written and maintained by:

Jonathan Rockway C<< <jrockway@cpan.org> >>

Stevan Little C<< <stevan.little@iinteractive.com> >>

Tomas Doran C<< <bobtfish@bobtfish.net> >>

Matt S. Trout C<< <mst@shadowcatsystems.co.uk> >>

Jesse Luehrs C<< <doy at tozt dot net> >>

Shawn Moore C<< <sartak@bestpractical.com> >>

Florian Ragwitz C<< <rafl@debian.org> >>

Chris Prather C<< <chris@prather.org> >>

Yuval Kogman C<< <nothingmuch@woobling.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


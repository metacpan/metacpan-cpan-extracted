package MooX::Aliases;
use strictures 1;

our $VERSION = '0.001006';
$VERSION = eval $VERSION;

use Carp;
use Class::Method::Modifiers qw(install_modifier);

sub import {
  my ($class) = @_;
  my $target = caller;

  my $around = do { no strict 'refs'; \&{"${target}::around"} }
    or croak "$target is not a Moo class or role";

  my $make_alias = sub {
    my ($from, $to) = @_;
    if (!$target->can($to)) {
      croak "Cannot find method $to to alias";
    }

    eval qq{
      sub ${target}::${from} {
        goto &{\$_[0]->can("$to")};
      };
      1;
    } or die "$@";
  };

  {
    no strict 'refs';
    *{"${target}::alias"} = $make_alias;
  }

  my $installed_buildargs;
  my %init_args;
  install_modifier $target, 'around', 'has', sub {
    my $orig = shift;
    my ($attr, %opts) = @_;

    my $aliases = delete $opts{alias};
    $aliases = [ $aliases ]
      if $aliases && !ref $aliases;

    return $orig->($attr, %opts)
      unless $aliases && @$aliases;

    my $attr_name
      = !ref $attr     ? $attr
      : @{$attr} == 1  ? $attr->[0]
      : croak "Cannot make alias to list of attributes";

    $attr_name =~ s/^\+//;

    my $name = defined $opts{init_arg} ? $opts{init_arg} : $attr_name;
    my @names = @$aliases;
    if (!exists $opts{init_arg} || defined $opts{init_arg}) {
      unshift @names, $name;
    }
    $init_args{$name} = \@names;

    my $out = $orig->($attr, %opts);

    for my $alias (@$aliases) {
      $make_alias->($alias => $attr_name);
    }

    if (!$installed_buildargs) {
      $installed_buildargs = 1;
      $around->('BUILDARGS', sub {
        my $orig = shift;
        my $self = shift;
        my $args = $self->$orig(@_);
        for my $attr (keys %init_args) {
          my @init = grep { exists $args->{$_} } (@{$init_args{$attr}});
          if (@init > 1) {
            croak "Conflicting init_args: (" . join(', ', @init) . ")";
          }
          elsif (@init == 1) {
            $args->{$attr} = delete $args->{$init[0]};
          }
        }
        return $args;
      });
    }

    return $out;
  };
}

1;

__END__

=head1 NAME

MooX::Aliases - easy aliasing of methods and attributes in Moo

=head1 SYNOPSIS

  package MyClass;
  use Moo;
  use MooX::Aliases;

  has this => (
      is    => 'rw',
      alias => 'that',
  );

  sub foo { my $self = shift; print $self->that }
  alias bar => 'foo';

  my $o = MyApp->new();
  $o->this('Hello World');
  $o->bar; # prints 'Hello World' 

or

  package MyRole;
  use Moo::Role;
  use MooX::Aliases;

  has this => (
      is    => 'rw',
      alias => 'that',
  );

  sub foo { my $self = shift; print $self->that }
  alias bar => 'foo';

=head1 DESCRIPTION

The MooX::Aliases module will allow you to quickly alias methods
in Moo. It provides an alias parameter for has() to generate aliased
accessors as well as the standard ones. Attributes can also be
initialized in the constructor via their aliased names.

You can create more than one alias at once by passing a listref:

  has ip_addr => (
    alias => [ qw(ipAddr ip) ],
  );

=head1 FUNCTIONS

=over 4

=item alias $alias, $method

Creates $alias as a method that is aliased to $method.

=back

=head1 CAVEATS

This module uses the C<BUILDARGS> to map the attributes.  If a class uses a
custom C<BUILDARGS>, this module may not behave properly.

=head1 SEE ALSO

=over 4

=item L<MooseX::Aliases>

=back

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head2 CONTRIBUTORS

=over 8

=item * Chris Prather <chris@prather.org>

=item * Jesse Luehrs <doy@tozt.net>

=item * Justin Hunter <justin.d.hunter@gmail.com>

=item * Karen Etheridge <ether@cpan.org>

=item * Yuval Kogman <nothingmuch@woobling.org>

=item * Daniel Gempesaw <gempesaw@gmail.com>

=item * Denis Ibaev <dionys@gmail.com>

=back

=head1 COPYRIGHT

Copyright (c) 2013 the MooX::Alises L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut

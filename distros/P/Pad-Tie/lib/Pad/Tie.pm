use strict;
use warnings;

package Pad::Tie;

use Pad::Tie::LP;
use Data::OptList;
use Module::Pluggable (
  require => 1,
  except => qr/^Pad::Tie::Plugin::Base::/,
);
use Carp ();

our $VERSION = '0.006';
my %METHOD;

sub new {
  my $class = shift;
  my ($invocant, $methods) = @_; 
  $methods = Data::OptList::mkopt($methods);
  my $self = bless {
    invocant => $invocant,
    methods  => $methods,
    persist  => Pad::Tie::LP->new,
    pre_call => [],
  } => $class;
  $self->build_context;
  #tie %{ $self->{context} }, 'Pad::Tie::Context', $self;
  $self->{persist}->set_context(_ => $self->{context});
  return $self;
}

sub build_methods {
  my $class = ref($_[0]) || $_[0];
  for my $plugin ($class->plugins) {
    for my $provided ($plugin->provides) {
      #warn "$plugin provides $provided\n";
      $METHOD{$provided} = $plugin;
    }
  }
}

sub build_context {
  my $self = shift;
  my $methods = shift || $self->{methods};
  $self->{context} ||= {};
  $self->build_methods unless %METHOD;
  for (@$methods) {
    my ($method_personality, $plugin_arg) = @$_;
    Carp::confess "unhandled method personality: $method_personality"
      unless $METHOD{$method_personality};
    my $plugin = $METHOD{$method_personality};
    my $rv = $plugin->$method_personality(
      $self->{context},
      $self->{invocant}, $plugin_arg,
    ) || {};
    # XXX I hate this but I can't think of a better way to do it offhand.
    # if you aren't me, don't use this; talk to me about it instead. -- hdp,
    # 2007-04-24
    if ($rv->{pre_call}) {
      push @{ $self->{pre_call} }, @{ $rv->{pre_call} };
    }
  }
}

sub clone {
  my ($self, $invocant) = @_;
  # XXX validate $invocant?
  # XXX does 'persist' need to be duplicated also?
  # I don't think it has any permanent state that is interesting
  return bless {
    %$self,
    invocant => $invocant,
  } => ref($self),
}

sub call {
  my ($self, $code, @args) = @_;
  $_->($self, $code, \@args) for @{ $self->{pre_call} };
  return $self->{persist}->call($code, @args);
}

sub wrap {
  my ($self, $code) = @_;
  return sub { $self->call($code, @_) };
}

1;

__END__

=head1 NAME

Pad::Tie - tie an object to lexical contexts

=head1 VERSION

 Version 0.006

=head1 SYNOPSIS

  use Pad::Tie;

  my $obj = MyClass->new(...);
  my $pad_tie = Pad::Tie->new(
    $obj,
    [
      scalar    => [qw(fooble quux)],
      array_ref => [qw(numbers)],
      hash_ref  => [qw(lookup)],
      'self',
    ]
  );

  $pad_tie->call(\&foo);
  my $code = $pad_tie->wrap(\&bar);
  $code->(1, 2, 3);

  sub foo {
    my $fooble;

    print $fooble; # $obj->fooble
  }

  sub bar {
    my $quux = 17; # $obj->quux(17);
    my %lookup;

    for my $key (keys %lookup) {
      # keys %{ $obj->lookup }

      $lookup{$key} ||= 1;       
      # $obj->lookup->{$key} ||= 1
    }

    my @numbers = @_; 
    # $obj->numbers([ 1, 2, 3 ]); @_ is from above
  }

=head1 DESCRIPTION

Pad::Tie lets you use your objects' methods as though they were lexical
variables.

Alternately, it lets you use lexical variables to refer to your bound object
methods.  It's all a matter of perspective.

Creating a Pad::Tie object requires an object (the invocant) and a list of
methods (with their personalities) that will be exposed to called subroutines.

There are a number of different calling conventions for methods in Perl.  In
order to accommodate as many as possible, Pad::Tie lets plugins handle them.
See L<Pad::Tie::Plugin> for details on writing new method personalities.

=head3 scalar

The simplest personality.  Using the variable calls the method with no
arguments.  Assignments to the variable call the method with a single argument,
the new value.

  ... Pad::Tie->new($obj, [ scalar => [ 'foo' ] ]);

  sub double_nonzero_foo {
    my $foo;
    if ($foo) {        # $obj->foo
      $foo = $foo * 2; # $obj->foo($obj->foo * 2)
    }
  }

=head3 array_ref

=head3 hash_ref

Nearly as simple as L<scalar|/scalar>.  Using the variable bound to doesn't
actually generate a method call; instead, it's retrieved once and the reference
is used repeatedly.

  ... Pad::Tie->new($obj, [ array_ref => [ 'foo' ] ]);

  sub add_to_foo {
    my @foo;
    push @foo, @_; # push @{ $obj->foo }, @_
  }

=head3 list

Reading from a array bound to a 'list' method personality calls the method
with no arguments in list context.  Assigning to the array calls the method
once with all of the assigned values.  Reading individual array elements is ok,
but setting individual array elements will croak.

  ... Pad::Tie->new($obj, [ list => [ 'foo' ] ]);

  sub get_or_set_foo {
    my @foo;
    @foo = @_ if @_; # $obj->foo(@_)
    return @foo;     # $obj->foo
  }

Because of the way this personality works, if you call the method directly or
otherwise change its return values, those changes may not be reflected in bound
array values.

In other words, continuing the example above, this is a bad idea:

  sub dont_do_this {
    my @foo;
    @foo = (1, 2, 3);
    $obj->foo(4, 5, 6);
    print "@foo"; # probably prints '1 2 3'
  }

=head3 self

This method personality takes no arguments and makes the invocant available as
C<$self> in any called subroutine.  Note that it will not add C<$self> to the
sub if it's not there; you still need a C<my $self> declaration in the scope of
the sub.

  ... Pad::Tie->new($obj, [ 'self' ]);

  sub who_am_i {
    my $self;
    return $self->name;
  }

=head1 CONFIGURATION

Each Pad::Tie object is configured with a list of methods and personalities:

  Pad::Tie->new($obj, [ $personality => \@methodnames, ... ])

The list of method names is actually just an argument to the plugin.  See
individual plugins and L<Pad::Tie::Plugin> for details.

Note that this is an 'optlist'; see L<Data::OptList>.  The short version is
that if you don't need arguments, such as for the C<self> plugin, you don't
need to pass an explicit C<undef> value.  See L</SYNOPSIS>.

More detail about methods and personalities is given above.  See
L<DESCRIPTION|/DESCRIPTION>.

=head1 METHODS

Most of the time you will only need to use C<new> and C<call>, or perhaps
C<wrap>.  The names for C<call> and C<wrap> are chosen deliberately to match up
with methods from L<Lexical::Persistence|Lexical::Persistence>, which this
module is build using.

=head2 new

  my $pad_tie = Pad::Tie->new($obj, \@methods);

Create a new binding for the given object.  

See L<DESCRIPTION|/DESCRIPTION> and L<CONFIGURATION|/CONFIGURATION>.

=head1 TODO

=over 

=item * subclassing

Work out and test interactions.

=item * method auto-discovery

Provide method personality plugins for various object frameworks to avoid
having to type a bunch.

=item * more method personalities

e.g. L<Rose::Object::MakeMethods::Generic|Rose::Object::MakeMethods::Generic>'s
different kinds of hash/array accessors, a scalar that calls different methods
for FETCH and STORE (C<$url> in examples/mech.pl).

=item * more options

interface for configuring the underlying Lexical::Persistence object

=item * more documentation

examples that aren't filled with 'foo', documentation on plugins

=head1 SEE ALSO

L<Pad::Tie::Plugin>
L<Lexical::Persistence>
L<Devel::LexAlias>
L<PadWalker>
L<Data::OptList>

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-pad-tie at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pad-Tie>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pad::Tie

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Pad-Tie>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Pad-Tie>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pad-Tie>

=item * Search CPAN

L<http://search.cpan.org/dist/Pad-Tie>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Pobox.com, who sponsored the development of this module.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

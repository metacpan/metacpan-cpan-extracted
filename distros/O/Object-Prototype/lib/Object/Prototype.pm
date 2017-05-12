package Object::Prototype;

# $Id: Prototype.pm,v 0.2 2007/04/07 01:57:59 dankogai Exp dankogai $
use 5.008001;
use strict;
use warnings;
use Carp;
use Scalar::Util qw(refaddr);
use Storable ();

our $VERSION = sprintf "%d.%02d", q$Revision: 0.2 $ =~ /(\d+)/g;
our $DEBUG = 0;
my %constructor_of;
my %prototype_of;

sub new($$;$) {
    my $class       = shift;
    my $constructor = shift;
    my $self        = Storable::dclone($constructor);
    my $id          = refaddr $self;
    $constructor_of{$id} = $constructor;
    $prototype_of{$id}   = {};
    bless $self => $class;
    for my $method ( keys %{ $_[0] } ) {
        $self->prototype( $method, $_[0]->{$method} );
    }
    return $self;
}

sub prototype($$;$) {
    my $self   = shift;
    my $id     = refaddr $self;
    my $method = shift;
    $prototype_of{$id}{$method} = shift if @_;
    return $prototype_of{$id}{$method};
}

sub constructor($) {
    my $self   = shift;
    my $id     = refaddr $self;
    return $constructor_of{$id}
}

sub DESTROY {
    my $id = refaddr shift;
    carp "DESTROY: $id" if $DEBUG;
    delete $constructor_of{$id};
    delete $prototype_of{$id};
}

sub AUTOLOAD {
    my $self   = shift;
    my $method = our $AUTOLOAD;
    $method =~ s/.*:://o;
    my $id = refaddr $self;
    warn "$id -> $method" if $DEBUG;
    my $code = $prototype_of{$id}{$method};
    return $self->$code(@_) if $code;
    while ( my $constructor = $constructor_of{$id} ) {
        warn "$constructor -> $method" if $DEBUG;
        $id = refaddr $constructor;
        $code = ref $constructor eq ref $self
          ? $prototype_of{$id}{$method}    # Prototypal
          : $constructor->can($method);    # Classical Perl Obj.
        return $self->$code(@_) if $code;
    }
    confess "unknown method : $method" if !$code;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Object::Prototype - Prototypal Object Model a la JavaScript

=head1 SYNOPSIS

  use Object::Prototype;
  use What::Ever;
  my $classical = What::Ever->new();
  $classical->foo("bar");
  is $classical->foo, "bar";
  my $prototypal = Object::Prototype->new();
  $prototypal->foo # bar, of course;
  $prototypal->prototype( baz => sub { shift->foo . shift->bar });
  $prototypal->baz() # foobar
  $classical->baz()  # croaks

=head1 DESCRIPTION

Object::Prototype implements JavaScript-like prototypal object system.
If you are familiar with JavaScript's object system, you should have
no problem using this module.  If you are not, please read
L<http://www.crockford.com/javascript/>.

There is one advantage over JavaScript, however.  As the example
above, you can start with conventional, classical, perlish object as
the prototype.  To find how it is done, just see the source.

=head2 EXPORT

None.

=head2 METHODS

=over 2

=item new($obj [, \%methods ])

Deeply clones $obj and make it a prototypal object.  You can
optionally add methods by passing a hashref like this;

  { method => sub { ... }, method2 => sub { ... } }

Which is a shorthand for

  my $p = Object::Prototype->new($obj);
  $p->prototype( method  => sub { ... } );
  $p->prototype( method2 => sub { ... } );

=item prototype($methname [ => \&code ]);

Accessor/Mutator of the object.  You can implement the singleton
method that way.

=item constructor()

Returns the constructor object.  Consider this as prototypal SUPER.

  $p->prototype(method => sub{
    my $self   = shift;
    my $retval = $self->constructor->method(@_);
    # do whatever to $retval
    return $retval
  });

=back

=head1 SEE ALSO

L<Class::SingletonMethod>, L<Class::Classless>

L<http://www.crockford.com/javascript/>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

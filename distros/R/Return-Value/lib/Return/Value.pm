use strict;
use warnings;
package Return::Value;
# ABSTRACT: (deprecated) polymorphic return values
# vi:et:sw=4 ts=4
$Return::Value::VERSION = '1.666005';
use Exporter 5.57 'import';
use Carp ();

our @EXPORT  = qw[success failure];

#pod =head1 DO NOT USE THIS LIBRARY
#pod
#pod Return::Value was a bad idea.  I'm sorry that I had it, sorry that I followed
#pod through, and sorry that it got used in other useful libraries.  Fortunately
#pod there are not many things using it.  One of those things is
#pod L<Email::Send|Email::Send> which is also deprecated in favor of
#pod L<Email::Sender|Email::Sender>.
#pod
#pod There's no reason to specify a new module to replace Return::Value.  In
#pod general, routines should return values of uniform type or throw exceptions.
#pod Return::Value tried to be a uniform type for all routines, but has so much
#pod weird behavior that it ends up being confusing and not very Perl-like.
#pod
#pod Objects that are false are just a dreadful idea in almost every circumstance,
#pod especially when the object has useful properties.
#pod
#pod B<Please do not use this library.  You will just regret it later.>
#pod
#pod A release of this library in June 2009 promised that deprecation warnings would
#pod start being issued in June 2010.  It is now December 2012, and the warnings are
#pod now being issued.  They can be disabled through means made clear from the
#pod source.
#pod
#pod =head1 SYNOPSIS
#pod
#pod Used with basic function-call interface:
#pod
#pod   use Return::Value;
#pod   
#pod   sub send_over_network {
#pod       my ($net, $send) = @_:
#pod       if ( $net->transport( $send ) ) {
#pod           return success;
#pod       } else {
#pod           return failure "Was not able to transport info.";
#pod       }
#pod   }
#pod   
#pod   my $result = $net->send_over_network(  "Data" );
#pod   
#pod   # boolean
#pod   unless ( $result ) {
#pod       # string
#pod       print $result;
#pod   }
#pod
#pod Or, build your Return::Value as an object:
#pod   
#pod   sub build_up_return {
#pod       my $return = failure;
#pod       
#pod       if ( ! foo() ) {
#pod           $return->string("Can't foo!");
#pod           return $return;
#pod       }
#pod       
#pod       if ( ! bar() ) {
#pod           $return->string("Can't bar");
#pod           $return->prop(failures => \@bars);
#pod           return $return;
#pod       }
#pod       
#pod       # we're okay if we made it this far.
#pod       $return++;
#pod       return $return; # success!
#pod   }
#pod
#pod =head1 DESCRIPTION
#pod
#pod Polymorphic return values are a horrible idea, but this library was written
#pod based on the notion that they were useful.  Often, we just want to know if
#pod something worked or not.  Other times, we'd like to know what the error text
#pod was.  Still others, we may want to know what the error code was, and what the
#pod error properties were.  We don't want to handle objects or data structures for
#pod every single return value, but we do want to check error conditions in our code
#pod because that's what good programmers do.
#pod
#pod When functions are successful they may return true, or perhaps some useful
#pod data.  In the quest to provide consistent return values, this gets confusing
#pod between complex, informational errors and successful return values.
#pod
#pod This module provides these features with a simplistic API that should get you
#pod what you're looking for in each context a return value is used in.
#pod
#pod =head2 Attributes
#pod
#pod All return values have a set of attributes that package up the information
#pod returned.  All attributes can be accessed or changed via methods of the same
#pod name, unless otherwise noted.  Many can also be accessed via overloaded
#pod operations on the object, as noted below.
#pod
#pod =over 4
#pod
#pod =item type
#pod
#pod A value's type is either "success" or "failure" and (obviously) reflects
#pod whether the value is returning success or failure.
#pod
#pod =item errno
#pod
#pod The errno attribute stores the error number of the return value.  For
#pod success-type results, it is by default undefined.  For other results, it
#pod defaults to 1.
#pod
#pod =item string
#pod
#pod The value's string attribute is a simple message describing the value.
#pod
#pod =item data
#pod
#pod The data attribute stores a reference to a hash or array, and can be used as a
#pod simple way to return extra data.  Data stored in the data attribute can be
#pod accessed by dereferencing the return value itself.  (See below.)
#pod
#pod =item prop
#pod
#pod The most generic attribute of all, prop is a hashref that can be used to pass
#pod an arbitrary number of data structures, just like the data attribute.  Unlike
#pod the data attribute, though, these structures must be retrieved via method calls.
#pod
#pod =back
#pod
#pod =head1 FUNCTIONS
#pod
#pod The functional interface is highly recommended for use within functions
#pod that are using C<Return::Value> for return values.  It's simple and
#pod straightforward, and builds the entire return value in one statement.
#pod
#pod =over 4
#pod
#pod =cut

# This hack probably impacts performance more than I'd like to know, but it's
# needed to have a hashref object that can deref into a different hash.
# _ah($self,$key, [$value) sets or returns the value for the given key on the
# $self blessed-ref

sub _ah {
    my ($self, $key, $value) = @_;
    my $class = ref $self;
    bless $self => "ain't::overloaded";
    $self->{$key} = $value if @_ > 2;
    my $return = $self->{$key};
    bless $self => $class;
    return $return;
}

sub _builder {
    my %args = (type => shift);
    $args{string} = shift if (@_ % 2);
    %args = (%args, @_);

    $args{string} = $args{type} unless defined $args{string};

    $args{errno}  = ($args{type} eq 'success' ? undef : 1)
        unless defined $args{errno};

    __PACKAGE__->new(%args);
}

#pod =item success
#pod
#pod The C<success> function returns a C<Return::Value> with the type "success".
#pod
#pod Additional named parameters may be passed to set the returned object's
#pod attributes.  The first, optional, parameter is the string attribute and does
#pod not need to be named.  All other parameters must be passed by name.
#pod
#pod  # simplest possible case
#pod  return success;
#pod
#pod =cut

sub success { _builder('success', @_) }

#pod =pod
#pod
#pod =item failure
#pod
#pod C<failure> is identical to C<success>, but returns an object with the type
#pod "failure"
#pod
#pod =cut

sub failure { _builder('failure', @_) }

#pod =pod
#pod
#pod =back
#pod
#pod =head1 METHODS
#pod
#pod The object API is useful in code that is catching C<Return::Value> objects.
#pod
#pod =over 4
#pod
#pod =item new
#pod
#pod   my $return = Return::Value->new(
#pod       type   => 'failure',
#pod       string => "YOU FAIL",
#pod       prop   => {
#pod           failed_objects => \@objects,
#pod       },
#pod   );
#pod
#pod Creates a new C<Return::Value> object.  Named parameters can be used to set the
#pod object's attributes.
#pod
#pod =cut

sub new {
    my $class = shift;
    bless { type => 'failure', string => q{}, prop => {}, @_ } => $class;
}

#pod =pod
#pod
#pod =item bool
#pod
#pod   print "it worked" if $result->bool;
#pod
#pod Returns the result in boolean context: true for success, false for failure.
#pod
#pod =item prop
#pod
#pod   printf "%s: %s',
#pod     $result->string, join ' ', @{$result->prop('strings')}
#pod       unless $result->bool;
#pod
#pod Returns the return value's properties. Accepts the name of
#pod a property returned, or returns the properties hash reference
#pod if given no name.
#pod
#pod =item other attribute accessors
#pod
#pod Simple accessors exist for the object's other attributes: C<type>, C<errno>,
#pod C<string>, and C<data>.
#pod
#pod =cut

sub bool { _ah($_[0],'type') eq 'success' ? 1 : 0 }

sub type {
    my ($self, $value) = @_;
    return _ah($self, 'type') unless @_ > 1;
    Carp::croak "invalid result type: $value"
        unless $value eq 'success' or $value eq 'failure';
    return _ah($self, 'type', $value);
};

foreach my $name ( qw[errno string data] ) {
    ## no critic (ProhibitNoStrict)
    no strict 'refs';
    *{$name} = sub {
        my ($self, $value) = @_;
        return _ah($self, $name) unless @_ > 1;
        return _ah($self, $name, $value);
    };
}

sub prop {
    my ($self, $name, $value) = @_;
    return _ah($self, 'prop')          unless $name;
    return _ah($self, 'prop')->{$name} unless @_ > 2;
    return _ah($self, 'prop')->{$name} = $value;
}

#pod =pod
#pod
#pod =back
#pod
#pod =head2 Overloading
#pod
#pod Several operators are overloaded for C<Return::Value> objects. They are
#pod listed here.
#pod
#pod =over 4
#pod
#pod =item Stringification
#pod
#pod   print "$result\n";
#pod
#pod Stringifies to the string attribute.
#pod
#pod =item Boolean
#pod
#pod   print $result unless $result;
#pod
#pod Returns the C<bool> representation.
#pod
#pod =item Numeric
#pod
#pod Also returns the C<bool> value.
#pod
#pod =item Dereference
#pod
#pod Dereferencing the value as a hash or array will return the value of the data
#pod attribute, if it matches that type, or an empty reference otherwise.  You can
#pod check C<< ref $result->data >> to determine what kind of data (if any) was
#pod passed.
#pod
#pod =cut

use overload
    '""'   => sub { shift->string  },
    'bool' => sub { shift->bool },
    '=='   => sub { shift->bool   == shift },
    '!='   => sub { shift->bool   != shift },
    '>'    => sub { shift->bool   >  shift },
    '<'    => sub { shift->bool   <  shift },
    'eq'   => sub { shift->string eq shift },
    'ne'   => sub { shift->string ne shift },
    'gt'   => sub { shift->string gt shift },
    'lt'   => sub { shift->string lt shift },
    '++'   => sub { _ah(shift,'type','success') },
    '--'   => sub { _ah(shift,'type','failure') },
    '${}'  => sub { my $data = _ah($_[0],'data'); $data ? \$data : \undef },
    '%{}'  => sub { ref _ah($_[0],'data') eq 'HASH'  ? _ah($_[0],'data') : {} },
    '@{}'  => sub { ref _ah($_[0],'data') eq 'ARRAY' ? _ah($_[0],'data') : [] },
    fallback => 1;

#pod =pod
#pod
#pod =back
#pod
#pod =cut

"This return value is true.";

__END__

=pod

=encoding UTF-8

=head1 NAME

Return::Value - (deprecated) polymorphic return values

=head1 VERSION

version 1.666005

=head1 SYNOPSIS

Used with basic function-call interface:

  use Return::Value;
  
  sub send_over_network {
      my ($net, $send) = @_:
      if ( $net->transport( $send ) ) {
          return success;
      } else {
          return failure "Was not able to transport info.";
      }
  }
  
  my $result = $net->send_over_network(  "Data" );
  
  # boolean
  unless ( $result ) {
      # string
      print $result;
  }

Or, build your Return::Value as an object:

  sub build_up_return {
      my $return = failure;
      
      if ( ! foo() ) {
          $return->string("Can't foo!");
          return $return;
      }
      
      if ( ! bar() ) {
          $return->string("Can't bar");
          $return->prop(failures => \@bars);
          return $return;
      }
      
      # we're okay if we made it this far.
      $return++;
      return $return; # success!
  }

=head1 DESCRIPTION

Polymorphic return values are a horrible idea, but this library was written
based on the notion that they were useful.  Often, we just want to know if
something worked or not.  Other times, we'd like to know what the error text
was.  Still others, we may want to know what the error code was, and what the
error properties were.  We don't want to handle objects or data structures for
every single return value, but we do want to check error conditions in our code
because that's what good programmers do.

When functions are successful they may return true, or perhaps some useful
data.  In the quest to provide consistent return values, this gets confusing
between complex, informational errors and successful return values.

This module provides these features with a simplistic API that should get you
what you're looking for in each context a return value is used in.

=head2 Attributes

All return values have a set of attributes that package up the information
returned.  All attributes can be accessed or changed via methods of the same
name, unless otherwise noted.  Many can also be accessed via overloaded
operations on the object, as noted below.

=over 4

=item type

A value's type is either "success" or "failure" and (obviously) reflects
whether the value is returning success or failure.

=item errno

The errno attribute stores the error number of the return value.  For
success-type results, it is by default undefined.  For other results, it
defaults to 1.

=item string

The value's string attribute is a simple message describing the value.

=item data

The data attribute stores a reference to a hash or array, and can be used as a
simple way to return extra data.  Data stored in the data attribute can be
accessed by dereferencing the return value itself.  (See below.)

=item prop

The most generic attribute of all, prop is a hashref that can be used to pass
an arbitrary number of data structures, just like the data attribute.  Unlike
the data attribute, though, these structures must be retrieved via method calls.

=back

=head1 DO NOT USE THIS LIBRARY

Return::Value was a bad idea.  I'm sorry that I had it, sorry that I followed
through, and sorry that it got used in other useful libraries.  Fortunately
there are not many things using it.  One of those things is
L<Email::Send|Email::Send> which is also deprecated in favor of
L<Email::Sender|Email::Sender>.

There's no reason to specify a new module to replace Return::Value.  In
general, routines should return values of uniform type or throw exceptions.
Return::Value tried to be a uniform type for all routines, but has so much
weird behavior that it ends up being confusing and not very Perl-like.

Objects that are false are just a dreadful idea in almost every circumstance,
especially when the object has useful properties.

B<Please do not use this library.  You will just regret it later.>

A release of this library in June 2009 promised that deprecation warnings would
start being issued in June 2010.  It is now December 2012, and the warnings are
now being issued.  They can be disabled through means made clear from the
source.

=head1 FUNCTIONS

The functional interface is highly recommended for use within functions
that are using C<Return::Value> for return values.  It's simple and
straightforward, and builds the entire return value in one statement.

=over 4

=item success

The C<success> function returns a C<Return::Value> with the type "success".

Additional named parameters may be passed to set the returned object's
attributes.  The first, optional, parameter is the string attribute and does
not need to be named.  All other parameters must be passed by name.

 # simplest possible case
 return success;

=item failure

C<failure> is identical to C<success>, but returns an object with the type
"failure"

=back

=head1 METHODS

The object API is useful in code that is catching C<Return::Value> objects.

=over 4

=item new

  my $return = Return::Value->new(
      type   => 'failure',
      string => "YOU FAIL",
      prop   => {
          failed_objects => \@objects,
      },
  );

Creates a new C<Return::Value> object.  Named parameters can be used to set the
object's attributes.

=item bool

  print "it worked" if $result->bool;

Returns the result in boolean context: true for success, false for failure.

=item prop

  printf "%s: %s',
    $result->string, join ' ', @{$result->prop('strings')}
      unless $result->bool;

Returns the return value's properties. Accepts the name of
a property returned, or returns the properties hash reference
if given no name.

=item other attribute accessors

Simple accessors exist for the object's other attributes: C<type>, C<errno>,
C<string>, and C<data>.

=back

=head2 Overloading

Several operators are overloaded for C<Return::Value> objects. They are
listed here.

=over 4

=item Stringification

  print "$result\n";

Stringifies to the string attribute.

=item Boolean

  print $result unless $result;

Returns the C<bool> representation.

=item Numeric

Also returns the C<bool> value.

=item Dereference

Dereferencing the value as a hash or array will return the value of the data
attribute, if it matches that type, or an empty reference otherwise.  You can
check C<< ref $result->data >> to determine what kind of data (if any) was
passed.

=back

=head1 AUTHORS

=over 4

=item *

Ricardo SIGNES <rjbs@cpan.org>

=item *

Casey West

=back

=head1 CONTRIBUTORS

=for stopwords David Steinbrunner Karen Etheridge Ricardo SIGNES

=over 4

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Ricardo SIGNES <rjbs@codesimply.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Casey West.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

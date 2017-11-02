# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle-Client.

package Pootle::Exception;

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);

use Exception::Class (
  'Pootle::Exception' => {
    description => 'Pootle exceptions base class',
  },
);

sub newFromDie {
  my ($class, $die) = @_;
  return Pootle::Exception->new(error => "$die");
}

=head2 rethrowDefault

Because there are so many different types of exception classes with different
interfaces, use this to rethrow if you dont know exactly what you are getting.

 @PARAM1 somekind of monster

=cut

sub rethrowDefaults {
  my ($e) = @_;

  die $e unless blessed($e);
  die $e if $e->isa('Mojo::Exception'); #Dying a Mojo::Exception actually rethrows it.
  $e->rethrow if ref($e) eq 'Pootle::Exception'; #If this is THE 'Pootle::Exception', then handle it here
  $e->rethrow if $e->isa('Pootle::Exception');
  $e->rethrow; #Exception classes are expected to implement rethrow like good exceptions should!!
}

=head2 handleDefaults

Handles all the boring exception cases in a default way. Saving you a lot of typing.

=cut

sub handleDefaults {
  my ($e) = @_;

  return $e unless blessed($e);
  return toTextMojo($e) if $e->isa('Mojo::Exception');
  return $e->toText if ref($e) eq 'Pootle::Exception'; #If this is THE 'Pootle::Exception', then handle it here
  return $e->toText if $e->isa('Pootle::Exception'); #If this is a subclass of 'Pootle::Exception', then let it through
  return toTextUnknown($e);
}

=head2 toText

 @RETURNS String, a textual representation of this exception,
                  Full::module::package :> error message, other supplied error keys

=cut

sub toText {
  my ($self) = @_;

  my @sb;
  push(@sb, ref($self).' :> '.$self->error);
# You can override global exception handling behaviour here.
# Maybe throw stack traces or somehow automatically identify
# supplementary exception payloads to show?
#
#  while (my ($k, $v) = each(%$self)) {
#    next if $k eq 'error';
#    push(@sb, "$k => '$v'");
#  }
  return join(', ', @sb);
}

=head2 toTextUnknown
 @STATIC

 @RETURNS String, a textual representation of this exception,
                 Full::module::package :> error message, other supplied error keys

=cut

sub toTextUnknown {
  my ($e) = @_;

  my @sb;
  if (ref($e) eq 'HASH' || blessed($e)) {
    while (my ($k, $v) = each(%$e)) {
      push(@sb, "$k => '$v'");
    }
  }
  elsif (ref($e) eq 'ARRAY') {
    @sb = @$e;
  }
  else {
    push(@sb, $e);
  }
  return join(', ', @sb);
}

=head2 toTextMojo

Returns a text representation of a Mojo::Exception

=cut

sub toTextMojo {
    my ($e) = @_;
    return $e->verbose(1)->to_string;
}

1;

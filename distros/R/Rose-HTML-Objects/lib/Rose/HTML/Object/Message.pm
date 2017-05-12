package Rose::HTML::Object::Message;

use strict;

use Carp;
use Clone::PP;
use Scalar::Util();

use Rose::HTML::Object::Messages qw(CUSTOM_MESSAGE);

use base 'Rose::Object';

our $VERSION = '0.606';

#our $Debug = 0;

use overload
(
  '""'   => sub { shift->text },
  'bool' => sub { 1 },
  '0+'   => sub { 1 },
   fallback => 1,
);

use Rose::Object::MakeMethods::Generic
(
  scalar => 
  [
    'id',
    'variant',
  ],
);

sub as_string { no warnings 'uninitialized'; "$_[0]" }

sub init
{
  my($self) = shift;
  @_ = (text => @_)  if(@_ == 1);
  $self->SUPER::init(@_);
}

sub args
{
  my($self) = shift;

  if(@_)
  {
    my %args;

    if(@_ == 1 && ref $_[0] eq 'ARRAY')
    {
      my $i = 1;
      %args = (map { $i++ => $_ } @{$_[0]});
    }
    elsif(@_ == 1 && ref $_[0] eq 'HASH')
    {
      %args = %{$_[0]};

      my $i = 1;

      foreach my $key (sort keys %args)
      {
        $args{$i} = $args{$key}  unless(exists $args{$i});
        $i++;
      }
    }
    else
    {
      my $i = 1;
      %args = map { $i++ => $_ } @_;
    }

    $self->{'args'} = \%args;

    return wantarray ? %{$self->{'args'}} : $self->{'args'};
  }

  return wantarray ? %{$self->{'args'} || {}} : ($self->{'args'} ||= {});
}

sub parent
{
  my($self) = shift; 
  return Scalar::Util::weaken($self->{'parent'} = shift)  if(@_);
  return $self->{'parent'};
}

sub clone
{
  my($self) = shift;
  my $clone = Clone::PP::clone($self);
  $clone->parent(undef);
  return $clone;
}

sub text
{
  my($self) = shift;

  if(@_)
  {
    if(UNIVERSAL::isa($_[0], __PACKAGE__))
    {
      $self->id($_[0]->id);
      return $self->{'text'} = $_[0]->text;
    }

    $self->id(CUSTOM_MESSAGE);
    return $self->{'text'} = $_[0];
  }

  return $self->{'text'};
}

sub is_custom { no warnings; shift->id == CUSTOM_MESSAGE }

1;

__END__

=head1 NAME

Rose::HTML::Object::Message - Text message object.

=head1 SYNOPSIS

  $msg = Rose::HTML::Object::Message->new('Hello world');
  print $msg->text; # Hello world

=head1 DESCRIPTION

L<Rose::HTML::Object::Message> objects encapsulate a text message with an optional integer L<id|/id>.

This class inherits from, and follows the conventions of, L<Rose::Object>. See the L<Rose::Object> documentation for more information.

=head1 OVERLOADING

Stringification is overloaded to call the L<text|/text> method.  In numeric and boolean contexts, L<Rose::HTML::Object::Message> objects always evaluate to true.

=head1 CONSTRUCTOR

=over 4

=item B<new [ PARAMS | TEXT ]>

Constructs a new L<Rose::HTML::Object::Message> object.  If a single argument is passed, it is taken as the value for the L<text|/text> parameter.  Otherwise, PARAMS name/value pairs are expected.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<id [INT]>

Get or set the message's integer identifier.

=item B<text [ TEXT | OBJECT ]>

Get or set the message's text.  If the message text is set to a TEXT string (rather than a L<Rose::HTML::Object::Message>-derived OBJECT), the L<id|/id> is set to the value of the constant C<Rose::HTML::Object::Message::CUSTOM_MESSAGE>.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

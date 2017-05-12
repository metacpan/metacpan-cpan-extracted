package Rose::HTML::Text;

use strict;

use base 'Rose::HTML::Object';

use Rose::HTML::Util();

our $VERSION = '0.602';

__PACKAGE__->valid_html_attrs([]);

use overload
(
  '""'   => sub { shift->html },
  'bool' => sub { 1 },
  '0+'   => sub { 1 },
   fallback => 1,
);

# XXX: When Class::XSAccessor is installed, the (apparent) combination of
# XXX: overload and Rose::Object::MakeMethods::Generic's method creation
# XXX: for plain scalar attributes causes things to go awry and tests to 
# XXX" fail (e.g., t/text.t)
# use Rose::Object::MakeMethods::Generic
# (
#   { override_existing => 1 },
#   scalar =>
#   [
#     'html',
#   ],
# );

# XXX: Do it the old-fashioned way (see comments above)
sub html
{
  my($self) = shift;
  return $self->{'html'} = shift  if(@_);
  return $self->{'html'};
}

sub html_tag  { shift->html(@_) }
sub xhtml_tag { shift->xhtml(@_) }

sub xhtml { shift->html(@_) }

sub init
{
  my($self) = shift;
  @_ = (text => @_)  if(@_ == 1);
  $self->SUPER::init(@_);
}

sub text
{
  my($self) = shift;
  local $^W = 0; # XXX: Using a sledgehammer here due to possible stringification overloading on $_[0]
  $self->html(defined $_[0] ? Rose::HTML::Util::escape_html(@_) : undef)  if(@_);
  return Rose::HTML::Util::unescape_html($self->html);
}

sub children
{
  my($self) = shift;
  Carp::croak ref($self), " objects cannot have children()"  if(@_ > 1);
  return wantarray ? () : [];
}

sub push_children { Carp::croak ref($_[0]), " objects cannot have children()" }
*unshift_children = \&push_children;

1;

__END__

=head1 NAME

Rose::HTML::Text - Object representation of HTML-escaped text.

=head1 SYNOPSIS

    $text = Rose::HTML::Text->new('I <3 HTML');

    print $text->html;  # I &lt;3 HTML

    # Stringification is overloaded    
    print "$text" # I &lt;3 HTML

    ...

=head1 DESCRIPTION

L<Rose::HTML::Text> is an object representation of and HTML-escaped text string.  Stringification is L<overloaded|overload> to call the L<html|/html> method.

This class inherits from, and follows the conventions of, L<Rose::HTML::Object>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::HTML::Object> documentation for more information.

=head1 HTML ATTRIBUTES

Valid attributes: E<lt>noneE<gt>

=head1 CONSTRUCTOR

=over 4

=item B<new [ PARAMS | TEXT ]>

This behaves like standard L<Rose::HTML::Object> L<constructor|Rose::HTML::Object/new> except that if a lone argument is passed, it is taken as the value of L<text|/text>.

=back

=head1 OBJECT METHODS

=over 4

=item B<html [HTML]>

Get or set the HTML version of the L<text|/text>.

=item B<text [TEXT]>

Get or set the text.

=item B<xhtml [XHTML]>

This is an alias for the L<html|/html> method.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

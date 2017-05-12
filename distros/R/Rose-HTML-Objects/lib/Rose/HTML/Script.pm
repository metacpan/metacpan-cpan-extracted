package Rose::HTML::Script;

use strict;

use base 'Rose::HTML::Object';

our $VERSION = '0.606';

use Rose::Class::MakeMethods::Generic
(
  inheritable_scalar => 'default_support_older_browsers',
);

__PACKAGE__->default_support_older_browsers(1);

__PACKAGE__->add_valid_html_attrs
(
  'charset',  # %Charset;      #IMPLIED  -- char encoding of linked resource
  'type',     # %ContentType;  #REQUIRED -- content type of script language
  'src',      # %URI;          #IMPLIED  -- URI for an external script
  'defer',    # (defer)        #IMPLIED  -- UA may defer execution of script
);

__PACKAGE__->add_required_html_attrs(
{
  type  => 'text/javascript',
});

__PACKAGE__->add_boolean_html_attrs
(
  'defer',
);

sub src  { shift->html_attr('src', @_) }
sub type { shift->html_attr('type', @_) }

sub support_older_browsers
{
  my($self) = shift;

  return $self->{'support_older_browsers'} = $_[0] ? 1 : 0  if(@_);

  unless(defined $self->{'support_older_browsers'})
  {
    return $self->{'support_older_browsers'} = 
      (ref($self))->default_support_older_browsers;
  }

  return $self->{'support_older_browsers'};
}

sub html_element  { 'script' }
sub xhtml_element { 'script' }

sub script
{
  my($self) = shift; 
  $self->children(@_)  if(@_);
  return join('', map { $_->html } $self->children)
}

*contents = \&script;

sub xhtml_contents_escaped
{
  my($self) = shift;

  my $contents = $self->contents;
  return $contents  unless($contents =~ /\S/);

  for($contents) { s/\A\n//; s/\n\Z// }

  if($self->support_older_browsers)
  {
    return "<!--//--><![CDATA[//><!--\n$contents\n//--><!]]>";
  }

  return "\n//<![CDATA[\n$contents\n//]]>\n";
}

sub html_contents_escaped
{
  my($self) = shift;

  my $contents = $self->contents;
  return $contents  unless($contents =~ /\S/);

  for($contents) { s/\A\n//; s/\n\Z// }

  return "\n<!--\n$contents\n// -->\n";
}

sub html_tag
{
  my($self) = shift;

  if(length($self->src || ''))
  {
    no warnings;
    return '<script' . $self->html_attrs_string . '></script>';
  }

  no warnings;
  return '<script' . $self->html_attrs_string . '>' .
         $self->html_contents_escaped .
         '</script>';
}

sub xhtml_tag
{
  my($self) = shift;

  if(length($self->src || ''))
  {
    no warnings;
    return '<script' . $self->xhtml_attrs_string . ' />';
  }

  no warnings;
  return '<script' . $self->xhtml_attrs_string . '>' .
         $self->xhtml_contents_escaped .
         '</script>';
}

1;

__END__

=head1 NAME

Rose::HTML::Script - Object representation of the "script" HTML tag.

=head1 SYNOPSIS

    $script = Rose::HTML::Script->new(src => '/main.js');

    print $script->html;

    $script = 
      Rose::HTML::Script->new(
        script => 'function addThese(a, b) { return a + b }');

    print $script->html;

    ...

=head1 DESCRIPTION

L<Rose::HTML::Script> is an object representation of a "script" HTML tag used to reference or wrap scripts (e.g., JavaScript).

This class inherits from, and follows the conventions of, L<Rose::HTML::Object>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::HTML::Object> documentation for more information.

=head1 HTML ATTRIBUTES

Valid attributes:

    charset
    class
    defer
    dir
    id
    lang
    onclick
    ondblclick
    onkeydown
    onkeypress
    onkeyup
    onmousedown
    onmousemove
    onmouseout
    onmouseover
    onmouseup
    src
    style
    title
    type
    xml:lang

Required attributes (default values in parentheses):

    type (text/javascript)

Boolean attributes:

    defer

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::HTML::Script> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 CLASS METHODS

=over 4

=item B<default_support_older_browsers [BOOL]>

Get or set a boolean value that indicates whether or not the L<XHTML|Rose::HTML::Object/xhtml> produced by objects of this class will, by default, attempt to support older web browsers that have trouble parsing the comments used to wrap script contents.   The default value is true.  See the L<support_older_browsers|/support_older_browsers> object method for some examples.

=back

=head1 OBJECT METHODS

=over 4

=item B<contents [TEXT]>

Get or set the contents of the script tag.

=item B<script [TEXT]>

This is an alias for the L<contents|/contents> method.

=item B<src [URI]>

Get or set the URI of the script file.  If this attribute is set, then the L<contents|/contents> of of the script tag are ignored when it comes time to produce the L<HTML|Rose::HTML::Object/html>.

=item B<support_older_browsers [BOOL]>

Get or set a boolean value that indicates whether or not the L<XHTML|Rose::HTML::Object/xhtml> produced by this object will attempt to support older web browsers that have trouble parsing the comments used to wrap script contents.  If undefined, the value of this attribute is set to the return value of the L<default_support_older_browsers|/default_support_older_browsers> class method.

Examples:

    $script = 
      Rose::HTML::Script->new(script => 'function foo() { return 123; }');

    print $script->xhtml;

This prints the following big mess which helps older browsers while also remaining valid XHTML.

    <script type="text/javascript"><!--//--><![CDATA[//><!--
    function foo() { return 123; }
    //--><!]]></script>

Now the other mode:

    $script->support_older_browsers(0);
    print $script->xhtml;

which prints:

    <script type="text/javascript">
    //<![CDATA[
    function foo() { return 123; }
    //]]>
    </script>

See L<http://hixie.ch/advocacy/xhtml> for more information on this topic.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

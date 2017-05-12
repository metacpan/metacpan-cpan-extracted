package Rose::HTML::Form::Field::Input;

use strict;

use base 'Rose::HTML::Form::Field';

our $VERSION = '0.607';

__PACKAGE__->add_valid_html_attrs
(
  'size',      # CDATA          #IMPLIED  -- specific to each type of field --
  'maxlength', # NUMBER         #IMPLIED  -- max chars for text fields --
  'src',       # %URI;          #IMPLIED  -- for fields with images --
  'alt',       # CDATA          #IMPLIED  -- short description --
  'usemap',    # %URI;          #IMPLIED  -- use client-side image map --
  'ismap',     # (ismap)        #IMPLIED  -- use server-side image map --
  'tabindex',  # NUMBER         #IMPLIED  -- position in tabbing order --
  'accesskey', # %Character;    #IMPLIED  -- accessibility key character --
  'onfocus',   # %Script;       #IMPLIED  -- the element got the focus --
  'onblur',    # %Script;       #IMPLIED  -- the element lost the focus --
  'onselect',  # %Script;       #IMPLIED  -- some text was selected --
  'onchange',  # %Script;       #IMPLIED  -- the element value was changed --
  'accept',    # %ContentTypes; #IMPLIED  -- list of MIME types for file upload --
  'type',      # %InputType;    "text"
  'name',      # CDATA          #IMPLIED
  'value',     # CDATA          #IMPLIED
  'checked',   # (checked)      #IMPLIED
  'disabled',  # (disabled)     #IMPLIED
  'readonly',  # (readonly)     #IMPLIED
  'placeholder',
  'formaction',
  'formenctype',
  'formmethod',
  'formnovalidate',
  'formtarget',
  'min',
  'max',
  'step',
);

__PACKAGE__->add_required_html_attrs(
{
  type => 'text',
});

__PACKAGE__->add_boolean_html_attrs
(
  'disabled',
  'readonly',
  'ismap',
  'checked',
);

sub element       { 'input' }
sub html_element  { 'input' }
sub xhtml_element { 'input' }

sub is_self_closing { 1 }

1;

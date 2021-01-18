package MsOffice::Word::Surgeon::Text;
use feature 'state';
use Moose;
use MooseX::StrictConstructor;
use MsOffice::Word::Surgeon::Utils qw(maybe_preserve_spaces is_at_run_level);
use Carp                           qw(croak);

use namespace::clean -except => 'meta';

has 'xml_before'   => (is => 'ro', isa => 'Str');
has 'literal_text' => (is => 'ro', isa => 'Str', required => 1);

our $VERSION = '1.06';


sub as_xml {
  my $self = shift;

  my $xml = $self->xml_before // '';
  if (my $lit_txt = $self->literal_text) {
    my $space_attr  = maybe_preserve_spaces($lit_txt);
    $xml .= "<w:t$space_attr>$lit_txt</w:t>";
  }
  return $xml;
}



sub merge {
  my ($self, $next_text) = @_;

  !$next_text->xml_before
    or croak "cannot merge -- next text contains xml before the text : "
           . $next_text->xml_before;

  $self->{literal_text} .= $next_text->literal_text;

}


sub replace {
  my ($self, $pattern, $replacement, %args) = @_;

  my $xml = "";
  my $current_text_node;
  my $xml_before = $self->xml_before;

  # closure to make sure that $xml_before is used only once
  my $maybe_xml_before = sub {
    my @r = $xml_before ? (xml_before => $xml_before) : ();
    $xml_before = undef;
    return @r;
  };

  # closure to create a new text node
  my $mk_new_text = sub {
    my ($literal_text) = @_;
    return MsOffice::Word::Surgeon::Text->new(
      $maybe_xml_before->(),
      literal_text => $literal_text,
     );
  };

  # closure to create a new run node for enclosing a text node
  my $add_new_run = sub {
    my ($text_node) = @_;
    my $run = MsOffice::Word::Surgeon::Run->new(
      xml_before  => '',
      props       => $args{run}->props,
      inner_texts => [$text_node],
     );
    $xml .= $run->as_xml;
  };

  # closure to add text to the current text node
  my $add_to_current_text_node = sub {
    my ($txt_to_add) = @_;
    $current_text_node //= $mk_new_text->('');
    $current_text_node->{literal_text} .= $txt_to_add;
  };

  # closure to clear the current text node
  my $maybe_clear_current_text_node = sub {
    if ($current_text_node) {
      if (is_at_run_level($xml)) {
        $add_new_run->($current_text_node);
      }
      else {
        $xml .= $current_text_node->as_xml;
      }
      $current_text_node = undef;
    }
  };

  # find pattern within $self, each match becomes a fragment to handle
  my @fragments            = split qr[($pattern)], $self->{literal_text}, -1;
  my $txt_after_last_match = pop @fragments;

  # loop to handle each match
  while (my ($txt_before, $matched) = splice (@fragments, 0, 2)) {

    # new contents to replace the matched fragment
    my $replacement_contents
      = !ref $replacement ? $replacement
                          : $replacement->(matched => $matched,
                                           (!$txt_before ? $maybe_xml_before->() : ()),
                                           %args);

    my $replacement_is_xml = $replacement_contents =~ /^</;
    if ($replacement_is_xml) {
      # if there was text before the match, add it as a new run
      if ($txt_before) {
        $maybe_clear_current_text_node->();
        $add_new_run->($mk_new_text->($txt_before));
      }

      # add the xml that replaces the match
      $xml .= $replacement_contents;
    }
    else { # $replacement_contents is not xml but just literal text
      $add_to_current_text_node->(($txt_before // '') . $replacement_contents);
    }
  }

  # handle remaining contents after the last match
  if ($txt_after_last_match) {
    $add_to_current_text_node->($txt_after_last_match);
    $maybe_clear_current_text_node->();
  }
  elsif ($xml_before) {
    !$xml or croak "internal error : Text::xml_before was ignored during replacements";
    $xml = $xml_before;
  }

  return $xml;
}



sub to_uppercase {
  my $self = shift;
  $self->{literal_text} = uc($self->{literal_text});
}


1;

__END__

=encoding ISO-8859-1

=head1 NAME

MsOffice::Word::Surgeon::Text - internal representation for a node of literal text

=head1 DESCRIPTION

This is used internally by L<MsOffice::Word::Surgeon> for storing
a chunk of literal text in a MsWord document. It loosely corresponds to
a C<< <w:t> >> node in OOXML, but may also contain an anonymous XML
fragment which is the part of the document just before the C<< <w:t> >> 
node -- used for reconstructing the complete document after having changed
the contents of some text nodes.


=head1 METHODS

=head2 new

  my $text_node = MsOffice::Word::Surgeon::Text(
    xml_before   => $xml_string,
    literal_text => $text_string,
  );

Constructor for a new text object. Arguments are :

=over

=item xml_before

A string containing arbitrary XML preceding that text node in the complete document.
The string may be empty but must be present.


=item literal_text

A string of literal text.

=back



=head2 as_xml

  my $xml = $text_node->as_xml;

Returns the XML representation of that text node.
The attribute C<< xml:space="preserve" >> is automatically added
if the literal text starts of ends with a space character.


=head2 merge

  $text_node->merge($next_text_node);

Merge the contents of C<$next_text_node> together with the current text node.
This is only possible if the next text node has
an empty C<xml_before> attribute; if this condition is not met,
an exception is raised.

=head2 replace

  my $xml = $text_node->replace($pattern, $replacement_callback, %args);

Replaces all occurrences of C<$pattern> within the text node by
a new string computed by C<$replacement_callback>, and returns a new xml
string corresponding to the result of all these replacements. This is the
internal implementation for public method
L<MsOffice::Word::Surgeon/replace>.

=head2 to_uppercase

Puts the literal text within the node into uppercase letters.


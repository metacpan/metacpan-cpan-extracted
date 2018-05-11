package Mojo::SAML::Document;

use Mojo::Base -base;

use Carp ();
use Data::GUID ();
use Mojolicious;
use Mojo::ByteStream;
use Mojo::Date;
use Mojo::Template;
use Mojo::XMLSig;

use overload bool => sub {1}, '""' => sub { $_[0]->to_string }, fallback => 1;

has [qw/sign_with_key insert_signature insert_xml_declaration/];
has template => sub { die 'template is required' };

my $isa = sub {
  my ($obj, $class) = @_;
  Scalar::Util::blessed($obj) && $obj->isa($class);
};
sub _dom { Mojo::DOM->new->xml(1)->parse("$_[0]") }

sub after_render  {
  my ($self, $xml) = @_;
  if (my $sig = $self->insert_signature) {
    $xml = $self->after_render_insert_signature($xml, $sig);
  }
  if (my $key = $self->sign_with_key) {
    $xml = $self->after_render_sign($xml, $key);
  }
  if ($self->insert_xml_declaration) {
    $xml = $self->after_render_insert_xml_declaration($xml);
  }
  return "$xml";
}

sub after_render_insert_signature {
  my ($self, $dom, $sig) = @_;
  Carp::croak 'Signature must be a Mojo::SAML::Document::Signature'
    unless $sig->$isa('Mojo::SAML::Document::Signature');

  $dom = _dom($dom) unless $dom->$isa('Mojo::DOM');
  my $root = $dom->at(':root');
  unless (@{ $sig->references }) {
    my $id = $root->{ID};
    unless ($id) {
      $id = $self->get_guid;
      $root->attr(ID => $id);
    }
    $sig->references([$id]);
  }
  $root->prepend_content("$sig");
  return $dom;
}

sub after_render_insert_xml_declaration {
  my ($self, $xml) = @_;
  return qq!<?xml version="1.0"?>$xml!;
}

sub after_render_sign {
  my ($self, $xml, $key) = @_;
  return Mojo::XMLSig::sign("$xml", $key);
}

sub before_render { }

{
  my $mojo = Mojolicious->new;
  package Mojo::SAML::TemplateSandbox;
  use Mojo::SAML::Names qw/binding nameid_format/;
  sub tag { $mojo->tag(@_) }
}

sub build_template {
  my ($self, $text) = @_;
  Mojo::Template->new(
    autoescape => 1,
    namespace  => 'Mojo::SAML::TemplateSandbox',
    prepend    => 'my $self = shift',
  )->parse($text);
}

sub get_guid { Data::GUID->guid_string }
sub get_instant { Mojo::Date->new->to_datetime }

sub to_string {
  my $self = shift;
  $self->before_render;
  my $output = $self->template->process($self);
  $output = $self->after_render($output);
  return Mojo::ByteStream->new($output);
}

sub to_string_deflate {
  require Compress::Raw::Zlib;
  my $zlib = Compress::Raw::Zlib::Deflate->new;
  my $string = shift->to_string;
  my $compressed;
  Carp::croak 'Compress failed'
    unless $zlib->deflate($string, $compressed) == Compress::Raw::Zlib::Z_OK();
  Carp::croak 'Compress failed'
    unless $zlib->flush($compressed) == Compress::Raw::Zlib::Z_OK();

  return Mojo::Util::b64_encode($compressed, '');
}

1;

=head1 NAME

Mojo::SAML::Document - Base class for classes representing and generating XML snippets

=head1 SYNOPSIS

  # use as a base class
  package Mojo::SAML::Document::MyDocument;
  use Mojo::Base 'Mojo::SAML::Document';

  has template => sub { shift->build_template(<<'TEMPLATE') };
  <SomeXML>...</SomeXML>
  TEMPLATE

  # direct usage
  my $doc = Mojo::SAML::Document->new;
  $doc->template($doc->build_template(<<'TEMPLATE'));
  <SomeXML>...</SomeXML>
  TEMPLATE
  my $output = $doc->to_string;
  my $ouput = "$doc";

=head1 DESCRIPTION

L<Mojo::SAML::Document> is a base class for classes that represent XML snippets and can be used to generate those snippets from data.
These objects stringify to their XML representation (based on their L</template>) making them easily composable.

While intended as a base class, it can also be used directly for one-off snippets when setting the L</template> manually.

=head1 ATTRIBUTES

L<Mojo::SAML::Document> inherits all of the attributes from L<Mojo::Base> and implements the following new ones.

=head2 insert_signature

Optional.
A signature document, likely an instance of L<Mojo::SAML::Docuemnt::Signature> to insert.
See later methods for more description.

=head2 insert_xml_declaration

Optional, undefined (false) by default.
If true the resulting rendered document will contain an XML declaration.
This should only be set (if at all) on the outermost document snippet.
See later methods for more description.

=head2 sign_with_key

Optional.
A key to sign the document, likely an instance of L<Crypt::OpenSSL::RSA>.
See later methods for more description.

=head2 template

An instance of L<Mojo::Template> used to generate the XML.
The default implementation dies if not set.
Commonly, subclasses will overload this to provide an appropriate template for the class.

=head1 METHODS

L<Mojo::SAML::Document> inherits all of the methods from L<Mojo::Base> and implements the following new ones.

=head2 after_render

  $xml = $doc->after_render($xml);

Called during rendering (see L</to_string>) after the document is rendered but before it is wrapped in a L<Mojo::ByteStream> and returned.
It is provided here to allow overriding by specific document types.
This method can be used to post-process the rendered document.

The default implementation of this method calls L</after_render_insert_signature> if a signature is given in L</insert_signature>.
If then calls L</after_render_sign> if a key is given in L</sign_with_key>.
Finally it calls L</after_render_insert_xml_declaration> if L</insert_xml_declaration> is true.

This default implementation allows any document to be signed during rendering by giving an appropriate document (likely a L<Mojo::SAML::Document::Signature>) and a key (an instance of L<Crypt::OpenSSL::RSA>).
Note that you probably only want to sign once on a full document render (not once per snippet) so keep that in mind when composing your snippets.

=head2 after_render_insert_signature

  $xml = $doc->after_render_insert_signature($xml, $signature);

Called during the default L</after_render> implementation.
It is provided here to allow overriding the insert by specific documents types.
Note that this default implementation requires a L<Mojo::SAML::Document::Sigature> object when called and actually returns a L<Mojo::DOM> reprenting the parsed form of its input.

Note that this is probably not that useful to call directly.

=head2 after_render_insert_xml_declaration

  $xml = $doc->after_render_insert_xml_declaration($xml);

Called during the default L</after_render> implementation.
It is provided here to allow overriding the insert by specific documents types.
It prepends a standard XML declaration to the passed-in document.

Note that this is probably not that useful to call directly.

=head2 after_render_sign

  $xml = $doc->after_render_sign($xml, $key);

Called during the default L</after_render> implementation.
It is provided here to allow overriding the signing process by specific documents types.
Calls L<Mojo::XMLSig/sign> with the XML payload and the given key.

Note that this is probably not that useful to call directly.

=head2 before_render

  $doc->before_render();

Called during rendering (see L</to_string>) before the document is rendered.
It is provided here to allow overriding by specific document types.
This method can be used to pre-process and/or validate the object before rendering.
The return value is ignored.

The default implementation does nothing.

=head2 build_template

  has template => sub { shift->build_template($string) };

Builds an instance of L<Mojo::Template> from a given string.
This is especially useful in the L</template> initializer.

The resulting template sets C<autoescape> to true which promotes good xml escaping.
It configures the template to shift off the invocant as C<$self> for use during the template.
(Note that during L</to_string> or stringification no arguments are passed to the template rendering, so this is very useful.)

Finally, it sets C<namespace> to C<Mojo::SAML::TemplateSandbox>.
This namespace is prepopulated with L<Mojo::SAML::Names/binding> and L<Mojo::SAML::Names/nameid_format> functions as well as a version of L<Mojolicious::Plugins::TagHelpers/tag>.

=head2 get_guid

my $guid = $doc->get_guid;

Generates a GUID using L<Data::GUID/guid_string>.

=head2 get_instant

my $instant = $doc->get_instant;

Generates an L<"RFC 3339"/http://tools.ietf.org/html/rfc3339> datetime representing the current time using L<Mojo::Date/to_datetime>.

=head2 to_string

my $xml = $doc->to_string;

Generates a string representation of the document.
First calls L</before_render> for possible validation.
Then renders the L</template> using L<Mojo::Template/process> passing the document itself into the template.
Then it post-processes the document by calling L</after_render> with the rendered result.
Finally that result is wrapped in a L<Mojo::ByteStream> object (to prevent later rendering from xml escaping) and returned.

=head2 to_string_deflate

Calls L</to_string> but further DEFLATE encodes and base64 encodes the result.
This is useful when the document is going to passed as a query parameter.
Note that when you do this, you probably don't want to include a signature nor sign it as in this case there is a different signing procedure.

=head1 OPERATORS

L<Mojo::SAML::Document> overloads the following operators.

=head2 bool

  my $bool = !!$doc;

Always true.

=head2 stringify

  my $str = "$doc";

Alias for L</"to_string">.


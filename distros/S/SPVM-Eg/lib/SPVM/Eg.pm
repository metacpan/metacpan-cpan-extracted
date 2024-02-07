package SPVM::Eg;

our $VERSION = "0.017";

1;

=head1 Name

SPVM::Eg - Components of SPVM Engine

=head1 Description

The Eg class in L<SPVM> provides components of a web platform SPVM Engine.

=head1 Usage

  use Eg;
  
  my $document = Eg->document;
  
  my $div = $document->create_element("div");
  
  $div->set_attribute("class", "foo");
  
=head1 Class Methods

=head2 window

C<static method window : L<Eg::Window|SPVM::Eg::Window> ();>

=head2 document

  static method document : L<Eg::Node::Document|SPVM::Eg::Node::Document> ();

=head1 Classes

=over

=item * L<Eg|SPVM::Eg>

=item * L<Eg::API|SPVM::Eg::API>

=item * L<Eg::API::App|SPVM::Eg::API::App>

=item * L<Eg::API::Window|SPVM::Eg::API::Window>

=item * L<Eg::CSS::Rule|SPVM::Eg::CSS::Rule>

=item * L<Eg::CSS::Rule::CounterStyle|SPVM::Eg::CSS::Rule::CounterStyle>

=item * L<Eg::CSS::Rule::FontFace|SPVM::Eg::CSS::Rule::FontFace>

=item * L<Eg::CSS::Rule::FontFeatureValues|SPVM::Eg::CSS::Rule::FontFeatureValues>

=item * L<Eg::CSS::Rule::FontPaletteValues|SPVM::Eg::CSS::Rule::FontPaletteValues>

=item * L<Eg::CSS::Rule::Grouping|SPVM::Eg::CSS::Rule::Grouping>

=item * L<Eg::CSS::Rule::Import|SPVM::Eg::CSS::Rule::Import>

=item * L<Eg::CSS::Rule::Keyframe|SPVM::Eg::CSS::Rule::Keyframe>

=item * L<Eg::CSS::Rule::Keyframes|SPVM::Eg::CSS::Rule::Keyframes>

=item * L<Eg::CSS::Rule::LayerBlock|SPVM::Eg::CSS::Rule::LayerBlock>

=item * L<Eg::CSS::Rule::LayerStatement|SPVM::Eg::CSS::Rule::LayerStatement>

=item * L<Eg::CSS::Rule::Media|SPVM::Eg::CSS::Rule::Media>

=item * L<Eg::CSS::Rule::Namespace|SPVM::Eg::CSS::Rule::Namespace>

=item * L<Eg::CSS::Rule::Page|SPVM::Eg::CSS::Rule::Page>

=item * L<Eg::CSS::Rule::Property|SPVM::Eg::CSS::Rule::Property>

=item * L<Eg::CSS::Rule::Style|SPVM::Eg::CSS::Rule::Style>

=item * L<Eg::CSS::Rule::Supports|SPVM::Eg::CSS::Rule::Supports>

=item * L<Eg::CSS::StyleDeclaration|SPVM::Eg::CSS::StyleDeclaration>

=item * L<Eg::CSS::StyleSheet|SPVM::Eg::CSS::StyleSheet>

=item * L<Eg::DOM::Implementation|SPVM::Eg::DOM::Implementation>

=item * L<Eg::Event::Target|SPVM::Eg::Event::Target>

=item * L<Eg::History|SPVM::Eg::History>

=item * L<Eg::Location|SPVM::Eg::Location>

=item * L<Eg::Node|SPVM::Eg::Node>

=item * L<Eg::Node::Attr|SPVM::Eg::Node::Attr>

=item * L<Eg::Node::CDATASection|SPVM::Eg::Node::CDATASection>

=item * L<Eg::Node::CharacterData|SPVM::Eg::Node::CharacterData>

=item * L<Eg::Node::Comment|SPVM::Eg::Node::Comment>

=item * L<Eg::Node::Document|SPVM::Eg::Node::Document>

=item * L<Eg::Node::Document::XML|SPVM::Eg::Node::Document::XML>

=item * L<Eg::Node::DocumentFragment|SPVM::Eg::Node::DocumentFragment>

=item * L<Eg::Node::DocumentType|SPVM::Eg::Node::DocumentType>

=item * L<Eg::Node::Element|SPVM::Eg::Node::Element>

=item * L<Eg::Node::Element::HTML|SPVM::Eg::Node::Element::HTML>

=item * L<Eg::Node::Element::HTML::Anchor|SPVM::Eg::Node::Element::HTML::Anchor>

=item * L<Eg::Node::Element::HTML::Area|SPVM::Eg::Node::Element::HTML::Area>

=item * L<Eg::Node::Element::HTML::Audio|SPVM::Eg::Node::Element::HTML::Audio>

=item * L<Eg::Node::Element::HTML::BR|SPVM::Eg::Node::Element::HTML::BR>

=item * L<Eg::Node::Element::HTML::Base|SPVM::Eg::Node::Element::HTML::Base>

=item * L<Eg::Node::Element::HTML::Body|SPVM::Eg::Node::Element::HTML::Body>

=item * L<Eg::Node::Element::HTML::Button|SPVM::Eg::Node::Element::HTML::Button>

=item * L<Eg::Node::Element::HTML::Canvas|SPVM::Eg::Node::Element::HTML::Canvas>

=item * L<Eg::Node::Element::HTML::DList|SPVM::Eg::Node::Element::HTML::DList>

=item * L<Eg::Node::Element::HTML::Data|SPVM::Eg::Node::Element::HTML::Data>

=item * L<Eg::Node::Element::HTML::DataList|SPVM::Eg::Node::Element::HTML::DataList>

=item * L<Eg::Node::Element::HTML::Details|SPVM::Eg::Node::Element::HTML::Details>

=item * L<Eg::Node::Element::HTML::Dialog|SPVM::Eg::Node::Element::HTML::Dialog>

=item * L<Eg::Node::Element::HTML::Div|SPVM::Eg::Node::Element::HTML::Div>

=item * L<Eg::Node::Element::HTML::Embed|SPVM::Eg::Node::Element::HTML::Embed>

=item * L<Eg::Node::Element::HTML::FieldSet|SPVM::Eg::Node::Element::HTML::FieldSet>

=item * L<Eg::Node::Element::HTML::Font|SPVM::Eg::Node::Element::HTML::Font>

=item * L<Eg::Node::Element::HTML::Form|SPVM::Eg::Node::Element::HTML::Form>

=item * L<Eg::Node::Element::HTML::Frame|SPVM::Eg::Node::Element::HTML::Frame>

=item * L<Eg::Node::Element::HTML::HR|SPVM::Eg::Node::Element::HTML::HR>

=item * L<Eg::Node::Element::HTML::Head|SPVM::Eg::Node::Element::HTML::Head>

=item * L<Eg::Node::Element::HTML::Heading|SPVM::Eg::Node::Element::HTML::Heading>

=item * L<Eg::Node::Element::HTML::Html|SPVM::Eg::Node::Element::HTML::Html>

=item * L<Eg::Node::Element::HTML::IFrame|SPVM::Eg::Node::Element::HTML::IFrame>

=item * L<Eg::Node::Element::HTML::Image|SPVM::Eg::Node::Element::HTML::Image>

=item * L<Eg::Node::Element::HTML::Input|SPVM::Eg::Node::Element::HTML::Input>

=item * L<Eg::Node::Element::HTML::LI|SPVM::Eg::Node::Element::HTML::LI>

=item * L<Eg::Node::Element::HTML::Label|SPVM::Eg::Node::Element::HTML::Label>

=item * L<Eg::Node::Element::HTML::Legend|SPVM::Eg::Node::Element::HTML::Legend>

=item * L<Eg::Node::Element::HTML::Link|SPVM::Eg::Node::Element::HTML::Link>

=item * L<Eg::Node::Element::HTML::Map|SPVM::Eg::Node::Element::HTML::Map>

=item * L<Eg::Node::Element::HTML::Marquee|SPVM::Eg::Node::Element::HTML::Marquee>

=item * L<Eg::Node::Element::HTML::Media|SPVM::Eg::Node::Element::HTML::Media>

=item * L<Eg::Node::Element::HTML::Menu|SPVM::Eg::Node::Element::HTML::Menu>

=item * L<Eg::Node::Element::HTML::Meta|SPVM::Eg::Node::Element::HTML::Meta>

=item * L<Eg::Node::Element::HTML::Meter|SPVM::Eg::Node::Element::HTML::Meter>

=item * L<Eg::Node::Element::HTML::Mod|SPVM::Eg::Node::Element::HTML::Mod>

=item * L<Eg::Node::Element::HTML::OList|SPVM::Eg::Node::Element::HTML::OList>

=item * L<Eg::Node::Element::HTML::Object|SPVM::Eg::Node::Element::HTML::Object>

=item * L<Eg::Node::Element::HTML::OptGroup|SPVM::Eg::Node::Element::HTML::OptGroup>

=item * L<Eg::Node::Element::HTML::Option|SPVM::Eg::Node::Element::HTML::Option>

=item * L<Eg::Node::Element::HTML::Output|SPVM::Eg::Node::Element::HTML::Output>

=item * L<Eg::Node::Element::HTML::Paragraph|SPVM::Eg::Node::Element::HTML::Paragraph>

=item * L<Eg::Node::Element::HTML::Param|SPVM::Eg::Node::Element::HTML::Param>

=item * L<Eg::Node::Element::HTML::Picture|SPVM::Eg::Node::Element::HTML::Picture>

=item * L<Eg::Node::Element::HTML::Portal|SPVM::Eg::Node::Element::HTML::Portal>

=item * L<Eg::Node::Element::HTML::Pre|SPVM::Eg::Node::Element::HTML::Pre>

=item * L<Eg::Node::Element::HTML::Progress|SPVM::Eg::Node::Element::HTML::Progress>

=item * L<Eg::Node::Element::HTML::Quote|SPVM::Eg::Node::Element::HTML::Quote>

=item * L<Eg::Node::Element::HTML::Script|SPVM::Eg::Node::Element::HTML::Script>

=item * L<Eg::Node::Element::HTML::Select|SPVM::Eg::Node::Element::HTML::Select>

=item * L<Eg::Node::Element::HTML::Slot|SPVM::Eg::Node::Element::HTML::Slot>

=item * L<Eg::Node::Element::HTML::Source|SPVM::Eg::Node::Element::HTML::Source>

=item * L<Eg::Node::Element::HTML::Span|SPVM::Eg::Node::Element::HTML::Span>

=item * L<Eg::Node::Element::HTML::Style|SPVM::Eg::Node::Element::HTML::Style>

=item * L<Eg::Node::Element::HTML::Table|SPVM::Eg::Node::Element::HTML::Table>

=item * L<Eg::Node::Element::HTML::TableCaption|SPVM::Eg::Node::Element::HTML::TableCaption>

=item * L<Eg::Node::Element::HTML::TableCell|SPVM::Eg::Node::Element::HTML::TableCell>

=item * L<Eg::Node::Element::HTML::TableCol|SPVM::Eg::Node::Element::HTML::TableCol>

=item * L<Eg::Node::Element::HTML::TableRow|SPVM::Eg::Node::Element::HTML::TableRow>

=item * L<Eg::Node::Element::HTML::TableSection|SPVM::Eg::Node::Element::HTML::TableSection>

=item * L<Eg::Node::Element::HTML::Template|SPVM::Eg::Node::Element::HTML::Template>

=item * L<Eg::Node::Element::HTML::TextArea|SPVM::Eg::Node::Element::HTML::TextArea>

=item * L<Eg::Node::Element::HTML::Time|SPVM::Eg::Node::Element::HTML::Time>

=item * L<Eg::Node::Element::HTML::Title|SPVM::Eg::Node::Element::HTML::Title>

=item * L<Eg::Node::Element::HTML::Track|SPVM::Eg::Node::Element::HTML::Track>

=item * L<Eg::Node::Element::HTML::UList|SPVM::Eg::Node::Element::HTML::UList>

=item * L<Eg::Node::Element::HTML::Unknown|SPVM::Eg::Node::Element::HTML::Unknown>

=item * L<Eg::Node::Element::HTML::Video|SPVM::Eg::Node::Element::HTML::Video>

=item * L<Eg::Node::ProcessingInstruction|SPVM::Eg::Node::ProcessingInstruction>

=item * L<Eg::Node::ShadowRoot|SPVM::Eg::Node::ShadowRoot>

=item * L<Eg::Node::Text|SPVM::Eg::Node::Text>

=item * L<Eg::OS|SPVM::Eg::OS>

=item * L<Eg::OS::API|SPVM::Eg::OS::API>

=item * L<Eg::Runtime|SPVM::Eg::Runtime>

=item * L<Eg::URL|SPVM::Eg::URL>

=item * L<Eg::URL::SearchParams|SPVM::Eg::URL::SearchParams>

=item * L<Eg::Window|SPVM::Eg::Window>

=back

=head1 Repository

L<SPVM::Eg - Github|https://github.com/yuki-kimoto/SPVM-Eg>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License


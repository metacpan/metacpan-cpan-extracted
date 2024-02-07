package SPVM::Eg::Node::Element::HTML;



1;

=head1 Name

SPVM::Eg::Node::Element::HTML - HTMLElement in JavaScript

=head1 Description

The Eg::Node::Element::HTML class in L<SPVM> represents any HTML element.

This class is a port of L<HTMLElement|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement> in JavaScript.

=head1 Usage

  my $div = Eg->document->create_element("div");
  
  my $style = $div->style;
  
  $div->set_attribute("id", "1");

=head2 Inheritance

L<Eg::Node::Element|SPVM::Eg::Node::Element>

=head1 Fields

C<has style : ro L<Eg::CSS::StyleDeclaration|SPVM::Eg::CSS::StyleDeclaration>;>

The inline style of an element in the form of a live L<Eg::CSS::StyleDeclaration|SPVM::Eg::CSS::StyleDeclaration> object that contains a list of all styles properties for that element with values assigned only for the attributes that are defined in the element's inline style attribute.

For details, see L<HTMLElement.style|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/style> in JavaScript.

=head1 Well Known Child Classes

=over 2

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

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License


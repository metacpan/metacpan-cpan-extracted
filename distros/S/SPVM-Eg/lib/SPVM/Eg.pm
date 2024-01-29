package SPVM::Eg;

our $VERSION = "0.014";

1;

=head1 Name

SPVM::Eg - HTML

=head1 Description

The Eg class in L<SPVM> provides components of web platform SPVM Engine.

=head1 Usage

  use Eg;
  
  my $document = Eg->document;
  
  my $div = $document->create_element("div");
    
  $div->set_attribute(atrr => "value");
  
  $div->set_text("foo");
  
=head1 Repository

L<SPVM::Eg - Github|https://github.com/yuki-kimoto/SPVM-Eg>

=head1 Class Methods

=head2 window

  static method window : Eg::Window ();

=head2 document

  static method document : Eg::Node::Document::HTML ();

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License


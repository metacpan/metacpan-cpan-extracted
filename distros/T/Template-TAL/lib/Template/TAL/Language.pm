=head1 NAME

Template::TAL::Language - base class for Template::TAL languages

=head1 SYNOPSIS

  my $tal = Template::TAL->new();
  $tal->add_language(MyLanguage->new);
  $tal->process( $template, $data );

=head1 DESCRIPTION

To be as flexible as possible, the tag handling in Template::TAL is
implemented as Language modules, which declare the namespace and the
tags that they wish to handle, and are called from the 'process_tag_node'
method of Template::TAL::Template. So far, there is only one
implemented language, L<Template::TAL::Language::TAL>, and there is no
easy way of changing which languages are loaded by Template::TAL in
it's normal use, though I expect this to change in the near future.
Specifically, when L<Template::TAL::Language::METAL> is ready, support
for adding Language modules will get a lot better.

=head1 SUBCLASSING

Assuming you want to create a new Language, subclass this module, and
override the L<namespace> and L<tags> methods, and provide process_tag_XXX
methods for every tag your language contains. For instance:

  package MyLanguage;
  use base qw( Template::TAL::Language );
  
  sub namespace { 'http://foo.bar' }
  sub tags {qw( bar )}
  sub process_tag_bar {
    my ($self, $parent, $element, $value, $local_context, $global_context);
    return (); # just remove the node
  }
  
When loaded, this will apply to the template

  <html xmlns:test="http://foo.bar">
    <fred test:bar="1">this element will be removed</fred>
  </html>

=cut

package Template::TAL::Language;
use warnings;
use strict;
use Carp qw( croak );

=head1 METHODS

Override these methods in a subclass

=over

=item new()

creates a new instance

=cut

sub new {
  return bless {}, shift;
}

=item namespace

return the namespace of the tags this module implements

=cut

sub namespace { return }

=item tags

return a list of tags in that namespace, in processing order, that this module
handles.

=cut

sub tags { () }

=item process_tag_<tagname>( caller, element, value, local_context, global_context )

called to process tags with the given tagname. The params are

=over

=item element - the XML::LibXML::Element being processed

=item value - the string value of the attribute

=item local_context - the local context hash, use this for preference

=item global_context - the global context hash

=back

Certian tag names, eg 'omit-tag', contain '-' characters, which will be converted
to '_' characters for the method call, so define process_tag_omit_tag { .. }.

=cut

# sub process_tag_foo { ..

=back

=head1 COPYRIGHT

Written by Tom Insam, Copyright 2005 Fotango Ltd. All Rights Reserved

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;

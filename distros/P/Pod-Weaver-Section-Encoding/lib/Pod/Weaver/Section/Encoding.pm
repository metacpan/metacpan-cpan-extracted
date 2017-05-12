package Pod::Weaver::Section::Encoding;
our $VERSION = '0.100830';
use Moose;
with 'Pod::Weaver::Role::Section';
# ABSTRACT: add a encoding pod tag with encoding (for your Perl module)

use Moose::Autobox;


use Pod::Elemental::Element::Pod5::Command;
use Pod::Elemental::Element::Pod5::Ordinary;
use Pod::Elemental::Element::Nested;

sub weave_section {
  my ($self, $document, $input) = @_;

  return unless my $ppi_document = $input->{ppi_document};
  my $pkg_node = $ppi_document->find_first('PPI::Statement::Package');

  my $filename = $input->{filename} || 'file';

  Carp::croak sprintf "couldn't find package declaration in %s", $filename
    unless $pkg_node;

  my $package = $pkg_node->namespace;

  my ($abstract)
    = $ppi_document->serialize =~ /^\s*#+\s*ENCODING:\s*(.+)$/m;

  $self->log([ "couldn't find encoding in %s", $filename ]) unless $abstract;
 
  my $name_para = Pod::Elemental::Element::Nested->new({
    command  => 'encoding',
    content  => $abstract,
  });
  
  $document->children->push($name_para);
}

1;

__END__
=pod

=head1 NAME

Pod::Weaver::Section::Encoding - add a encoding pod tag with encoding (for your Perl module)

=head1 VERSION

version 0.100830

=head1 OVERVIEW

This section plugin will produce a hunk of Pod giving the encoding of the document
as well as an encoding, like this:

    =encoding utf-8

It will look for the first package declaration, and for a comment in this form:

    # ENCODING: utf-8

You have to add C<[Encoding]> in your weaver.* configuration file:

    [@CorePrep]
    
    [Encoding]
    
    [Name]
    [Version]
    
    [Region  / prelude]
    
    ...

I stole this code from L<Pod::Weaver::Section::Name>.

=head1 AUTHOR

  Keedi Kim - 김도형 <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


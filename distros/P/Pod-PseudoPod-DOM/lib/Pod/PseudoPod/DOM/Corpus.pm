package Pod::PseudoPod::DOM::Corpus;
# ABSTRACT: a collection of documents which share metadata elements

use strict;
use warnings;

use Moose;
use Path::Class;

use Pod::PseudoPod::DOM::Index;
use Pod::PseudoPod::DOM::TableOfContents;
use Pod::PseudoPod::DOM::App 'open_fh';

has 'documents',  is => 'ro', default => sub { [] };
has 'references', is => 'ro', default => sub { {} };
has 'index',      is => 'ro',
    default => sub { Pod::PseudoPod::DOM::Index->new };
has 'contents',   is => 'ro',
    default => sub { Pod::PseudoPod::DOM::TableOfContents->new };

sub add_document
{
    my ($self, $document) = @_;
    push @{ $self->documents }, $document;
    $self->add_index_from_document(      $document );
    $self->add_references_from_document( $document );
    $self->add_contents_from_document(   $document );
}

sub add_index_from_document
{
    my ($self, $document) = @_;
    $self->index->add_document( $document );
}

sub add_references_from_document
{
    my ($self, $document) = @_;
}

sub add_contents_from_document
{
    my ($self, $document) = @_;
    $self->contents->add_document( $document );
}

sub get_index
{
    my $self = shift;
    return $self->index->emit_index;
}

sub get_toc
{
    my $self      = shift;
    return $self->contents->emit_toc;
}

sub write_documents
{
    my $self      = shift;
    my $documents = $self->documents;

    $_->resolve_anchors for @$documents;

    for my $doc (@$documents)
    {
        my $output = $doc->filename;
        my $outfh  = open_fh( $output, '>' );
        print {$outfh} $doc->emit;
    }
}

sub write_index
{
    my $self  = shift;
    my $outfh = $self->get_fh_in_path( 'theindex', '>' );
    print {$outfh} $self->get_index;
}

sub write_toc
{
    my $self  = shift;
    my $outfh = $self->get_fh_in_path( 'index', '>' );
    print {$outfh} $self->get_toc;
}

sub get_fh_in_path
{
    my ($self, $filename, $mode) = @_;
    my $docs     = $self->documents;
    return unless @$docs;

    my $docfile  = $docs->[0]->filename;
    my ($suffix) = $docfile =~ /\.(.+)$/;
    my $dir      = file( $docfile )->dir;
    my $file     = $dir->file( $filename . '.' . $suffix );

    return open_fh( $file->stringify, $mode );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::PseudoPod::DOM::Corpus - a collection of documents which share metadata elements

=head1 VERSION

version 1.20210620.2040

=head1 AUTHOR

chromatic <chromatic@wgz.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by chromatic.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Pod::PseudoPod::DOM::Index;
# ABSTRACT: an index for a PPDOM Corpus

use strict;
use warnings;

use Moose;

has 'entries',      is => 'ro', default => sub { {} };
has 'seen_entries', is => 'ro', default => sub { {} };

sub add_document
{
    my ($self, $document) = @_;
    my $seen_entries      = $self->seen_entries;
    $self->add_entry( $_ )
        for $document->get_index_entries( $seen_entries );
}

sub add_entry
{
    my ($self, $node)        = @_;
    my ($title, @subentries) = $node->get_key;
    my $entry                = $self->get_top_entry( $title );
    $entry->add( $title, @subentries, $node );
}

sub get_top_entry
{
    my ($self, $key) = @_;
    my $entries      = $self->entries;
    my $top_key      = $key =~ /(\w)/ ? $1 : substr $key, 0, 1;
    return $entries->{uc $top_key}
        ||= Pod::PseudoPod::DOM::Index::TopEntryList->new( key => uc $top_key );
}

sub emit_index
{
    my $self    = shift;
    my $entries = $self->entries;
    my $heading = <<END_HTML_HEAD;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
    "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<title></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="stylesheet" href="../css/style.css" type="text/css" />
</head>
<body>
<h1 id="index">Index</h1>
END_HTML_HEAD

    my $footer = <<END_HTML_FOOTER;
</body>
</html>
END_HTML_FOOTER

    return $heading
         . join( "\n", map { $entries->{$_}->emit } sort keys %$entries )
         . $footer;
}

__PACKAGE__->meta->make_immutable;

package Pod::PseudoPod::DOM::Index::EntryList;

use strict;
use warnings;

use Moose;
use HTML::Entities;

has 'key',      is => 'ro', required => 1;
has 'contents', is => 'ro', default  => sub { {} };

sub add
{
    my ($self, $key) = splice @_, 0, 2;
    my $contents     = $self->contents;
    my $node         = pop @_;
    my $elements     = $contents->{$key} ||= [];

    return $self->add_nested_entry( $key, $node, $elements, @_ ) if @_;
    $self->add_entry(               $key, $node, $elements );
}

sub add_nested_entry
{
    my ($self, $key, $node, $elements, @path) = @_;

    for my $element (@$elements)
    {
        next unless $element->isa( 'Pod::PseudoPod::DOM::Index::EntryList' );
        $element->add( @path, $node );
        return;
    }

    my $entry_list = Pod::PseudoPod::DOM::Index::EntryList->new( key => $key );

    $entry_list->add( @path, $node );
    push @{ $elements }, $entry_list;
}

sub add_entry
{
    my ($self, $key, $node, $elements, @path) = @_;

    for my $element (@$elements)
    {
        next unless $element->isa( 'Pod::PseudoPod::DOM::Index::Entry' );
        $element->add_location( $node );
        return;
    }

    my $entry = Pod::PseudoPod::DOM::Index::Entry->new( key => $key );
    $entry->add_location( $node );
    push @{ $elements }, $entry;
}

sub emit
{
    my $self    = shift;
    my $key     = encode_entities( $self->key );

    return qq|$key\n| . $self->emit_contents;
}

sub sort_content_hash
{
    my ($self, $hash) = @_;

    return  map { $_->[1] }
           sort { $a->[0] cmp $b->[0] }
            map { my $key = $_; $key =~ s/[^\w\s]//g; [ lc( $key ), $_ ] }
            keys %$hash;
}

sub emit_contents
{
    my $self     = shift;
    my $contents = $self->contents;
    my $content  = qq|<ul>\n|;

    for my $key ($self->sort_content_hash( $contents ))
    {
        my @sorted = map  { $_->[2] }
                     sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] }
                     map  {
                            my $title = $_->key;
                            $title    =~ s/[^\w\s]//g;
                            [ lc( $title ), ref $_, $_ ]
                          }
                         @{ $contents->{$key} };

        $content .= join "\n", map { '<li>' . $_->emit . "</li>\n" } @sorted;
    }

    return $content . qq|</ul>\n|;
}

__PACKAGE__->meta->make_immutable;

package Pod::PseudoPod::DOM::Index::Entry;

use strict;
use warnings;

use Moose;
use HTML::Entities;

has 'key',       is => 'ro', required => 1;
has 'locations', is => 'ro', default  => sub { [] };

sub emit
{
    my $self = shift;

    return encode_entities( $self->key ) . ' '
         . join ' ', map { $_->emit } @{ $self->locations };
}

sub add_location
{
    my ($self, $entry) = @_;
    push @{ $self->locations },
        Pod::PseudoPod::DOM::Index::Location->new( entry => $entry );
}

__PACKAGE__->meta->make_immutable;

package Pod::PseudoPod::DOM::Index::Location;
# ABSTRACT: represents a location to which an index entry points

use strict;
use warnings;

use Moose;

has 'entry', is => 'ro', required => 1;

sub emit
{
    my $self  = shift;
    my $entry = $self->entry;

    return '[' . $entry->emit_index_link . ']';
}

__PACKAGE__->meta->make_immutable;

package Pod::PseudoPod::DOM::Index::TopEntryList;

use strict;
use warnings;

use Moose;
use HTML::Entities;

extends 'Pod::PseudoPod::DOM::Index::EntryList';

sub emit
{
    my $self = shift;
    my $key  = encode_entities( $self->key );

    return qq|<h2>$key</h2>\n\n| . $self->emit_contents;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::PseudoPod::DOM::Index - an index for a PPDOM Corpus

=head1 VERSION

version 1.20210620.2040

=head1 AUTHOR

chromatic <chromatic@wgz.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by chromatic.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

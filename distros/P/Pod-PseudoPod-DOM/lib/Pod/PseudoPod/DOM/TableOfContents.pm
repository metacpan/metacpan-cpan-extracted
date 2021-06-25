package Pod::PseudoPod::DOM::TableOfContents;
# ABSTRACT: table of contents for a PPDOM Corpus

use strict;
use warnings;

use Moose;

has 'contents',
    is      => 'ro',
    default => sub { Pod::PseudoPod::DOM::TableOfContents::TopContents->new };

sub add_document
{
    my ($self, $document) = @_;
    my $headings          = $document->extract_headings( max_depth => 5 );
    my @stack             = ($self->contents);
    my $current_level     = 0;
    my $class             = 'Pod::PseudoPod::DOM::TableOfContents::Entry';
    my $last_entry;

    for my $heading (@$headings)
    {
        my $level = $heading->level;
        my $entry = $class->new( heading => $heading );

        if ($level == $current_level)
        {
            $stack[-1]->add( $entry );
        }
        elsif ($level > $current_level)
        {
            $last_entry->add( $entry );
            push @stack, $last_entry;
        }
        else
        {
            my $diff    = $current_level - $level;
            $last_entry = pop @stack for 1 .. $diff;
            $stack[-1]->add( $entry );
        }

        $last_entry    = $entry;
        $current_level = $level;
    }
}

sub emit_toc
{
    my $self = shift;
    return <<END_HTML . $self->contents->emit . "</ul></body></html>";
<!DOCTYPE html>
<html lang="en">
<head>
<link rel="stylesheet" href="../css/style.css" type="text/css" />
</head>
<body>
END_HTML
}

__PACKAGE__->meta->make_immutable;

package Pod::PseudoPod::DOM::TableOfContents::TopContents;

use strict;
use warnings;

use Moose;

has 'kids', is => 'ro', default  => sub { [] };

sub add
{
    my ($self, $entry) = @_;
    push @{ $self->kids }, $entry;
}

sub emit
{
    my $self     = shift;
    my $kids     = $self->kids;
    return '' unless @$kids;

    my $contents = '';
    for my $kid (@$kids)
    {
        $contents .= '<h2>' . $kid->heading->get_heading_link . "</h2>\n"
                  .  $kid->emit_kids;
    }

    return $contents;
}

__PACKAGE__->meta->make_immutable;

package Pod::PseudoPod::DOM::TableOfContents::Entry;

use strict;
use warnings;

use Moose;

has 'kids',    is => 'ro', default  => sub { [] };
has 'heading', is => 'ro', required => 1;

sub add
{
    my ($self, $entry) = @_;
    push @{ $self->kids }, $entry;
}

sub emit_kids
{
    my $self = shift;
    my $kids = $self->kids;
    return '' unless @$kids;
    my $contents = "<ul>\n";

    for my $kid (@$kids)
    {
        $contents .= $kid->emit;
    }

    return $contents . "\n</ul>\n";
}

sub emit
{
    my $self     = shift;
    my $kids     = $self->kids;
    return "<li>" . $self->heading->get_heading_link
                  . $self->emit_kids . "</li>\n";
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::PseudoPod::DOM::TableOfContents - table of contents for a PPDOM Corpus

=head1 VERSION

version 1.20210620.2040

=head1 AUTHOR

chromatic <chromatic@wgz.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by chromatic.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

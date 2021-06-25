package Pod::PseudoPod::DOM::Role::HTML;
# ABSTRACT: an HTML formatter role for PseudoPod DOM trees

use strict;
use warnings;

use Moose::Role;

use HTML::Entities;
use Scalar::Util 'blessed';
use MIME::Base64 'encode_base64url';

requires 'type';
has 'add_body_tags',     is => 'ro', default => 0;
has 'emit_environments', is => 'ro', default => sub { {} };
has 'anchors',           is => 'rw', default => sub { {} };

sub get_anchor
{
    my $self   = shift;
    my $anchor = $self->emit_kids( encode => 'index_anchor' );
    return encode_base64url( $anchor );
}

sub get_link_for_anchor
{
    my ($self, $anchor) = @_;
    my $anchors         = $self->anchors;

    return unless my $heading = $anchors->{$anchor};
    my $filename = $heading->link;
    my $target   = $heading->get_anchor;
    my $title    = $heading->get_link_text;

    return $filename, $target, $title;
}

sub resolve_anchors
{
    my $self    = shift;
    my $anchors = $self->anchors;

    for my $anchor (@{ $self->anchor })
    {
        my $a = $anchor->emit_kids;
        $anchors->{$anchor->emit_kids} = $anchor;
    }
}

sub get_index_entries
{
    my ($self, $seen) = @_;
    $seen           ||= {};

    my @entries;

    for my $entry (@{ $self->index })
    {
        my $text = $entry->emit_kids( encode => 'index_anchor' );
        $entry->id( ++$seen->{ $text } );
        push @entries, $entry;
    }

    return @entries;
}

sub accept_targets { qw( html HTML xhtml XHTML ) }
sub encode_E_contents {}

my %characters = (
    acute    => sub { '&' . shift . 'acute;' },
    grave    => sub { '&' . shift . 'grave;' },
    uml      => sub { '&' . shift . 'uml;'   },
    cedilla  => sub { '&' . shift . 'cedil;' },
    opy      => sub { '&copy;'               },
    dash     => sub { '&mdash;'              },
    lusmn    => sub { '&plusmn;'             },
    mp       => sub { '&amp;'                },
    rademark => sub { '&#8482;'              },
);

sub emit_character
{
    my ($self, %args) = @_;
    my $content       = eval { $self->emit_kids };

    return ''       unless defined $content;

    if (my ($char, $class) = $content =~ /(\w)(\w+)/)
    {
        return $characters{$class}->($char) if exists $characters{$class};
    }

    $args{encode}   ||= '';
    my $char = Pod::Escapes::e2char( $content );
    return $char if $args{encode} =~ /^(index_|id$)/;

    return $self->handle_encoding( $char );
}

sub emit
{
    my $self = shift;
    my $type = $self->type;
    my $emit = 'emit_' . $type;

    $self->$emit( @_ );
}

sub emit_document
{
    my $self = shift;

    return $self->emit_body if $self->add_body_tags;
    return $self->emit_kids( @_ );
}

sub extract_headings
{
    my ($self, %args) = @_;
    my @headings;

    for my $kid (@{ $self->children })
    {
        next unless $kid->type eq 'header';
        next if     $kid->exclude_from_toc( $args{max_depth} );
        push @headings, $kid;
    }

    return \@headings;
}

sub emit_toc
{
    my $self     = shift;
    my $headings = $self->extract_headings;

    return $self->walk_headings( $headings, filename => $self->filename );
}

sub walk_headings
{
    my ($self, $headings, %args) = @_;
    $args{indent}              ||= '';

    my $toc = '';

    for my $heading (@$headings)
    {
        $toc .= $args{indent};

        if (blessed($heading))
        {
            $toc .= '<li>' . $heading->get_heading_link( %args );
        }
        else
        {
            my $indent = $args{indent} . '  ';
            $toc .= qq|\n$args{indent}|
                 .  $args{indent} . qq|<ul>\n|
                 .  $self->walk_headings( $heading, %args, indent => $indent )
                 .  $args{indent} . qq|</ul>\n|;

        }

        $toc .= qq|</li>\n|;
    }

    return $toc . qq|\n|;
}

sub get_heading_link
{
    my ($self, %args) = @_;

    my $content       = $self->emit_kids;
    my $filename      = $self->filename || '';
    my $frag          = $self->get_anchor;

    $content          =~ s/^\*//;
    return qq|<a href="$filename#$frag">$content</a>|;
}

sub emit_body
{
    my $self = shift;
    return <<END_HTML_HEAD . $self->emit_kids( @_ ) . <<END_HTML;
<!DOCTYPE html>
<html lang="en">
<head>
<link rel="stylesheet" href="../css/style.css" type="text/css" />
</head>
<body>

END_HTML_HEAD
</body>
</html>
END_HTML
}

sub emit_kids
{
    my $self = shift;
    join '', map { $_->emit( @_ ) } @{ $self->children };
}

sub emit_header
{
    my $self    = shift;
    my $content = $self->emit_kids( @_ );
    my $id_node = $self->anchor;
    my $id      = $id_node ? $id_node->get_anchor : $self->get_anchor;
    my $no_toc  = $content =~ s/^\*//;
    my $level   = 'h' . ($self->level + 1);
    my $anchor  = $id_node ? $self->emit_index( @_ ) : '';

    return qq|<$level id="$id">$anchor$content</$level>\n\n|;
}

sub emit_plaintext
{
    my ($self, %args) = @_;
    my $content       = $self->content;
    $content          = '' unless defined $content;
    $self->handle_encoding( $content, %args );
}

sub handle_encoding
{
    my ($self, $content, %args) = @_;

    if (my $encode = $args{encode})
    {
        my $method = 'encode_' . $encode;
        return $self->$method( $content, %args );
    }

    return $self->encode_text( $content, %args );
}

sub encode_none { $_[1] }

sub encode_split
{
    my ($self, $content, %args) = @_;
    my $target                  = $args{target};
    return join $args{joiner},
        map { $self->encode_text( $_ ) } split /\s*\Q$target\E\s*/, $content;
}

sub encode_text
{
    my ($self, $text) = @_;

    use Carp;
    unless (defined $text)
    {
        confess 'no text';
    }
    $text = encode_entities($text);
    $text =~ s/\s*---\s*/&#8213;/g;
    $text =~ s/\s*--\s*/&mdash;/g;

    return $text;
}

sub encode_id
{
    my ($self, $text) = @_;
    $text =~ s/<.+?>//g;
    $text =~ s/\W//g;
    return lc $text;
}

sub encode_index_anchor
{
    my ($self, $text) = @_;

    $text =~ s/^\*//;
    $text =~ s/[\s"]//g;

    return $text;
}

sub encode_index_key
{
    my ($self, $text) = @_;
    $text =~ s/^\s+|\s+$//g;
    return $text;
}

sub encode_verbatim_text
{
    my ($self, $text) = @_;
    return encode_entities( $text );
}

sub emit_literal
{
    my $self = shift;
    my @kids;

    if (my $title = $self->title)
    {
        my $target = $title->emit_kids( encode => 'none' );
        @kids = map
        {
            $_->emit_kids(
                encode => 'split', target => $target, joiner => "</p>\n\n<p>",
            )
        } @{ $self->children };
    }
    else
    {
        @kids = map { $_->emit_kids( @_ ) } @{ $self->children };
    }

    return qq|<div class="literal"><p>|
         . join( "\n", @kids )
         . qq|</p></div>\n\n|;
}

sub emit_anchor
{
    my $self = shift;
    return qq|<a name="| . $self->get_anchor . qq|"></a>|;
}

sub emit_number_item
{
    my $self   = shift;
    my $marker = $self->marker;
    my $number = $marker ? qq| number="$marker"| : '';
    return "<li$number>" . $self->emit_kids . "</li>\n\n";
}

sub emit_text_item
{
    my $self  = shift;
    my $kids  = $self->children;
    return "<li></li>\n\n" unless @$kids;

    my $first = shift @$kids;
    return '<li>' . $first->emit( @_ ) . qq|</li>\n\n| unless @$kids;

    return "<li><p>" . $first->emit . "</p>\n\n"
         . join( '', map { $_->emit } @$kids ) . "</li>\n\n";
}

sub emit_verbatim
{
    my $self = shift;
    return "<pre><code>" . $self->emit_kids( encode => 'verbatim_text', @_ )
         . "</code></pre>\n\n";
}

sub emit_italics     { shift->emit_tagged_kids( 'em',     @_ ) }
sub emit_code        { shift->emit_tagged_kids( 'code',   @_ ) }
sub emit_bold        { shift->emit_tagged_kids( 'strong', @_ ) }
sub emit_superscript { shift->emit_tagged_kids( 'sup',    @_ ) }
sub emit_subscript   { shift->emit_tagged_kids( 'sub',    @_ ) }
sub emit_file        { shift->emit_tagged_kids( 'em',     @_ ) }

sub emit_tagged_kids
{
    my ($self, $tag, %args) = @_;
    my $kids          = $self->emit_kids( encode => 'verbatim_text', %args );
    $args{encode}   ||= '';

    return $kids if $args{encode} =~ /^(index_|id$)/;
    return qq|<$tag>$kids</$tag>|;
}

sub emit_footnote
{
    my $self = shift;
    return ' <span class="footnote">' . $self->emit_kids . '</span>';
}

sub emit_url
{
    my $self = shift;
    my $url  = $self->emit_kids;
    return qq|<a class="url" href="$url">$url</a>|;
}

sub emit_link
{
    my $self                 = shift;
    my $anchor               = $self->emit_kids;

    my ($file, $frag, $text) = $self->get_link_for_anchor( $anchor );
    return qq|<a href="$file#$frag">$text</a>|;
}

use constant { BEFORE => 0, AFTER => 1 };

my %block_items =
(
    programlisting => [ qq|<div class="programlisting">\n\n|, q|</div>| ],
    sidebar        => [ qq|<div class="sidebar">\n\n|,        q|</div>| ],
    epigraph       => [ qq|<div class="epigraph">\n\n|,       q|</div>| ],
    blockquote     => [ qq|<div class="blockquote">\n\n|,     q|</div>| ],
);

while (my ($tag, $values) = each %block_items)
{
    my $sub = sub
    {
        my $self  = shift;
        my $title = $self->title;
        my $env   = $self->emit_environments;

        return $self->make_basic_block( $env->{$tag}, $title, @_ )
            if exists $env->{$tag};

        # deal with title somehow
        return $values->[BEFORE]
             . $self->make_block_title( $title )
             . $self->emit_kids . $values->[AFTER]
             . "\n\n";
    };

    do { no strict 'refs'; *{ 'emit_' . $tag } = $sub };
}

my %invisibles = map { $_ => 1 } qw( index anchor );

sub emit_paragraph
{
    my $self             = shift;
    my @kids             = @{ $self->children };
    my $has_visible_text = grep { ! exists $invisibles{ $_->type } } @kids;
    return $self->emit_kids( @_ ) unless $has_visible_text;

    my $attrs = @kids && $kids[0]->type =~ /^(?:anchor|index)$/
              ? $self->get_anchored_paragraph_attrs( shift @kids )
              : '';

    # inlined emit_kids() here to reflect any anchor manipulation
    my $content          = join '', map { $_->emit( @_ ) } @kids;
    return "<p$attrs>" . $content . qq|</p>\n\n|;
}

sub get_anchored_paragraph_attrs
{
    my ($self, $tag) = @_;
    my $type         = $tag->type;

    if ($type eq 'anchor')
    {
        my $content = $tag->get_anchor;
        return qq| id="$content"|;
    }
    elsif ($type eq 'index')
    {
        my $content = $tag->get_anchor . $tag->id;
        return qq| id="$content"|;
    }
}

my %parent_items =
(
    text_list      => [ qq|<ul>\n\n|,                         q|</ul>|  ],
    bullet_list    => [ qq|<ul>\n\n|,                         q|</ul>|  ],
    bullet_item    => [ qq|<li>|,                             q|</li>|  ],
    number_list    => [ qq|<ol>\n\n|,                         q|</ol>|  ],
);

while (my ($tag, $values) = each %parent_items)
{
    my $sub = sub
    {
        my $self = shift;
        return $values->[BEFORE] . $self->emit_kids( @_ ) . $values->[AFTER]
                                 . "\n\n";
    };

    do { no strict 'refs'; *{ 'emit_' . $tag } = $sub };
}

sub emit_block
{
    my $self   = shift;
    my $title  = $self->title ? $self->title->emit_kids : '';
    my $target = $self->target;

    if (my $environment = $self->emit_environments->{$target})
    {
        $target = $environment;
    }
    elsif (my $meth = $self->can( 'emit_' . $target))
    {
        return $self->$meth( @_ );
    }

    return $self->make_basic_block( $self->target, $title, @_ );
}

sub emit_html
{
    my $self = shift;
    return $self->emit_kids( encode => 'none' );
}

sub make_basic_block
{
    my ($self, $target, $title, @rest) = @_;

    $title = $self->make_block_title( $title );

    return qq|<div class="$target">\n$title|
         . $self->emit_kids( @rest )
         . qq|</div>|;
}

sub make_block_title
{
    my ($self, $title) = @_;

    return '' unless defined $title and length $title;
    return qq|<p class="title">$title</p>\n|;
}

sub emit_index
{
    my $self    = shift;
    my $content = $self->get_anchor;
    $content   .= $self->id if $self->type eq 'index';

    return qq|<a name="$content"></a>|;
}

sub emit_index_link
{
    my $self  = shift;
    my $id    = $self->id;
    my $frag  = $self->get_anchor . $id;
    my $file  = $self->link;
    return qq|<a href="$file#$frag">$id</a>|;
}

sub emit_table
{
    my $self    = shift;
    my $title   = $self->title ? $self->title->emit_kids : '';

    my $content = qq|<table>\n|;
    $content   .= qq|<caption>$title</caption>\n| if $title;
    $content   .= $self->emit_kids;
    $content   .= qq|</table>\n\n|;

    return $content;
}

sub emit_headrow
{
    my $self = shift;

    # kids should be cells
    my $content = '<tr>';

    for my $kid (@{ $self->children })
    {
        $content .= '<th>' . $kid->emit_kids . '</th>';
    }

    return $content . "</tr>\n";
}

sub emit_row
{
    my $self = shift;

    return '<tr>' . $self->emit_kids . qq|</tr>\n|;
}

sub emit_cell
{
    my $self = shift;
    return '<td>' . $self->emit_kids . qq|</td>\n|;
}

sub emit_figure
{
    my $self    = shift;
    my $caption = $self->caption;
    my $anchor  = $self->anchor;
    my $id      = defined $anchor ? ' id="' . $anchor->get_anchor . '"' : '';
    my $file    = $self->file->emit_kids;
    my $content = qq|<p$id>|;

    $content   .= $anchor if $anchor;
    $content   .= qq|<img src="$file" />|;
    $content   .= qq|<br />\n<em>$caption</em>| if $caption;
    $content   .= qq|</p>\n\n|;

    return $content;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::PseudoPod::DOM::Role::HTML - an HTML formatter role for PseudoPod DOM trees

=head1 VERSION

version 1.20210620.2040

=head1 AUTHOR

chromatic <chromatic@wgz.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by chromatic.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

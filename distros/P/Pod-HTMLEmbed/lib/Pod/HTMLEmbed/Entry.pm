package Pod::HTMLEmbed::Entry;
use Any::Moose;

use Carp::Clan '^(Mo[ou]se::|Pod::HTMLEmbed(::)?)';
use Pod::Simple::XHTML;
use HTML::TreeBuilder;
use URI::Escape ();
use HTML::Entities ();
use List::Util qw/min/;

has file => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has [qw/name title body toc/] => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

has _tree => (
    is         => 'ro',
    isa        => 'HTML::TreeBuilder',
    lazy_build => 1,
);

has _context => (
    is       => 'ro',
    isa      => 'Pod::HTMLEmbed',
    required => 1,
    handles  => ['url_prefix', 'has_url_prefix'],
);

no Any::Moose;

sub sections {
    my $self = shift;
    map { $_->content_list } $self->_tree->find('h2');
}

sub section {
    my ($self, $section_name) = @_;
    croak 'section_name is required' unless $section_name;

    my $section = $self->_tree->look_down(
        _tag => 'h2',
        sub { $_[0]->content->[0] eq $section_name },
    );

    my $content = q[];
    while ($section and $section = $section->right and $section->tag ne 'h2') {
        $content .= $section->as_XML . "\n";
    }

    $content;
}

sub DEMOLISH {
    my $self = shift;

    if ($self->_has_tree) {
        $self->_tree->delete;
    }
}

sub _build_name {
    my $self = shift;

    (my $name = $self->section('NAME')) =~ s/\s*-.*$//s;
    $name =~ s/<.*?>//gs;
    $name;
}

sub _build_title {
    my $self = shift;

    my ($title) = $self->section('NAME') =~ / - (.*)/ or return '';
    $title =~ s/<.*?>//g;
    $title;
}

sub _build_body {
    my $self = shift;

    my $body = q[];
    for my $content ($self->_tree->find('body')->content_list) {
        $body .= $content->as_XML . "\n";
    }
    $body;
}

sub _build_toc {
    my $self = shift;

    my $toc = '<ul>';

    for my $section ($self->sections) {
        $toc .= '<li>' . $self->_section_link($section);
        $toc .= $self->_toc_in_section($section);
        $toc .= '</li>';
    }
    $toc .= '</ul>';

    $toc;
}

sub _section_link {
    my ($self, $section) = @_;

    unless (ref $section) {
        $section = $self->_tree->look_down(
            _tag => 'h2', sub { $_[0]->content->[0] eq $section },
        ) or return;
    }

    my $text = HTML::Entities::encode_entities($section->as_trimmed_text, '<>&"');
    my $escaped_text = URI::Escape::uri_escape($section->as_trimmed_text);

    return join '', '<a href="#', $escaped_text, '">', $text, '</a>';
}

sub _toc_in_section {
    my ($self, $section_name) = @_;

    my $section = $self->_tree->look_down(
        _tag => 'h2',
        sub { $_[0]->content->[0] eq $section_name },
    ) or return;

    my $toc = q[];
    my $num = 2;

    while ($section and $section = $section->right and $section->tag ne 'h2') {
        next unless $section->tag =~ /^h[2-6]$/;
        my ($n) = $section->tag =~ /(\d)/;

        if ($num < $n) {
            $toc .= join '', '<ul><li>', $self->_section_link($section);
        }
        elsif ($num == $n) {
            $toc .= join '', '</li><li>', $self->_section_link($section);
        }
        else {
            $toc .= join '', '</li></ul></li><li>', $self->_section_link($section);
        }

        $num = $n;
    }
    return '' unless $toc;

    $toc .= '</li></ul>' while $num-- > 2;
    $toc;
}

sub _build__tree {
    my $self = shift;

    my $html = $self->_parse_pod($self->file);

    my $tree = HTML::TreeBuilder->new;
    $tree->parse_content( $html );

    # remove white spaces in codeblocks
    my @codes = $tree->look_down( _tag => 'code', sub { $_[0]->parent->tag eq 'pre' } );
    $self->_strip_tree($_) for @codes;

    # remove first num strings in <ol> tag
    my @list = $tree->look_down( _tag => 'li', sub { $_[0]->parent->tag eq 'ol' } );
    for my $li (@list) {
        my $first_child = shift @{ $li->content_array_ref } or next;
        $first_child =~ s/^\d+\.\s+// unless ref $first_child;
        $li->unshift_content($first_child);
    }

    # remove first <p> from lists
    @list = $tree->look_down( _tag => 'li' );
    for my $li (@list) {
        my @children = $li->content_list;
        my $num_element = grep { ref $_ } @children;

        if (1 == $num_element and my $p = $children[0] and $children[0]->tag eq 'p') {
            $p->replace_with_content;
        }
    }

    # shift header level, and add id attr
    my @header = $tree->look_down( _tag => qr/^h[1-5]$/ );
    for my $header (@header) {
        my ($n) = $header->tag =~ /(\d)/;
        $header->tag( 'h' . ++$n );
        $header->attr( id => $header->as_trimmed_text );
    }

    $tree;
}

sub _parse_pod {
    my ($self, $file) = @_;

    my $p = Pod::Simple::XHTML->new;
    $p->html_header('');
    $p->html_footer('');

    $p->output_string(\my $html);
    $p->perldoc_url_prefix( $self->url_prefix ) if $self->has_url_prefix;

    $p->parse_file($file)
        or croak "Pod parse error: $!";

    $html;
}

sub _strip_tree {
    my ($self, $code) = @_;
    my $stripped = _strip($code->content_list);
    $stripped .= "\n" unless $stripped =~ /\n$/;

    $code->delete_content;
    $code->push_content($stripped);
}

# copy from String::TT::strip
sub _strip($){
    my $lines = shift;

    my $trailing_newline = ($lines =~ /\n$/s);# perl silently throws away data
    my @lines = split "\n", $lines;
    shift @lines if $lines[0] eq ''; # strip empty leading line

    # determine indentation level
    my @spaces = map { /^(\040+)/ and length $1 or 0 } grep { !/^\s*$/ } @lines;

    my $indentation_level = min(@spaces);

    # strip off $indentation_level spaces
    my $stripped = join "\n", map { 
        my $copy = $_;
        substr($copy,0,$indentation_level) = "";
        $copy;
    } @lines;

    $stripped .= "\n" if $trailing_newline;
    return $stripped;
}

__PACKAGE__->meta->make_immutable;

__END__

=for stopwords toc html

=head1 NAME

Pod::HTMLEmbed::Entry - pod file object for Pod::HTMLEmbed

=head1 SYNOPSIS

    use Pod::HTMLEmbed;
    
    my $pod = Pod::HTMLEmbed->new->find('Moose');
    
    $pod->name;  # => 'Moose'
    $pod->title; # => 'A postmodern object system for Perl 5'
    
    $pod->section('SYNOPSIS'); # => html for Moose's SYNOPSIS
    $pod->sections;            # => Moose's pod section list: NAME, SYNOPSIS, DESCRIPTION...
    
    $pod->toc; # html for "Table of contents"

=head1 METHODS

=head2 file

Return pod file path.

=head2 name

Return pod name. This is generated by NAME section.

For example,

    =head1 NAME
    
    Pod::HTMLEmbed - Make clean html snippets from POD

This documents C<name> is C<Pod::HTMLEmbed>. And C<Make clean html snippets from POD> is C<title> showed below.

=head2 title

Return pod title.

=head2 body

Return whole html. See C<section> method showed below for section based html.

=head2 sections

Return list of sections. (Array of head1 contents)

=head2 section($section_name)

Return section based html.

For example:

    $pod->section('SYNOPSIS');

=head2 toc

Return "table of contents" html.

=head1 SEE ALSO

L<Pod::HTMLEmbed>.

=head1 AUTHOR

Daisuke Murase C<typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut


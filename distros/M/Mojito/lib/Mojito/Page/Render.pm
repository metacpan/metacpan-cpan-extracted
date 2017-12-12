use strictures 1;
package Mojito::Page::Render;
$Mojito::Page::Render::VERSION = '0.25';
use 5.010;
use Moo;
use Mojito::Template;
use Mojito::Filter::MojoMojo::Converter;
use Text::Textile;
use Text::MultiMarkdown;
use Text::WikiCreole;
use Pod::Simple::XHTML;
use HTML::Strip;
use Data::Dumper::Concise;

with('Mojito::Filter::Shortcuts');
with('Mojito::Role::Config');

=head1 Name

Mojito::Page::Render - turn a parsed page into html

=cut

has tmpl => (
    is => 'ro',
    lazy => 1,
    # pass the config
    'default' => sub { Mojito::Template->new(config => shift->config) },
);
has textile => (
    is => 'ro',
    lazy => 1,
    'default' => sub { Text::Textile->new },
);
has markdown => (
    is => 'ro',
    lazy => 1,
    'default' => sub { return Text::MultiMarkdown->new }
);

has base_url => ( is => 'rw', );

has 'stripper' => (
    is => 'ro',

    # isa  => 'HTML::Strip';
    lazy    => 1,
    builder => '_build_stripper',
);

has 'to_format' => (
    is => 'rw',
    'default' => sub { 'HTML' },
);

=head2 render_sections

Turn the sections into something viewable in a HTML browser.
Be mindful of the section class which we'll use for formatting purposes.

=cut

sub render_sections {
    my ( $self, $doc ) = @_;

    my ( @formatted_document_sections );
    foreach my $section ( @{ $doc->{sections} } ) {
        push @formatted_document_sections, $self->render_section($section, $doc->{default_format});
    }

    return \@formatted_document_sections;
}

sub render_section {
    my ($self, $section, $default_format) = @_;
    
    # The class of section is used to determine what the source code format is for the section.
    # We want to use this knowledge when we render to HTML.
    my $from_format = ($section->{class} && ($section->{class} ne 'Implicit'))
                        ? $section->{class} 
                        : $default_format;
    return $self->render_content( $section->{content}, $from_format, $self->to_format );
}

=head2 render_page

Make a page for viewing in the browser.

=cut

sub render_page {
    my ( $self, $doc ) = @_;

    return 'page is not available' if !$doc;
    # Give the tmpl object a base url first before asking for the html template.
    my $base_url = $self->base_url;
    $self->tmpl->base_url($base_url);
    # Give the template a page id if it exists
    $self->tmpl->page_id($doc->{'_id'});
    my $page = $self->tmpl->template;

    if (my $title = $doc->{title}) {
       $page =~ s/<title>.*?<\/title>/<title>${title}<\/title>/si;
    }

    my $rendered_body = $self->render_body($doc);
    # Remove edit area
    $page =~ s/(<section id="edit_area"[^>]*>).*?(<\/section>)//si;
    # Insert rendered page into view area
    $page =~ s/(<section id="view_area"[^>]*>).*?(<\/section>)/$1${rendered_body}$2/si;

    if ( my $id = $doc->{'_id'}||$doc->{id} ) {
        $page =~ s/(<nav id="edit_link"[^>]*>).*?(<\/nav>)/$1<a href="${base_url}page\/${id}\/edit">Edit<\/a>$2/sig;
    }

    return $page;
}

=head2 render_body

Turn the raw into something distilled.
TODO: Do we really need to return two things when only one is used?

=cut

sub render_body {
    my ( $self, $doc ) = @_;

    my $rendered_sections = $self->render_sections($doc);
    my $rendered_body = join "\n", @{$rendered_sections};

    $rendered_body = $self->expand_shortcuts($rendered_body);
    # Convert MojoMojo content if needed
    if ($self->config->{convert_mojomojo}) {
       $rendered_body = Mojito::Filter::MojoMojo::Converter->new( content => $rendered_body )->convert_content;
    }
    return $rendered_body;
}

=head2 render_content

Given some $content, a source and target format, convert the source to the target.
Example: textile => HTML

=cut

sub render_content {
    my ( $self, $content, $from_format, $to_format ) = @_;
   
    if ( !$content ) { die "Error: no content going from: $from_format to: $to_format"; }
    my $formatted_content;
    
    # TODO: This should be a dispatch table
    # In addition to HTML we'd like epub and PDF outputs
    if ( $to_format eq 'HTML' ) {
        $formatted_content = $self->format_for_web( $content, $from_format );
    }

    return $formatted_content; 
}

=head2 format_for_web

Given some content and its format, let's convert it to HTML.

=cut

sub format_for_web {
    my ( $self, $content, $from_language ) = @_;

    # smartmatch throws warnings on 5.18.0+, suppress them
    no if $] >= 5.018000, warnings => qw(experimental::smartmatch); 
    my $formatted_content = $content;
    given ($from_language) {
        when (/^HTML$/i) {
            # pass HTML through as is
        }

        when (/^POD$/i) {
            $formatted_content = $self->pod2html($content);
        }
        when (/^textile$/i) {
            $formatted_content = $self->textile->process($content);
        }
        when (/^markdown$/i) {
            $formatted_content = $self->markdown->markdown($content);
        }
        when (/^creole$/i) {
            $formatted_content = creole_parse($content);
        }

        when (/^h$/i) {

            # Let's do some highlighting
            $formatted_content = "<pre class='prettyprint'>${content}</pre>";
        }
        # More highlighting - language specific
        when (/^perl$/i) {
            $formatted_content = "<pre class='sh_perl'>$content</pre>";
        }
        when (/^js$/i) {
            $formatted_content = "<pre class='sh_javascript'>$content</pre>";
        }
        when (/^css$/i) {
            $formatted_content = "<pre class='sh_css'>$content</pre>";
        }
        when (/^sql$/i) {
            $formatted_content = "<pre class='sh_sql'>$content</pre>";
        }
        when (/^sh$/i) {
            $formatted_content = "<pre class='sh_sh'>$content</pre>";
        }
        when (/^diff$/i) {
            $formatted_content = "<pre class='sh_diff'>$content</pre>";
        }
        when (/^(haskell|hs)$/i) {
            $formatted_content = "<pre class='sh_haskell'>$content</pre>";
        }
        when (/^sh_html$/i) {
            $formatted_content = "<pre class='sh_html'>$content</pre>";
        }
        when (/^note$/i) {
            $formatted_content = "<div class='note'>$content</div>";
        }
        default {
            # pass HTML through as is
        }
    }
    return $formatted_content;
}

=head2 pod2html

Turn POD into HTML

=cut

sub pod2html {
    my ( $self, $content ) = @_;

    my $converter = Pod::Simple::XHTML->new;

    # We just want the body content
    $converter->html_header('');
    $converter->html_footer('');
    $converter->output_string( \my $html );
    $converter->parse_string_document($content);

    return $html;
}

=head2 intro_text

Extract the beginning text substring.

=cut

sub intro_text {
    my ( $self, $html ) = @_;

    my $title_length_limit = 64;
    my ($title) = $html =~ m/(.*)?\n?/;
    return '' if !$title;
    $title = $self->stripper->parse($title);
    if (length($title) > $title_length_limit) {
        my @words = split /\s+/, $title;
        my @title_words;
        my $title_length = 0;
        foreach my $word (@words) {
            if ($title_length + length($word) <= $title_length_limit) {
              push @title_words, $word;
              $title_length += length($word);
            }
            else {
              last;
            }
        }
        $title = join ' ', @title_words;
        $title .= ' ...';
    }

    return $title;
}

sub _build_stripper {
    my $self = shift;

    return HTML::Strip->new();
}

1;

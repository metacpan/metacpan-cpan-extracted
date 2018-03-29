package Statocles::Document;
our $VERSION = '0.091';
# ABSTRACT: Base class for all Statocles documents

use Statocles::Base 'Class';
with 'Statocles::Role::PageAttrs';
use Statocles::Image;
use Statocles::Util qw( derp );
use YAML ();
use JSON::PP qw( decode_json );

#pod =attr path
#pod
#pod The path to this document. This is not settable from the frontmatter.
#pod
#pod =cut

has path => (
    is => 'rw',
    isa => PagePath,
    coerce => PagePath->coercion,
);

#pod =attr store
#pod
#pod The Store this document comes from. This is not settable from the
#pod frontmatter.
#pod
#pod =cut

has store => (
    is => 'ro',
    isa => Store,
    coerce => Store->coercion,
);

#pod =attr title
#pod
#pod     ---
#pod     title: My First Post
#pod     ---
#pod
#pod The title of this document. Used in the template and the main page
#pod title. Any unsafe characters in the title (C<E<lt>>, C<E<gt>>, C<">, and
#pod C<&>) will be escaped by the template, so no HTML allowed.
#pod
#pod =cut

#pod =attr author
#pod
#pod     ---
#pod     author: preaction <doug@example.com>
#pod     ---
#pod
#pod The author of this document. Optional. Either a simple string containing
#pod the author's name and optionally, in E<gt>E<lt>, the author's e-mail address,
#pod or a hashref of L<Statocles::Person attributes|Statocles::Person/ATTRIBUTES>.
#pod
#pod     ---
#pod     # Using Statocles::Person attributes
#pod     author:
#pod         name: Doug Bell
#pod         email: doug@example.com
#pod     ---
#pod
#pod =cut

sub _build_author { }

#pod =attr status
#pod
#pod The publishing status of this document.  Optional. Statocles apps can
#pod examine this to determine whether to turn a document into a page.  The
#pod default value is C<published>; other reasonable values could include
#pod C<draft> or C<private>.
#pod
#pod =cut

has status => (
    is => 'rw',
    isa => Str,
    default => 'published',
);

#pod =attr content
#pod
#pod The raw content of this document, in markdown. This is everything below
#pod the ending C<---> of the frontmatter.
#pod
#pod =cut

has content => (
    is => 'rw',
    isa => Str,
);

#pod =attr tags
#pod
#pod     ---
#pod     tags: recipe, beef, cheese
#pod     tags:
#pod         - recipe
#pod         - beef
#pod         - cheese
#pod     ---
#pod
#pod The tags for this document. Tags are used to categorize documents.
#pod
#pod Tags may be specified as an array or as a comma-separated string of
#pod tags.
#pod
#pod =cut

has tags => (
    is => 'rw',
    isa => ArrayRef,
    default => sub { [] },
    coerce => sub {
        return [] unless $_[0];
        if ( !ref $_[0] ) {
            return [ split /\s*,\s*/, $_[0] ];
        }
        return $_[0];
    },
);

#pod =attr links
#pod
#pod     ---
#pod     links:
#pod         stylesheet:
#pod             - href: /theme/css/extra.css
#pod         alternate:
#pod             - href: http://example.com/blog/alternate
#pod               title: A contributed blog
#pod     ---
#pod
#pod Related links for this document. Links are used to build relationships
#pod to other web addresses. Link categories are named based on their
#pod relationship. Some possible categories are:
#pod
#pod =over 4
#pod
#pod =item stylesheet
#pod
#pod Additional stylesheets for the content of this document.
#pod
#pod =item script
#pod
#pod Additional scripts for the content of this document.
#pod
#pod =item alternate
#pod
#pod A link to the same document in another format or posted to another web site
#pod
#pod =back
#pod
#pod Each category contains an arrayref of hashrefs of L<link objects|Statocles::Link>.
#pod See the L<Statocles::Link|Statocles::Link> documentation for a full list of
#pod supported attributes. The most common attributes are:
#pod
#pod =over 4
#pod
#pod =item href
#pod
#pod The URL for the link.
#pod
#pod =item text
#pod
#pod The text of the link. Not needed for stylesheet or script links.
#pod
#pod =back
#pod
#pod =cut

#pod =attr images
#pod
#pod     ---
#pod     images:
#pod         title:
#pod             src: title.jpg
#pod             alt: A title image for this post
#pod         banner: banner.jpg
#pod     ---
#pod
#pod Related images for this document. These are used by themes to display
#pod images in appropriate templates. Each image has a category, like C<title>,
#pod C<banner>, or C<thumbnail>, mapped to an L<image object|Statocles::Image>.
#pod See the L<Statocles::Image|Statocles::Image> documentation for a full
#pod list of supported attributes. The most common attributes are:
#pod
#pod =over 4
#pod
#pod =item src
#pod
#pod The source path of the image. Relative paths will be resolved relative
#pod to this document.
#pod
#pod =item alt
#pod
#pod The alternative text to display if the image cannot be downloaded or
#pod rendered. Also the text to use for non-visual media.
#pod
#pod =back
#pod
#pod =cut

#pod =attr date
#pod
#pod     ---
#pod     date: 2015-03-27
#pod     date: 2015-03-27 12:04:00
#pod     ---
#pod
#pod The date/time this document is for. For pages, this is the last modified date.
#pod For blog posts, this is the post's date.
#pod
#pod Should be in C<YYYY-MM-DD> or C<YYYY-MM-DD HH:MM:SS> format.
#pod
#pod =cut

has date => (
    is => 'rw',
    isa => DateTimeObj,
    coerce => DateTimeObj->coercion,
    predicate => 'has_date',
);

#pod =attr template
#pod
#pod     ---
#pod     template: /blog/recipe.html
#pod     ---
#pod
#pod The path to a template override for this document. If set, the L<document
#pod page|Statocles::Page::Document> will use this instead of the template provided
#pod by the application.
#pod
#pod The template path should not have the final extention (by default C<.ep>).
#pod Different template parsers will have different extentions.
#pod
#pod =cut

has template => (
    is => 'rw',
    isa => Maybe[ArrayRef[Str]],
    coerce => sub {
        return $_[0] if ref $_[0];
        return [ grep { $_ ne '' } split m{/}, $_[0] ];
    },
    predicate => 'has_template',
);

#pod =attr layout
#pod
#pod     ---
#pod     layout: /site/layout-dark.html
#pod     ---
#pod
#pod The path to a layout template override for this document. If set, the L<document
#pod page|Statocles::Page::Document> will use this instead of the layout provided
#pod by the application.
#pod
#pod The template path should not have the final extention (by default C<.ep>).
#pod Different template parsers will have different extentions.
#pod
#pod =cut

has layout => (
    is => 'rw',
    isa => Maybe[ArrayRef[Str]],
    coerce => sub {
        return $_[0] if ref $_[0];
        return [ grep { $_ ne '' } split m{/}, $_[0] ];
    },
    predicate => 'has_layout',
);

#pod =attr data
#pod
#pod     ---
#pod     data:
#pod       ingredients:
#pod         - Eggs
#pod         - Milk
#pod         - Cheese
#pod     ---
#pod     % for my $item ( @{ $self->data->{ingredients} } ) {
#pod         <%= $item %>
#pod     % }
#pod
#pod A hash of extra data to attach to this document. This is available
#pod immediately in the document content, and later in the page template.
#pod
#pod Every document's content is parsed as a template. The C<data> attribute can be
#pod used in the template to allow for some structured data that would be cumbersome
#pod to have to mark up time and again.
#pod
#pod =cut

has data => (
    is => 'rw',
);

#pod =attr disable_content_template
#pod
#pod     ---
#pod     disable_content_template: true
#pod     ---
#pod
#pod This disables processing the content as a template. This can speed up processing
#pod when the content is not using template directives. 
#pod
#pod This can be also set in the application
#pod (L<Statocles::App/disable_content_template>), or for the entire site
#pod (L<Statocles::Site/disable_content_template>).
#pod
#pod =cut

has disable_content_template => (
    is => 'ro',
    isa => Bool,
    lazy => 1,
    default => 0,
    predicate => 'has_disable_content_template',
);

around BUILDARGS => sub {
    my ( $orig, $self, @args ) = @_;
    my $args = $self->$orig( @args );
    if ( defined $args->{data} && ref $args->{data} ne 'HASH' ) {
        derp qq{Invalid data attribute in document "%s". Data attributes that are not hashes are deprecated and will be removed in v2.0. Please use a hash instead.},
            $args->{path};
    }
    return $args;
};

#pod =method parse_content
#pod
#pod     my $doc = $class->parse_content(
#pod         path => $path,
#pod         store => $store,
#pod         content => $content,
#pod     );
#pod
#pod Construct a document the given content, with the given additional
#pod attributes. Returns a new C<Statocles::Document> object.
#pod
#pod This parses the YAML or JSON frontmatter into the document's attributes,
#pod putting the rest of the file after the YAML or JSON frontmatter in the
#pod C<content> attribute.
#pod
#pod Custom document classes can override this method to change how file content is
#pod parsed.
#pod
#pod =cut

sub parse_content {
    my ( $class, %args ) = @_;

    my %doc;
    my $content = delete $args{content} or die "Content is required";

    my @lines = split /\n/, $content;
    # YAML frontmatter
    if ( @lines && $lines[0] =~ /^---/ ) {
        shift @lines;

        # The next --- is the end of the YAML frontmatter
        my ( $i ) = grep { $lines[ $_ ] =~ /^---/ } 0..$#lines;

        # If we did not find the marker between YAML and Markdown
        if ( !defined $i ) {
            die qq{Could not find end of YAML front matter (---)\n};
        }

        # Before the marker is YAML
        eval {
            %doc = %{ YAML::Load( join "\n", splice( @lines, 0, $i ), "" ) };
        };
        if ( $@ ) {
            die qq{Error parsing YAML in "$args{path}"\n$@};
        }

        # Remove the last '---' mark
        shift @lines;
    }
    # JSON frontmatter
    elsif ( @lines && $lines[0] =~ /^{/ ) {
        my $json;
        if ( $lines[0] =~ /\}$/ ) {
            # The JSON is all on a single line
            $json = shift @lines;
        }
        else {
            # The } on a line by itself is the last line of JSON
            my ( $i ) = grep { $lines[ $_ ] =~ /^}$/ } 0..$#lines;
            # If we did not find the marker between YAML and Markdown
            if ( !defined $i ) {
                die qq{Could not find end of JSON front matter (\})\n};
            }
            $json = join "\n", splice( @lines, 0, $i+1 );
        }
        eval {
            %doc = %{ decode_json( $json ) };
        };
        if ( $@ ) {
            die qq{Error parsing JSON: $@\n};
        }
    }

    # The remaining lines are content
    $doc{content} = join "\n", @lines, "";

    delete $doc{path};
    delete $doc{store};

    return $class->new( %doc, %args );
}

#pod =method deparse_content
#pod
#pod     my $content = $doc->deparse_content;
#pod
#pod Deparse the document into a string ready to be stored in a file. This will
#pod serialize the document attributes into YAML frontmatter, and place the content
#pod after.
#pod
#pod =cut

sub deparse_content {
    my ( $self ) = @_;
    my %data = %$self;
    delete $data{ store };
    delete $data{ path };
    my $content = delete $data{content};

    # Serialize date correctly
    if ( exists $data{date} ) {
        $data{date} = $data{date}->strftime('%Y-%m-%d %H:%M:%S');
    }

    # Don't save empty references
    for my $hash_type ( qw( links images ) ) {
        if ( exists $data{ $hash_type } && !keys %{ $data{ $hash_type } } ) {
            delete $data{ $hash_type };
        }
    }
    for my $array_type ( qw( tags ) ) {
        if ( exists $data{ $array_type } && !@{ $data{ $array_type } } ) {
            delete $data{ $array_type };
        }
    }

    return YAML::Dump( \%data ) . "---\n". $content;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Document - Base class for all Statocles documents

=head1 VERSION

version 0.091

=head1 DESCRIPTION

A Statocles::Document is the base unit of content in Statocles.
L<Applications|Statocles::App> take documents to build
L<pages|Statocles::Page>.

Documents are usually written as files, with the L<content|/content> in Markdown,
and the other attributes as frontmatter, a block of YAML at the top of the file.

An example file with frontmatter looks like:

    ---
    title: My Blog Post
    author: preaction
    links:
        stylesheet:
            - href: /theme/css/extra.css
    ---
    In my younger and more vulnerable years, my father gave me some

=head1 ATTRIBUTES

=head2 path

The path to this document. This is not settable from the frontmatter.

=head2 store

The Store this document comes from. This is not settable from the
frontmatter.

=head2 title

    ---
    title: My First Post
    ---

The title of this document. Used in the template and the main page
title. Any unsafe characters in the title (C<E<lt>>, C<E<gt>>, C<">, and
C<&>) will be escaped by the template, so no HTML allowed.

=head2 author

    ---
    author: preaction <doug@example.com>
    ---

The author of this document. Optional. Either a simple string containing
the author's name and optionally, in E<gt>E<lt>, the author's e-mail address,
or a hashref of L<Statocles::Person attributes|Statocles::Person/ATTRIBUTES>.

    ---
    # Using Statocles::Person attributes
    author:
        name: Doug Bell
        email: doug@example.com
    ---

=head2 status

The publishing status of this document.  Optional. Statocles apps can
examine this to determine whether to turn a document into a page.  The
default value is C<published>; other reasonable values could include
C<draft> or C<private>.

=head2 content

The raw content of this document, in markdown. This is everything below
the ending C<---> of the frontmatter.

=head2 tags

    ---
    tags: recipe, beef, cheese
    tags:
        - recipe
        - beef
        - cheese
    ---

The tags for this document. Tags are used to categorize documents.

Tags may be specified as an array or as a comma-separated string of
tags.

=head2 links

    ---
    links:
        stylesheet:
            - href: /theme/css/extra.css
        alternate:
            - href: http://example.com/blog/alternate
              title: A contributed blog
    ---

Related links for this document. Links are used to build relationships
to other web addresses. Link categories are named based on their
relationship. Some possible categories are:

=over 4

=item stylesheet

Additional stylesheets for the content of this document.

=item script

Additional scripts for the content of this document.

=item alternate

A link to the same document in another format or posted to another web site

=back

Each category contains an arrayref of hashrefs of L<link objects|Statocles::Link>.
See the L<Statocles::Link|Statocles::Link> documentation for a full list of
supported attributes. The most common attributes are:

=over 4

=item href

The URL for the link.

=item text

The text of the link. Not needed for stylesheet or script links.

=back

=head2 images

    ---
    images:
        title:
            src: title.jpg
            alt: A title image for this post
        banner: banner.jpg
    ---

Related images for this document. These are used by themes to display
images in appropriate templates. Each image has a category, like C<title>,
C<banner>, or C<thumbnail>, mapped to an L<image object|Statocles::Image>.
See the L<Statocles::Image|Statocles::Image> documentation for a full
list of supported attributes. The most common attributes are:

=over 4

=item src

The source path of the image. Relative paths will be resolved relative
to this document.

=item alt

The alternative text to display if the image cannot be downloaded or
rendered. Also the text to use for non-visual media.

=back

=head2 date

    ---
    date: 2015-03-27
    date: 2015-03-27 12:04:00
    ---

The date/time this document is for. For pages, this is the last modified date.
For blog posts, this is the post's date.

Should be in C<YYYY-MM-DD> or C<YYYY-MM-DD HH:MM:SS> format.

=head2 template

    ---
    template: /blog/recipe.html
    ---

The path to a template override for this document. If set, the L<document
page|Statocles::Page::Document> will use this instead of the template provided
by the application.

The template path should not have the final extention (by default C<.ep>).
Different template parsers will have different extentions.

=head2 layout

    ---
    layout: /site/layout-dark.html
    ---

The path to a layout template override for this document. If set, the L<document
page|Statocles::Page::Document> will use this instead of the layout provided
by the application.

The template path should not have the final extention (by default C<.ep>).
Different template parsers will have different extentions.

=head2 data

    ---
    data:
      ingredients:
        - Eggs
        - Milk
        - Cheese
    ---
    % for my $item ( @{ $self->data->{ingredients} } ) {
        <%= $item %>
    % }

A hash of extra data to attach to this document. This is available
immediately in the document content, and later in the page template.

Every document's content is parsed as a template. The C<data> attribute can be
used in the template to allow for some structured data that would be cumbersome
to have to mark up time and again.

=head2 disable_content_template

    ---
    disable_content_template: true
    ---

This disables processing the content as a template. This can speed up processing
when the content is not using template directives. 

This can be also set in the application
(L<Statocles::App/disable_content_template>), or for the entire site
(L<Statocles::Site/disable_content_template>).

=head1 METHODS

=head2 parse_content

    my $doc = $class->parse_content(
        path => $path,
        store => $store,
        content => $content,
    );

Construct a document the given content, with the given additional
attributes. Returns a new C<Statocles::Document> object.

This parses the YAML or JSON frontmatter into the document's attributes,
putting the rest of the file after the YAML or JSON frontmatter in the
C<content> attribute.

Custom document classes can override this method to change how file content is
parsed.

=head2 deparse_content

    my $content = $doc->deparse_content;

Deparse the document into a string ready to be stored in a file. This will
serialize the document attributes into YAML frontmatter, and place the content
after.

=head1 SEE ALSO

=over 4

=item L<Statocles::Help::Content>

The content guide describes how to edit content in Statocles sites, which are
represented by Document objects.

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

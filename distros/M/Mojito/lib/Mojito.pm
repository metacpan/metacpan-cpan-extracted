use strictures 1;
package Mojito;
$Mojito::VERSION = '0.25';
use Moo;
use Path::Class;
use File::Spec;
use 5.010;
use Data::Dumper::Concise;

extends 'Mojito::Page';

=head1 NAME

Mojito - A Web Document System

=head1 SYNOPSIS

  use Mojito::Model::Config;
  my $mojito = Mojito->new(config => Mojito::Model::Config->new->config);
  my $page_id = '123456781234567812345678';
  my $rendered_page = $mojito->view_page({id => $page_id});

  # You might want to checkout one of the applications in app/
  # For example: 'plackup -Ilib' starts up a Web::Simple instance of Mojito

=head1 DESCRIPTION

Mojito is a web document system that enables individuals to easily author 
HTML5 compliant documents.  It provides a source editor for various
markup languages along with a near realtime view pane.  It allows for the
intermixing of different source formats.

=head1 Attributes

=head2 base_url

Base of the application used for creating internal links.

=cut

has base_url => ( is => 'rw', );

=head2 username

Authenticated (Digest Auth) user name (aka REMOTE_USER)

=cut

has username => (
    is => 'rw',
);

has bench_fixture => ( is => 'ro', lazy => 1, builder => '_build_bench_fixture');

=head1 Methods

=head2 create_page

Create a new page and return the url to redirect to, namely the page in edit mode.
We might change this to view mode if demand persuades.

=cut

sub create_page {
    my ( $self, $params ) = @_;

    # We need to get some content into the delegatee
    $self->parser->page($params->{content});

    my $page_struct = $self->page_structure;
    # Load some parts to the page_struct
    $page_struct->{default_format} = $params->{wiki_language};
    $page_struct->{page_html} = $self->render_page($page_struct);
    $page_struct->{body_html} = $self->render_body($page_struct);
    $page_struct->{title}     = $self->intro_text( $page_struct->{body_html} );
    if ($params->{public}) {
        $page_struct->{public} = 1;
    }
    my $id = $self->create($page_struct);
    $params->{id} = $id;
    # Put into repo
    $params->{username} = $self->username;
    $self->commit_page($page_struct, $params);

    return $self->base_url . 'page/' . $id . '/edit';
}

=head2 preview_page

AJAX preview of a page (parse and render, save when button pressed)

=cut

sub preview_page {
    my ( $self, $params ) = @_;

    $self->parser->page($params->{content});
    $self->parser->default_format($params->{wiki_language});
    my $page_struct = $self->page_structure;
    if (   $params->{extra_action}
        && ( $params->{extra_action} eq 'save' )
        && ( $params->{'mongo_id'} ) )
    {
        $page_struct->{page_html} = $self->render_page($page_struct);
        $page_struct->{body_html} = $self->render_body($page_struct);
        $page_struct->{title} = $self->intro_text( $page_struct->{body_html} );
        $self->update( $params->{'mongo_id'}, $page_struct );
    }
    elsif ( $params->{'mongo_id'} ) {

# Auto update this stuff so the user doesn't have to even think about clicking save button
# TODO: add title, page and body html to page_struct like above.
#       Do we even need these two branches given that we're autosaving now.
# TODO: on new page, insert to get an id then update to that from the start
        $page_struct->{title} = $params->{page_title}||'no title';
        $self->update( $params->{'mongo_id'}, $page_struct );
    }

    my $rendered_content = $self->render_body($page_struct);
    my $response_href = { rendered_content => $rendered_content, message => $page_struct->{message} };

    return $response_href;
}

=head2 update_page

Update a page given: content, id and base_url

=cut

sub update_page {
    my ( $self, $params ) = @_;

    $self->parser->page($params->{content});
    $self->parser->default_format($params->{wiki_language});
    my $page = $self->page_structure;

    # Store rendered parts as well.  May as well until proven wrong.
    $page->{page_html} = $self->render_page($page);
    $page->{body_html} = $self->render_body($page);
    $page->{title}     = $self->intro_text( $page->{body_html} );

    # Add a feed if there is such a param
    if (my $feeds = $params->{feeds}) {
        # Allow : to separate multiple feeds. e.g. ?feeds=ironman:chatterbox
        my @feeds = split ':', $feeds;
        $page->{feeds} = [@feeds];
        # A document that is part of a feed is considered public by default
        $page->{public} = 1;
    }
    if ($params->{public}) {
        $page->{public} = 1;
    }

    # Update the list of collections to which this doc belongs
    $self->collector->editer->update_collection_membership($params);

    # Save page to db
    $self->update( $params->{id}, $page );
    # Commit revison to git repo
    # add username to params so it can used in the commit
    $params->{username} = $self->username;
    $self->commit_page($page, $params);
    return $self->base_url . 'page/' . $params->{id};
}

=head2 edit_page_form

Present the form with a page ready to be edited.

=cut

sub edit_page_form {
    my ( $self, $params ) = @_;

    my $page             = $self->read( $params->{id} );
    my $rendered_content = $self->render_body($page);

    return $self->fillin_edit_page( $page, $rendered_content, $params->{id} );
}

=head2 view_page

Given a page id, we retrieve its page from the db and return
the HTML form of the page to the browser.

=cut

sub view_page {
    my ( $self, $params ) = @_;

    my $page          = $self->read( $params->{id} );
    my $rendered_page = $self->render_page($page);
    my $links         = $self->get_recent_links;
    my $collections   = $self->view_collections_index;

    # Change class on view_area when we're in view mode.
    $rendered_page =~ s/(<section\s+id="view_area").*?>/$1 class="view_area_view_mode">/si;
    # Fill-in recent area
    $rendered_page =~ s/(<section\s+id="recent_area".*?>)<\/section>/$1${links}<\/section>/si;
    # Fill-in collections area
    $rendered_page =~ s/(<section\s+id="collections_area".*?>)<\/section>/$1${collections}<\/section>/si;

    return $rendered_page;
}

=head2 view_page_public

Given a page id, we retrieve its page from the db and return
the HTML form of the page to the browser.  This method is much
like the view_page() method is setup for public pages
(ones that do not require authentication).

=cut

sub view_page_public {
    my ( $self, $params ) = @_;
    my $page          = $self->read( $params->{id} );
    return "Page is not public" if not $page->{public};
# TODO: Use body_html unless otherwise specified
#    return $self->wrap_page($page->{body_html}, $page->{title});
    return $self->wrap_page($self->render_body($page), $page->{title});
}

=head2 view_page_collected

Given a page id and a collection id we retrieve the collected page source
from the db and return it as an HTML rendered page to the browser.  This method 
is much like the view_page() method, but is setup for viewing pages in a collection
with a collection navigation: next, previous, index (toc)

=cut

sub view_page_collected {
    my ( $self, $params ) = @_;

    my $page          = $self->read( $params->{page_id} );
    my $rendered_page = $self->render_page($page);

    # Change class on view_area when we're in view mode.
    $rendered_page =~
      s/(<section\s+id="view_area").*?>/$1 class="view_area_view_mode">/si;

    # Strip out Edit and New links (even though they are Auth::Digest Protected)
    # Remove edit, new links and the recent area
    if(not $self->config->{username}) {
        $rendered_page =~ s/<nav id="edit_link".*?><\/nav>//sig;
    }
    $rendered_page =~ s/<nav id="new_link".*?>.*?<\/nav>//sig;
    $rendered_page =~ s/<section id="recent_area".*?><\/section>//si;
    $rendered_page =~ s/<section id="publish_area">.*?<\/section>//si;
    $rendered_page =~ s/<section id="collections_area"><\/section>//si;
    $rendered_page =~ s/<section id="search_area">.*?<\/section>//si;
    $rendered_page =~ s/<section id="calendar_area">.*?<\/section>//si;
    # Fill-in collection navigation area
    my $collection_nav = $self->view_collection_nav( $params );
    $rendered_page =~ s/(<section\s+id="collection_nav_area".*?>)<\/section>/$1${collection_nav}<\/section>/si;

    return $rendered_page;
}

=head2 view_home_page

Create the view for the base of the application.

=cut

sub view_home_page {
    my $self = shift;

    my $output = $self->home_page;
    my $links  = $self->get_recent_links;
    $output =~ s/(<section\s+id="recent_area".*?>)<\/section>/$1${links}<\/section>/si;

    return $output;
}

=head2 view_page_diff

View the diff of a page.

=cut

sub view_page_diff {
    my ( $self, $params ) = @_;

    my $head = '
<!doctype html>
<html>
<head>
  <meta charset=utf-8>
  <meta http-equiv="powered by" content="Mojito development version" />
  <title>Mojito Syntax Highlighting - via JavaScript</title>
<script src=http://missoula.org/mojito/jquery/jquery_min.js></script>
<script src=http://missoula.org/mojito/javascript/render_page.js></script>
<script src=http://missoula.org/mojito/javascript/style.js></script>
<script src=http://missoula.org/mojito/syntax_highlight/prettify.js></script>
<script src=http://missoula.org/mojito/jquery/autoresize_min.js></script>
<script src=http://missoula.org/mojito/jquery/jquery-ui-1.8.11.custom.min.js></script>
<script src=http://missoula.org/mojito/SHJS/sh_main.min.js></script>
<script src=http://missoula.org/mojito/SHJS/sh_diff.min.js></script>
<link href=http://missoula.org/mojito/css/ui-lightness/jquery-ui-1.8.11.custom.css type=text/css rel=stylesheet />
<link href=http://missoula.org/mojito/syntax_highlight/prettify.css type=text/css rel=stylesheet />
<link href=http://missoula.org/mojito/SHJS/sh_rand01.min.css type=text/css rel=stylesheet />
<link href=http://missoula.org/mojito/css/mojito.css type=text/css rel=stylesheet />

</head>
<body class="html_body">
';
    my $diff = '<pre class="sh_diff">' . "\n" . $self->diff_page($params->{id}, $params->{m}, $params->{n}) . "\n</pre>";
    my $foot = "\n</body></html>";
    return $head . $diff . $foot;
}

=head2 search

Search the documents for a single word.

=cut

sub search {
    my ( $self, $params ) = @_;

    my $base_url = $self->base_url;
    my $hit_hashref= $self->search_word($params->{word});
    if (not scalar keys %{$hit_hashref}) {
        my $output = "No matches for: <b>" . $params->{word} . "</b><br />&nbsp;\n";
        $output .= "<nav style='font-size:0.8em;'>Want a <a href='${base_url}page'>new page?</a></nav>";
        return $output; 
    }
    # Get the full page and extract the title for display.
    # Rework hit_has from HashRef to HashRef[HashRef] so we can store both hit counts and a title.
    my $link_data = {};
    foreach my $page_id (keys %{$hit_hashref}) {
        my $page = $self->read($page_id);
        $link_data->{$page_id}->{title} = $page->{title}||'no title';
        $link_data->{$page_id}->{times_found} = $hit_hashref->{$page_id};
    }
    my @search_hits = map { "<a href='${base_url}page/$_'>$link_data->{$_}->{title} <span style='font-size: 0.82em;'>($link_data->{$_}->{times_found})</span></a>" }
      sort {$link_data->{$b}->{times_found} <=> $link_data->{$a}->{times_found}} keys %{$link_data};
    return join "<br />\n", @search_hits;
}

=head2 collect

Collect documents.  The id for each document submitted will be put into
a list of document ids stored in the 'collection' collection.  Yeah, that
may seem strange at first, but the idea is we want to allow for arbitrary
sets of documents from the notes collection.  We construct these sets by creating
a list (array) of the corresponding document ids and inserting this "document"
into the "collection" collection.  

For example, the Beer collection document could look like:

    { 
        collection_name => 'Beer',
        documents       => [$some_doc_id, $another_doc_id, .. $last_doc_id]
        permissions     => { owner => 'rwx', group=> 'r', world => 'r' }
    }

where the doc ids are the usual mongodb auto-generated id.

Return the /collections URL to which we'll redirect.

=cut

sub collect {
    my ( $self, $params ) = @_;
    
    # Create page in DB
    $params->{id}= $self->collector->create($params);
   
    # Put into repo
    $params->{username} = $self->username;
    my $page_source = join "\n", @{$params->{collected_page_ids}};
    $page_source .= "\n";
    my $page_struct = { page_source => $page_source };
    $self->commit_page($page_struct, $params);

    return $self->base_url . 'collections';
}

=head2 sort_collection

Store a sorted list of pages. 
Return the /collections URL to which we'll redirect.

=cut

sub sort_collection {
    my ( $self, $params ) = @_;
    $self->collector->create($params);
    return $self->base_url . 'collections';
}

=head2 merge_collection

Given a collection id, we concatentate all its page into one.

=cut

sub merge_collection {
    my ( $self, $params ) = @_;

    use Mojito::Filter::MojoMojo::Converter;
    # Get the page ids for the collection.
    my $collection_struct = $self->collector->read($params->{collection_id});
    my @page_ids = @{$collection_struct->{collected_page_ids}};
    my $rendered_bodies;
    foreach my $page_id (@page_ids) {
        $rendered_bodies .= $self->render_body($self->read($page_id));
    }
    my $collection_title = $collection_struct->{collection_name};
    $collection_title = "<h1 class='collection_title'>$collection_title</h1>";
    my $toc = "\n{{toc 1-}}\n";
    $rendered_bodies =  $collection_title . $toc . $rendered_bodies;
    my $convert = Mojito::Filter::MojoMojo::Converter->new( content => $rendered_bodies );
    $convert->toc;

    return $self->wrap_page($convert->content, $collection_struct->{collection_name});
}

=head2 delete_collection

Given a collection id:
* Delete it from the mongo DB
Return the URL to of the collections index 

=cut

sub delete_collection {
    my ( $self, $params ) = @_;
    $self->collector->delete($params->{collection_id});
    return $self->base_url . 'collections';
}

=head2 epub_collection

Create and .epub document from the given collection.

=cut

sub epub_collection {
    my ($self, $params) = @_;
    
    my $authors = $self->get_author_for($params->{collection_id});

    my $collection_html = $self->merge_collection($params);
    # Strip out HTML::TOC
    $collection_html =~ s/<div class="toc">.*?<\/div>//sig;
    
    my $tmp_html_file = Path::Class::file(File::Spec->tmpdir, 'collection_' 
                                     . $params->{collection_id} 
                                     . '.html');
    open my $html_file, '>', $tmp_html_file or die "Can't open html file: $tmp_html_file";
    print $html_file $collection_html;
    close $html_file;

    my $tmp_epub_file = Path::Class::file(File::Spec->tmpdir, 'collection_' 
                                     . $params->{collection_id} 
                                     . '.epub');
    my $converter = $self->tmpl->config->{ebook_converter};
    
    # Check that we have a converter defined and that it exists on the file system.
    return if !($converter && -e $converter);
    # TODO Handle Exceptions
    `$converter $tmp_html_file $tmp_epub_file --authors "${authors}"  --level2-toc //h:h2 --level1-toc //h:h1 --extra-css ".html_body {background-color: white;}"`;
    open my $epub_file, '<', $tmp_epub_file or die "Can't open epub file: $tmp_epub_file";
    my $epub;
    while (<$epub_file>) {
        $epub .= $_;
    }
    return $epub;
}

=head2 delete_page

Given a page id:
* Delete it from the mongo DB
* Remove it from the git repo
Return the URL to recent (maybe home someday?)

=cut

sub delete_page {
    my ( $self, $params ) = @_;

    $self->delete($params->{id});
    $self->rm_page($params->{id});

    return $self->base_url . 'recent';
}

=head2 publish_page

Publish a page - Currently this means POST to a MM instance.

=cut

sub publish_page {
    my ( $self, $params ) = @_;
    
     my $doc = $self->read($params->{id});
     my $content = $doc->{page_source};
     $self->publisher->content($content);
     $self->publisher->target_base_url($params->{target_base_url});
     $self->publisher->target_page($params->{name});
     $self->publisher->user($params->{user});
     $self->publisher->password($params->{password});
     my $result = $self->publisher->publish;
     # return redirect location
     my $redirect_url =  $self->publisher->target_base_url .  $self->publisher->target_page;
     my $response_href = { redirect_url => $redirect_url, result => $result };
}

=head2 feed_page

Get a feed in a particular format

=cut

sub feed_page {
    my ( $self, $params ) = @_;
    my ($feed, $format) = @{$params}{qw/feed_name feed_format/};
    if ($format eq 'atom') {
        return $self->get_atom_feed($feed);
    }
    return;
}

=head2 bench

A path for benchmarking to get an basic idea of performance.

=cut

sub bench {
    my $self  = shift;

    $self->parser->page($self->bench_fixture);
    my $page_struct = $self->page_structure;

    # Let's run our bench stuff in its own DB to keep it separate from
    # real (user created) pages.
    $self->editer->db_name('bench');
    $self->create($page_struct);

    return $self->render_page($page_struct);
}

sub _build_bench_fixture {
    my $self = shift;

    my $implicit_section = <<'END';
h1. Greetings

<sx c=Perl>
use Modern::Perl;
say 'something';
</sx>

Implicit Section

<sx c="JavaScript">
function () { var one = 1 }
</sx>

Stuff After

END
    return $implicit_section;
}

BEGIN { require 5.010001; }

1;
__END__

=head1 Current Limitations

    * single word search
    * revision history doesn't have a web interface yet

=head1 Authors

Mateu Hunter C<hunter@missoula.org>

=head1 Copyright

Copyright 2011, Mateu Hunter

=head1 License

You may distribute this code under the same terms as Perl itself.

=cut

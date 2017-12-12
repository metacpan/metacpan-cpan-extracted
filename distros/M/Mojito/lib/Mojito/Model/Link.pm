use strictures 1;
package Mojito::Model::Link;
$Mojito::Model::Link::VERSION = '0.25';
use Moo;
use Mojito::Model::Doc;
use Mojito::Collection::Present;
use DateTime;
use XML::Atom::SimpleFeed;
use Data::Dumper::Concise;

with('Mojito::Role::Config');

has base_url => ( is => 'rw', );

has name_of_page_collection => (
    is => 'rw',
);

has db => (is => 'ro', lazy => 1);

has doc => (
    is      => 'ro',
    isa     => sub { die "Need a Doc Model object.  Have ref($_[0]) instead." unless $_[0]->isa('Mojito::Model::Doc') },
    lazy    => 1,
    handles => [
        qw(
          get_most_recent_docs
          get_feed_docs
          get_collections
          get_collection_pages
          get_docs_for_month
          )
    ],
    writer => '_build_doc',
);

=head1 Methods

=head2 get_most_recent_link_data

Get the recent links data structure - ArrayRef[HashRef]

TODO: There's HTML in here, omg.

=cut

sub get_most_recent_link_data {
    my ($self) = @_;
    my $cursor = $self->get_most_recent_docs;
    return $self->get_link_data($cursor);
}

=head2 get_feed_link_data

Get the data to create links for a particular feed.

=cut

sub get_feed_link_data {
    my ($self, $feed) = @_;
    my $cursor = $self->get_feed_docs($feed);
    return $self->get_link_data($cursor);
}

=head2 get_atom_feed

Get the data to create links for a particular feed.

=cut

sub get_atom_feed {
    my ($self, $feed) = @_;
    my $cursor = $self->get_feed_docs($feed);
    my @feed_title = split /_/, $feed;
    my $feed_title = join ' ', map { ucfirst($_) } @feed_title;
    my $atom = XML::Atom::SimpleFeed->new(title => $feed_title, id => $feed);
    while (my $doc = $cursor->next) {
        my $link = $self->base_url . 'public/page/' . $doc->{'_id'}->value;
        my $author = $doc->{author} || $self->config->{default_author} || 'Anonymous';
        my $dt = DateTime->from_epoch( epoch => $doc->{last_modified} );
        $dt->set_time_zone($self->config->{local_timezone});
        my $updated = $dt->mdy('/') . ' ' . $dt->hms;
        $atom->add_entry(
            title => $doc->{title},
            'link', => $link,
            author => $author,
            id => $doc->{'_id'}->value,
            updated => $updated,
        );
    }
    return $atom->as_string;
}

=head2 get_collections_index_link_data

Get the data to create links to all the available collections.

=cut

sub get_collections_index_link_data {
    my ($self) = @_;
    my $cursor = $self->get_collections;
    return $self->get_link_data($cursor);
}

=head2 get_collection_link_data

Get the data to create links to all the documents in a collection.

=cut

sub get_collection_link_data {
    my ($self, $collection_id) = @_;
    my ($name_of_page_collection, $pages) = $self->get_collection_pages($collection_id);
    # Store this for use later
    $self->name_of_page_collection($name_of_page_collection);
    return $self->get_link_data($pages);
}

=head2 get_link_data

Given a MongoDB cursor OR ArrayRef of documents then create the link data.

=cut

sub get_link_data {
    my ($self, $cursor) = @_;
    my $link_data;
    if ( ref($cursor) eq 'MongoDB::Cursor' ) {
        while ( my $doc = $cursor->next ) {
            my $title = $doc->{title}||$doc->{collection_name}||'no title';
            push @{$link_data}, { id => $doc->{'_id'}->value, title => $title };
        }
    }
    elsif ( ref($cursor) eq 'ARRAY' ) {
        foreach my $doc (@{$cursor}) {
            my $title = $doc->{title}||$doc->{collection_name}||'no title';
            push @{$link_data}, { id => $doc->{'_id'}||$doc->{id}, title => $title };
        }
    }
    else {
        die "I don't know how to get link data for ", Dumper $cursor;
    }

    return $link_data;
}

=head2 get_recent_links

Turn the data into HTML
$args should be a HashRef of options

=cut

sub get_recent_links {
    my ($self, $args) = @_;

    # Let's limit the amount of recent links we show
    # if we've set a limit in our config.
    $args->{last_link_number} = $self->config->{last_link_number};
    my $base_url = $self->base_url;
    my $link_data = $self->get_most_recent_link_data;
    my $link_title = '<span id="recent_articles_label" style="font-weight: bold;">Recent Articles</span><br />' . "\n";
    my $links = $self->create_list_of_links($link_data, $args) || "No Documents yet.  Get to <a href='${base_url}page'>writing!</a>";

    return $link_title . $links;
}

=head2 get_feed_links

Get the links for the documents belonging to a particular feed.

=cut

sub get_feed_links {
    my ($self, $feed) = @_;

    my $link_data = $self->get_feed_link_data($feed);
    my @feed_title = split /_/, $feed;
    my $feed_title = join ' ', map { ucfirst($_) } @feed_title;
    my $title = $feed_title . ' Feed';
    my $link_title = "<span class='feeds' style='font-weight: bold;'>$title</span><br />";
    my $links = $self->create_list_of_links($link_data, {want_public_link => 1});
    if ($links) {
        return $link_title . $links;
    }
    else {
        "The <em>$feed</em> feed is <b>empty</b>";
    }
}

=head2 view_selectable_page_list

Get the links for the documents belonging to a particular feed.

=cut

sub view_selectable_page_list {
    my ($self, $args) = @_;

    my $base_url = $self->base_url;
    my $link_data = $self->get_most_recent_link_data;
    my $list_title = '<span id="selectable_page_list_label" style="font-weight: bold;">Select articles to be part of a collection</span><br />' . "\n";
    my $list = $self->create_selectable_page_list($link_data, $args) || "No Documents yet.  Get to <a href='${base_url}page'>writing!</a>";

    return $list_title . $list;
}

=head2 view_sortable_page_list

View the pages in a collection, ready to be sorted.

=cut

sub view_sortable_page_list {
    my ($self, $args) = (shift, shift);

    my $base_url = $self->base_url;
    my $link_data = $self->get_collection_link_data($args->{collection_id});
    my $name_of_page_collection = $self->name_of_page_collection;
    my $list_title =<<"EOH";
    <header id='collections_index' style='font-weight: bold;'>
    ORDER (drag-n-drop) pages in the collection:  
    <span style='color: darkblue; font-size: 1.33em;'>$name_of_page_collection</i></span>
    </header>
EOH
    my $list = $self->create_sortable_page_list($link_data, $name_of_page_collection) || "No Documents yet.  Get to <a href='${base_url}page'>writing!</a>";

    return $list_title . $list;
}

=head2 create_selectable_page_list

Given link data (doc id and title) and possibly some $args then create hyperlinks

=cut

sub create_selectable_page_list {
    my ($self, $link_data) = (shift, shift);

    return if !$link_data;
    my $base_url = $self->base_url;
    my $list;
    foreach my $datum (@{$link_data}) {
        $list .= "<li id='$datum->{id}'>$datum->{title}</li>\n";
    }
    $list =<<"EOH";
    <section id='selectable_page_list'>
    <form action=${base_url}collect method=POST>
    <label for="collection_name">Collection name: </label>
    <input type="text" name="collection_name" id="collection_name" required="required" value="" />
    <ul>
    ${list}
    </ul>
    <div id="hidden_params"><input type="hidden" name="collected_page_ids" id="collected_page_ids" value="" /></div>
    <input type=submit name=collect value="Create Collection"/>
    </form>
    </section>

EOH
    
    return $list;
}

=head2 create_sortable_page_list

Create a sortable list of the pages in a collection.
This is how we impose order to collection of pages.

=cut

sub create_sortable_page_list {
    my ($self, $link_data, $collection_name) = (shift, shift, shift);

    my $list;
    foreach my $datum (@{$link_data}) {
        $list .= "<li id='$datum->{id}'>$datum->{title}</li>\n";
    }
    $list =<<"EOH";
    <section id='sortable'>
    <form action='' method=POST>
    <input type="hidden" name="collection_name" id="collection_name" value="${collection_name}" />
    <ol>
    ${list}
    </ol>
    <div id="hidden_params"><input type="hidden" name="collected_page_ids" id="collected_page_ids" value="" /></div>
    <input type=submit name=collect value="Order Collection"/>
    </form>
    </section>

EOH
    
    return $list;
}

=head2 view_collections_index

List the existing collections

=cut

sub view_collections_index {
    my ($self, $args) = @_;

    $args->{route} = '/collection/';
    my $base_url = $self->base_url;
    my $link_data = $self->get_collections_index_link_data;
    my $list_title = "<span id='collections_index' style='font-weight: bold;'>Page Collections:</span> <a href='${base_url}collect'>create one</a><br />\n";
    my $list = $self->create_generic_list_of_links($link_data, $args) || "No Collections yet.  Get to <a href='${base_url}collect'>creating them!</a>";

    return $list_title . $list;
}

=head2 view_collection_page

View a list of links to the pages that make up a collection.

=cut

sub view_collection_page {
    my ($self, $args) = @_;

    my $base_url = $self->base_url;
    my $link_data = $self->get_collection_link_data($args->{collection_id});
    my $name_of_page_collection = $self->name_of_page_collection;
    my $list_title =<<"EOH";
    <header id='collections_index' style='font-weight: bold;'>
    <span style='color: darkblue; font-size: 1.33em;'>$name_of_page_collection</i></span>
    </header>
EOH

    $args->{route} = '/collection/' . $args->{collection_id} . '/page/';
    $args->{route} = '/public' . $args->{route} if $args->{is_public};
    $args->{list_style} = 'ordered';
    my $list = $self->create_generic_list_of_links($link_data, $args) || "No Collections yet.  Get to <a href='${base_url}/collect'>creating them!</a>";

    return $list_title . $list;
}

=head2 create_list_of_links

Given link data (doc id and title) and possibly some $args then create hyperlinks

=cut

sub create_list_of_links {
    my ($self, $link_data, $args) = @_;

    my $base_url = $self->base_url;
    $base_url .= 'public/' if $args->{want_public_link};
    my $links;
    my $i = 1; my $limit = $args->{last_link_number};
    foreach my $datum (@{$link_data}) {
        $links .= "<div class='list_of_links'>&middot; <a href=\"${base_url}page/" . $datum->{id} . '">' . $datum->{title} . "</a>";
        if ($args && $args->{want_delete_link}) {
            $links .=  " | <span style='font-size: 0.88em;'><a href=\"${base_url}page/"   . $datum->{id} . '/delete"> delete</a></span>';
        }
        $links .= "</div>\n";
        last if ($limit && ($i == $limit)); $i++;
    }
    $links = "<section id='list_of_links'>\n${links}\n</section>" if defined $links;
    return $links;
}

=head2 create_generic_list_of_links

Given link data (doc id and title) and possibly some $args then create hyperlinks,
but in a more general manner than create_list_of_links().

    Returns array of <a hrefs 

=cut

sub create_generic_list_of_links {
    my ($self, $link_data, $args) = @_;
    
    my $base_url = $self->base_url;
    my $route = $args->{route}||die 'Need a route to create a generic list of links';
    # make sure $route doesn't start with a '/'
    $route =~ s/^\///;
    # NOTE: We're assuming a route like /page/$id or /collection/$id etc.
    my $base_href = $base_url . $route;
    my @links;
    my $item_number = 1;
    foreach my $datum (@{$link_data}) {
        next if not $datum->{id};
        my $moniker = ($args->{list_style} && $args->{list_style} eq 'ordered') ? "$item_number. " : '&middot; ';
        push @links, $moniker . "<a href=\"${base_href}" . $datum->{id} . '">' . $datum->{title} . "</a>";
        $item_number++;
    }
    my $links = join "<br />\n", @links;
    my $return = '<section id="list_of_links">' .  $links . '</section>';
}

sub view_collection_nav {
    my ($self, $params) = @_;
    
    # Obtain focus point.
    my $presenter = Mojito::Collection::Present->new(
        config        => $self->config,
        db            => $self->db, 
        collection_id => $params->{collection_id}, 
        focus_page_id => $params->{page_id},
    );
    
    # Handle public collections
    my $base_url = $self->base_url;
    $base_url .= 'public/' if $params->{public};

    my $next_page_URL     = $base_url . $presenter->next_page_route;
    my $previous_page_URL = $base_url . $presenter->previous_page_route;
    my $index_page_URL    = $base_url . $presenter->index_page_route;
    my $js = $self->collection_nav_js( $next_page_URL, $previous_page_URL, $index_page_URL);
    my $nav_fragment =<<"EOH";
    $js
   <div style="float:right;">
    <a accesskey='p' href="${previous_page_URL}" title='[p]'>&lt; &lt; Previous</a> |
    <a accesskey='i' href="${index_page_URL}" title='[i]'>Index</a> |
    <a accesskey='n' href="${next_page_URL}" title='[n]'>Next &gt;&gt;</a>
    </div>
EOH

    return $nav_fragment;
}

sub collection_nav_js {
    my ($self, $next_page, $previous_page, $index_page) = @_;

    my $js =<<"EOJ";
<script>
    function nextSlide() {
        window.location = '$next_page';
    }
    
    function prevSlide() {
        window.location = '$previous_page';
    }
    
    function indexSlide() {
        window.location = '$index_page';
    }
    
    function handleKey(e) {
        var key;
        if (e == null) {
            // IE
            key = event.keyCode
        } 
        else {
            // Mozilla
            if (e.altKey || e.ctrlKey) {
                return true
            }
            key = e.which
        }
        switch(key) {
            case 8: prevSlide(); break
            case 13: nextSlide(); break
            case 32: nextSlide(); break
            case 105: indexSlide(); break
            case 110: nextSlide(); break
            case 112: prevSlide(); break
            default: //xxx(e.which)
        }
    }

    document.onkeypress = handleKey
</script>

EOJ
    return $js
}

=head2 BUILD

Create the handler objects

=cut

sub BUILD {
    my $self                  = shift;
    my $constructor_args_href = shift;

    # pass the options into the subclasses
    $self->_build_doc(Mojito::Model::Doc->new($constructor_args_href));
}

1

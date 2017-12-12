use strictures 1;
package Mojito::Template;
$Mojito::Template::VERSION = '0.25';
use Moo;
use 5.010;
use MooX::Types::MooseLike::Base qw(:all);
use Mojito::Model::Link;
use Mojito::Collection::CRUD;
use Mojito::Page::Publish;
use DateTime;
use Syntax::Keyword::Junction qw/ any /;
use HTML::Entities;
use Data::Dumper::Concise;

with('Mojito::Template::Role::Javascript');
with('Mojito::Template::Role::CSS');

=head1 Name

Mojito::Template - the main HTML class

=cut

has 'template' => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_template',
);

has 'page_id' => (
    is => 'rw',
);

# Allow Template to receive a db attribute upon construction
# currently it's passed to the $mojito->tmpl handler
has 'db' => ( is => 'ro', lazy => 1);

has 'base_url' => ( is => 'rw', );

has linker => (
    is      => 'ro',
    isa     => sub { die "Need a Link Model object.  Have ref($_[0]) instead." unless $_[0]->isa('Mojito::Model::Link') },
    lazy    => 1,
    handles => {
        recent_links_view            => 'get_recent_links',
        collection_page_view         => 'view_collection_page',
        select_collection_pages_view => 'view_selectable_page_list',
        sort_collection_pages_view   => 'view_sortable_page_list',
        collections_index_view       => 'view_collections_index',
        get_docs_for_month           => 'get_docs_for_month',
        get_collection_list         => 'get_collections_index_link_data',
    },
    writer => '_set_linker',
);

has collector => (
    is      => 'ro',
    isa     => sub { die "Need a Collection::CRUD object" unless $_[0]->isa('Mojito::Collection::CRUD') },
    'default' => sub { my $self = shift; return Mojito::Collection::CRUD->new(config => $self->config, db => $self->db) },
    lazy => 1,
);

has 'home_page' => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_home_page',
);

has 'collect_page_form' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_collect_page_form',
);

has 'collections_index' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_collections_index',
);

has 'recent_links' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_recent_links',
);

has 'wiki_language_selection' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_wiki_language_selection',
);
has js_css_html => (
    is => 'ro',
    isa => Value,
    lazy => 1,
    default => sub { my $self = shift; join "\n", @{$self->javascript_html}, @{$self->css_html} }
);

has page_wrap_end => (
    is => 'ro',
    lazy => 1,
    builder => '_build_page_wrap_end',
);

sub _build_template {
    my $self = shift;

    my $base_url  = $self->base_url;
    my $mojito_version = $self->config->{VERSION};
    my $wiki_language_selection = $self->wiki_language_selection;
    my $js_css = $self->js_css_html;
    my $page_id = $self->page_id||'';
    my $publisher = Mojito::Page::Publish->new(config => $self->config);
    my $publish_form = '';
    $publish_form = $publisher->publish_form||'' if $page_id;
    my @collections_for_page = $self->collector->editer->collections_for_page($page_id);
    my $collection_list = $self->get_collection_list||[];
    my $collection_size = scalar @{$collection_list} + 1;
    my $collection_options = "<select id='collection_select' name='collection_select' 
    multiple='multiple' size='${collection_size}' form='editForm' style='font-size: 1.00em; display:none;' >\n";
    $collection_options .= "<option value='0'>- No Collection -</option>\n";
    foreach my $collection (@{$collection_list}) {
        $collection_options .= "<option value='$collection->{id}'";
        if ($collection->{id} eq any(@collections_for_page)) {
            $collection_options .= " selected='selected' ";
        }
        $collection_options .= ">$collection->{title}</option>\n";
    }
    $collection_options .= "</select>\n";
    my $edit_page = <<"END_HTML";
<!doctype html>
<html>
<head>
  <meta charset=utf-8>
  <meta http-equiv="powered by" content="Mojito $mojito_version" />
  <title>Mojito page</title>
$js_css
<script></script>
<style></style>
</head>
<body class="html_body">
<header>
<nav id="edit_link" class="edit_link"></nav>
<nav id="new_link" class="new_link"> <a href=${base_url}page>New</a></nav>
</header>
<section id="message_area"></section>
<section id="collection_nav_area"></section>
<article id="body_wrapper">
<input type="hidden" id ="page_id" name="page_id" value="$page_id" />
<section id="edit_area">
<span style="font-size: 0.82em;"><label id="feeds_label">feeds+</label>
  <input id="feeds" name="feeds" form="editForm" value="" size="12" style="font-size: 1.00em; display:none;" />
</span>
<span style="font-size: 0.82em;">
<label id="collection_label">collections+</label>
$collection_options
</span>
<form id="editForm" action="" accept-charset="UTF-8" method="post">
    <div id="wiki_language">
        $wiki_language_selection
    </div>
    <input id="mongo_id" name="mongo_id" type="hidden" form="editForm" value="" />
    <input id="wiki_language" name="wiki_language" type="hidden" form="editForm" value="" />
    <input id="page_title" name="page_title" type="hidden" form="editForm" value="" />
    <textarea id="content" name="content" rows="32" required="required"/></textarea>
    <input id="commit_message" name="commit_message" value="commit message" onclick="this.value == 'commit message' ? this.value = '' : true"/>
    <input id="submit_save" name="submit" type="submit" value="Save" style="font-size: 66.7%;" />
    <input id="submit_view" name="submit" type="submit" value="Done" style="font-size: 66.7%;" />
    <label style="font-size: 0.667em;" for="public" title="Check if you want a publicly viewable page" >
      <input id="public" name="public" value="1" type="checkbox" style="font-size: 0.667em;" />
       public
    </label>
</form>
</section>
<section id="view_area" class="view_area_edit_mode"></section>
<nav id="side">
<section id="search_area">
<form action=${base_url}search method=POST>
<input type="text" name="word" value="Search" onclick="this.value == 'Search' ? this.value = '' : true"/>
</form>
</section><br />
<section id="publish_area">$publish_form</section>
<section id="collections_area"></section>
<section id="calendar_area"><a href="${base_url}calendar">Calendar</a></section>
<section id="recent_area"></section>
</nav>
</article>
<footer id="footer_area">
<nav id="edit_link" class="edit_link"></nav>
<nav id="new_link" class="new_link"> <a href=${base_url}page>New</a></nav>
</footer>
</body>
</html>
END_HTML
    $edit_page =~ s/<script><\/script>/<script>mojito.base_url = '${base_url}';<\/script>/s;
    return $edit_page;
}

sub _build_wiki_language_selection {
    my ($self) = @_;
    
    my $selection;
    my $default_wiki_language =$self->config->{default_wiki_language}||'markdown';
    foreach my $language (qw/textile markdown creole html pod/) {
        if ($language =~ m/$default_wiki_language/) {
            $selection .= qq{<input type="radio" id="$language"  name="wiki_language" value="$language" checked="checked" /><label for="$language">$language</label>};
        }
        else {
            $selection .= qq{<input type="radio" id="$language"  name="wiki_language" value="$language" /><label for="$language">$language</label>};
        }
    }
    return $selection;
 }


sub page_wrap_start {
    my ($self, $title) = @_;
    my $mojito_version = $self->config->{VERSION};
    my $js_css = $self->js_css_html;
    my $page_start = <<"START_HTML";
<!doctype html>
<html>
<head>
  <meta charset=utf-8>
  <meta name="application-name" content="Mojito $mojito_version" />
  <title>$title</title>
$js_css
<script></script>
<style></style>
</head>
<body class="html_body">
<section id="message_area"></section>
<article id="body_wrapper">
START_HTML

    return $page_start;
}

sub page_wrap_start_vanilla {
    my ($self, $title) = @_;
    my $mojito_version = $self->config->{VERSION};
    my $static_url = $self->config->{static_url};
    my $page_start = <<"START_HTML";
<!doctype html>
<html>
<head>
  <meta charset=utf-8>
  <meta name="application-name" content="Mojito $mojito_version" />
  <title>$title</title>
  <link href=${static_url}css/mojito.css type=text/css rel=stylesheet />
</head>
<body class="vanilla_body">
<article id="body_wrapper_vanilla">
START_HTML

    return $page_start;
}

sub _build_page_wrap_end {
    my $self = shift;

    my $page_end =<<'END_HTML';

</article>
</body>
</html>
END_HTML

    return $page_end;
}

=head2 wrap_page

Wrap a page body with start and end HTML.

=cut

sub wrap_page {
    my ($self, $page_body, $title) = @_;
    $title //= 'Mojito page';
    $page_body //= 'Empty page';
    return ($self->page_wrap_start($title) . $page_body . $self->page_wrap_end);
}

=head2 wrap_page_vanilla

Wrap a page body with start and end HTML, and NO Javascript or CSS links

=cut

sub wrap_page_vanilla {
    my ($self, $page_body, $title) = @_;
    $title //= 'Mojito page';
    $page_body //= 'Empty page';
    return ($self->page_wrap_start_vanilla($title) . $page_body . $self->page_wrap_end);
}

sub _build_collect_page_form {
    my $self = shift;
    return $self->wrap_page($self->select_collection_pages_view);
}

sub _build_collections_index {
    my $self = shift;
    return $self->wrap_page($self->collections_index_view);
}

sub _build_recent_links {
    my $self = shift;
    return $self->wrap_page($self->recent_links_view({want_delete_link => 1}));
}

=head2 sort_collection_form

A form to sort a collection of pages.

=cut

sub sort_collection_form {
    my ($self, $params) = (shift, shift);
    return $self->wrap_page($self->sort_collection_pages_view({ collection_id => $params->{id} }));
}

=head2 collection_page

Given a collection id, show a list of belonging pages.

=cut

sub collection_page {
    my ($self, $params) = (shift, shift);

    my $base_url = $self->base_url;
    $base_url .= 'public/' if $params->{public};
    my $collector = Mojito::Collection::CRUD->new(config => $self->config, db => $self->db);
    my $collection = $collector->read( $params->{id} );
    return $self->wrap_page(
        $self->collection_page_view( { collection_id => $params->{id}, is_public => $params->{public} }), 
        $collection->{collection_name},
    );
}

sub _build_home_page {
    my $self = shift;

    my $base_url  = $self->base_url;
    my $mojito_version = $self->config->{VERSION};
    my $js_css = $self->js_css_html;
    my $home_page = <<"END_HTML";
<!doctype html>
<html>
<head>
  <meta charset=utf-8>
  <meta name="application-name" content="Mojito $mojito_version" />
  <title>Mojito page</title>
$js_css
<script></script>
<style></style>
</head>
<body class=html_body>
<header>
<nav id="new_link" class="new_link"> <a href=${base_url}page>New</a></nav>
</header>
<article id="body_wrapper">
<nav id="side">
<section id="search_area"><form action=${base_url}search method=POST><input type="text" name="word" value="Search" onclick="this.value == 'Search' ? this.value = '' : true" /></form></section><br />
<section id="recent_area"></section>
</nav>
</article>
<footer id="footer_area">
<nav id="new_link" class="new_link"> <a href=${base_url}page>New</a></nav>
</footer>
</body>
</html>
END_HTML

    return $home_page;
}

=head1 Methods

=head2 fillin_edit_page

Get the contents of the edit page proper given the starting template and some data.

=cut

sub fillin_edit_page {
    my ( $self, $page, $page_view, $mongo_id ) = @_;

    # Encode source content with HTML entities since it will be displayed in a textarea
    my $page_source   = encode_entities($page->{page_source}); 
    my $wiki_language = $page->{default_format}; 
    my $page_title    = $page->{title}||'no title';
    my @feeds = ();
    if (ref($page->{feeds}) eq 'ARRAY') {
        @feeds = @{$page->{feeds}}; 
    }
    my $feeds         = join ':', @feeds;
    my $public        = $page->{public};

    # Set page_id for the template
    $self->page_id($mongo_id);
    my $output   = $self->template;
    my $base_url = $self->base_url;
    $output =~
s/<script><\/script>/<script>mojito.preview_url = '${base_url}preview';<\/script>/s;
    # Set some form values
    $output =~ s/(<input id="mongo_id".*?value=)""/$1"${mongo_id}"/si;
#    $output =~ s/(<input .*? id ="page_id" .*? value=)""/$1"${mongo_id}"/si;
    $output =~ s/(<input id="wiki_language".*?value=)""/$1"${wiki_language}"/si;
    $output =~ s/(<input id="page_title".*?value=)""/$1"${page_title}"/si;
    $output =~ s/(<input id="feeds".*?value=)""/$1"${feeds}"/si;
    if ($public) {
        $output =~ s/(<input id="public")/$1 checked="checked"/si;
    }
    $output =~
s/(<textarea\s+id="content"[^>]*>)<\/textarea>/$1${page_source}<\/textarea>/si;
    $output =~
s/(<section\s+id="view_area"[^>]*>)<\/section>/$1${page_view}<\/section>/si;

# An Experiment in Design: take out the save button, because we have autosave every few seconds
    $output =~ s/<input id="submit_save".*?>//sig;

    # Remove side, recent area and wiki_language (for create only)
    $output =~ s/<nav id="side">.*?<\/nav>//si;
#    $output =~ s/<section id="recent_area".*?><\/section>//si;
    $output =~ s/<div id="wiki_language".*?>.*?<\/div>//si;
    $output =~ s|(<section id="edit_area">)|$1\n<button id="toggle_view">Toggle View</button>|si;

    # Remove edit and new links
    $output =~ s/<nav id="edit_link".*?><\/nav>//sig;
    $output =~ s/<nav id="new_link".*?>.*?<\/nav>//sig;

    # body with no style
    $output =~ s/<body.*?>/<body>/si;
    
    # Give the page a title
    if ($page_title) {
       $output =~ s/<title>.*?<\/title>/<title>${page_title}<\/title>/si;
    }
    return $output; 
}

=head2 fillin_create_page

Get the contents of the create page proper given the starting template and some data.

=cut

sub fillin_create_page {
    my ($self) = @_;

    my $output   = $self->template;
    my $base_url = $self->base_url;

    # Set mojito preiview_url variable
    $output =~
s/<script><\/script>/<script>mojito.preview_url = '${base_url}preview'<\/script>/;

    # Take out view button and change save to create.
    $output =~ s/<input id="submit_view".*?>//;
    $output =~ s/<input id="submit_save"(.*?>)/<input id="submit_create"$1/;
    $output =~ s/(id="submit_create".*?value=)"Save"/$1"Create"/i;

    # Remove side nav area
    $output =~ s/<nav id="side">.*?<\/nav>//si;

    # Remove wiki_language hidden input (for edit)
    $output =~ s/<input id="wiki_language".*?\/>//sig;

    # Remove edit and new links
    $output =~ s/<nav id="edit_link".*?><\/nav>//sig;
    $output =~ s/<nav id="new_link".*?>.*?<\/nav>//sig;

    # body with no style
    $output =~ s/<body.*?>/<body>/si;

    return $output;
}

sub calendar_for_month {
    my $self = shift;
    my %args = ref($_[0]) ? %{ $_[0] } : @_;
    my ($month, $year, $title) = @args{qw/month year title/};
    my $base_url = $self->base_url;
    #$title ||= 'Monthly Notes';
    my %monthly_docs = $self->get_docs_for_month($month, $year);
    my ($m_j, $m_k, $y_j, $y_k) = next_and_previous_month_year($month, $year);
    my $calendar = "<section id='calendar_month'>\n";
    $calendar .= "<h1>${title}</h1>\n" if $title;
    $calendar .= "<table class='monthly_calendar'>";

# Got to turn off highlight of current day else we'd have to strip the \b's around it.
# TODO: Allow variable path to cal
    open(my $CAL, '-|', "/usr/bin/cal -h $month $year")
      || die "Can't open /usr/bin/cal\n";
    while (<$CAL>) {

        last if /^\s+$/;    ## ignore cal's terminating blank line
        s/^\s*(.*?)\s*$/$1/;    ## trim whitespace

        if ($. == 1) {
            $calendar .=
"<tr><th class='previous' colspan='3'><a href='${base_url}calendar/year/${y_j}/month/${m_j}'>Previous Month</a></th>
     <th class='calendar_month' colspan='1'>$_</th>
     <th class='next' colspan='3'><a href='${base_url}calendar/year/${y_k}/month/${m_k}'>Next Month</a></th></tr>\n";
            next;
        }

        my $tag;
        if ($. == 2) {
            $tag = "th class='weekdays'";
        }
        else { $tag = "td" }

        ## make a row, padding first week of the month as necessary
        my @data = ();
        @data = split(/\s+/, $_);
        $calendar .= "<tr>\n";
        if ($. == 3) {
            for (1 .. 6 - $#data) { $calendar .= "<td> </td>\n"; }
        }
        for my $i (0 .. $#data) {
            $calendar .= "<$tag>$data[$i]";
            # Just process the digits found.
            next if ($data[$i] !~ m/^\d+$/);
            foreach my $ref (@{ $monthly_docs{ $data[$i] } }) {
                            # Make srue we have some type of title
                            $ref->{title} ||= 'No title found';
                            $calendar .=
"<div class='calendar_note'><a href='${base_url}page/$ref->{id}'>* $ref->{title}</a></div>";
            }
            $calendar .= "</td>\n";
        }     
        $calendar .= "</tr>\n";
    }
    close($CAL);
    $calendar .= "</table>\n</section>\n";

    return $calendar;
}

sub calendar_month_page {
    my $self = shift;
    my %args = ref($_[0]) ? %{ $_[0] } : @_;
    @args{qw/month year/} = get_current_month_year() 
      if not($args{month} && $args{year});
    my ($month, $year, $title) = @args{qw/month year title/};
    $title ||= "Notes Calendar for $month/$year";
    return $self->wrap_page_vanilla($self->calendar_for_month(\%args), $title);
}

sub get_current_month_year {
    my $now = DateTime->now;
    return ($now->month, $now->year);
}

sub next_and_previous_month_year {
    my ($month, $year) = @_;
## Set up for previous and next month link
    my ($m_j, $m_k, $y_j, $y_k);
    if ($month == 12) {
        $m_j = 11;
        $m_k = 1;
        $y_j = $year;
        $y_k = $year + 1;
    }
    elsif ($month == 1) {
        $m_j = 12;
        $m_k = 2;
        $y_j = $year - 1;
        $y_k = $year;
    }
    else {
        $m_j = $month - 1;
        $m_k = $month + 1;
        $y_j = $year;
        $y_k = $year;
    }
    return ($m_j, $m_k, $y_j, $y_k);
}

sub BUILD {
    my $self                  = shift;
    my $constructor_args_href = shift;

    # pass the options into the delegatees
    $self->_set_linker(Mojito::Model::Link->new($constructor_args_href));
}
1

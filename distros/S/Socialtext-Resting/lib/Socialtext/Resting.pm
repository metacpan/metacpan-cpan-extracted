package Socialtext::Resting;

use strict;
use warnings;

use URI::Escape;
use LWP::UserAgent;
use HTTP::Request;
use Class::Field 'field';
use JSON::XS;

use Readonly;

our $VERSION = '0.38';

=head1 NAME

Socialtext::Resting - module for accessing Socialtext REST APIs

=head1 SYNOPSIS

  use Socialtext::Resting;
  my $Rester = Socialtext::Resting->new(
    username => $opts{username},
    password => $opts{password},
    server   => $opts{server},
  );
  $Rester->workspace('wikiname');
  $Rester->get_page('my_page');
}

=head1 DESCRIPTION

C<Socialtext::Resting> is a module designed to allow remote access
to the Socialtext REST APIs for use in perl programs.

=head1 METHODS

=cut

Readonly my $BASE_URI => '/data';
Readonly my $BASE_WS_URI => $BASE_URI . '/workspaces';
Readonly my %ROUTES   => (
    backlinks      => $BASE_WS_URI . '/:ws/pages/:pname/backlinks',
    breadcrumbs    => $BASE_WS_URI . '/:ws/breadcrumbs',
    frontlinks     => $BASE_WS_URI . '/:ws/pages/:pname/frontlinks',
    page           => $BASE_WS_URI . '/:ws/pages/:pname',
    pagerevision   => $BASE_WS_URI . '/:ws/pages/:pname/revisions/:revisionid',
    pages          => $BASE_WS_URI . '/:ws/pages',
    pagetag        => $BASE_WS_URI . '/:ws/pages/:pname/tags/:tag',
    pagetags       => $BASE_WS_URI . '/:ws/pages/:pname/tags',
    pagetaghistory => $BASE_WS_URI . '/:ws/pages/:pname/taghistory',
    pagecomments   => $BASE_WS_URI . '/:ws/pages/:pname/comments',
    pageattachment => $BASE_WS_URI
        . '/:ws/pages/:pname/attachments/:attachment_id',
    pageattachments      => $BASE_WS_URI . '/:ws/pages/:pname/attachments',
    sheetcells           => $BASE_WS_URI . '/:ws/sheets/:pname/cells/:cellid',
    revisions            => $BASE_WS_URI . '/:ws/pages/:pname/revisions',
    taggedpages          => $BASE_WS_URI . '/:ws/tags/:tag/pages',
    workspace            => $BASE_WS_URI . '/:ws',
    workspaces           => $BASE_WS_URI,
    workspacetag         => $BASE_WS_URI . '/:ws/tags/:tag',
    workspacetags        => $BASE_WS_URI . '/:ws/tags',
    workspaceattachment  => $BASE_WS_URI . '/:ws/attachments/:attachment_id',
    workspaceattachments => $BASE_WS_URI . '/:ws/attachments',
    workspaceuser        => $BASE_WS_URI . '/:ws/users/:user_id',
    workspaceusers       => $BASE_WS_URI . '/:ws/users',
    user                 => '/data/users/:user_id',
    users                => '/data/users',
    homepage             => $BASE_WS_URI . '/:ws/homepage',
    people               => $BASE_URI . '/people',
    person               => $BASE_URI . '/people/:pname',
    person_tag           => $BASE_URI . '/people/:pname/tags',
    profile_photo        => $BASE_URI . '/people/:pname/photo/:version',
    signals              => $BASE_URI . '/signals',
    webhooks             => $BASE_URI . '/webhooks',
    webhook              => $BASE_URI . '/webhooks/:id',
);

field 'workspace';
field 'username';
field 'password';
field 'user_cookie';
field 'server';
field 'verbose';
field 'accept';
field 'filter';
field 'order';
field 'offset';
field 'count';
field 'query';
field 'etag_cache' => {};
field 'http_header_debug';
field 'response';
field 'json_verbose';
field 'cookie';
field 'agent_string';
field 'on_behalf_of';
field 'additional_headers' => {};
field 'siteminder';

=head2 new

    my $Rester = Socialtext::Resting->new(
        username => $opts{username},
        password => $opts{password},
        server   => $opts{server},
    );

    or

    my $Rester = Socialtext::Resting->new(
        user_cookie => $opts{user_cookie},
        server      => $opts{server},
    );

Creates a Socialtext::Resting object for the specified
server/user/password, or server/cookie combination.

=cut

sub new {
    my $invocant = shift;
    my $class    = ref($invocant) || $invocant;
    my $self     = {@_};
    return bless $self, $class;
}

=head2 accept

    $Rester->accept($mime_type);

Sets the HTTP Accept header to ask the server for a specific
representation in future requests.

Standard representations:
http://www.socialtext.net/st-rest-docs/index.cgi?standard_representations

Common representations:

=over 4

=item text/x.socialtext-wiki

=item text/html

=item application/json

=back

=head2 get_page

    $Rester->workspace('wikiname');
    $Rester->get_page('page_name');

Retrieves the content of the specified page.  Note that
the workspace method needs to be called first to specify
which workspace to operate on.

=cut

sub get_page {
    my $self = shift;
    my $pname = shift;

    return $self->_get_page_or_revision(
        'page',
        $pname,
    );
}

=head2 get_page_revision

    $Rester->workspace('wikiname');
    $Rester->get_page_revision('page_name', 'revision_id');

Retrieves the content of the specified page revision.  Note that the workspace
method needs to be called first to specify which workspace to operate on.

=cut

sub get_page_revision {
    my $self = shift;
    my $pname = shift;
    my $revisionid = shift;

    return $self->_get_page_or_revision(
        'pagerevision',
        $pname,
        $revisionid,
    );
}

sub _get_page_or_revision {
    my $self = shift;
    my $route = shift;
    my $pname = shift;
    my $revisionid = shift;

    my $paccept = (ref $pname) ? $pname->{accept} : $self->accept;

    $pname = name_to_id($pname);
    my $accept = $paccept || 'text/x.socialtext-wiki';

    my $workspace = $self->workspace;
    my $uri = $self->_make_uri(
        $route,
        { pname => $pname, ws => $workspace, revisionid => $revisionid }
    );
    $uri .= '?verbose=1' if $self->json_verbose;

    $accept = 'application/json' if $accept eq 'perl_hash';
    my ( $status, $content, $response ) = $self->_request(
        uri    => $uri,
        method => 'GET',
        accept => $accept,
    );

    if ( $status == 200 || $status == 404 ) {
        $self->{etag_cache}{$workspace}{$pname} = $response->header('etag');
        return decode_json($content)
            if (($self->accept || '') eq 'perl_hash');
        return $content;
    }
    else {
        die "$status: $content\n";
    }
}

=head2 get_attachment

    $Rester->workspace('wikiname');
    $Rester->get_attachment('attachment_id');

Retrieves the specified attachment from the workspace.
Note that the workspace method needs to be called first
to specify which workspace to operate on.

=cut

# REVIEW: dup with above, some
sub get_attachment {
    my $self          = shift;
    my $attachment_id = shift;

    my $uri = $self->_make_uri(
        'workspaceattachment',
        { attachment_id => $attachment_id, ws => $self->workspace, }
    );

    my ( $status, $content ) = $self->_request(
        uri    => $uri,
        method => 'GET',
    );

    if ( $status == 200 || $status == 404 ) {
        return $content;
    }
    else {
        die "$status: $content\n";
    }
}

=head2 put_workspacetag

    $Rester->workspace('wikiname');
    $Rester->put_workspacetag('tag');

Add the specified tag to the workspace.

=cut

sub put_workspacetag {
    my $self  = shift;
    my $tag   = shift;

    my $uri = $self->_make_uri(
        'workspacetag',
        { ws => $self->workspace, tag => $tag }
    );

    my ( $status, $content ) = $self->_request(
        uri    => $uri,
        method => 'PUT',
    );

    if ( $status == 204 || $status == 201 ) {
        return $content;
    }
    else {
        die "$status: $content\n";
    }
}

=head2 put_pagetag

    $Rester->workspace('wikiname');
    $Rester->put_pagetag('page_name', 'tag');

Add the specified tag to the page.

=cut

sub put_pagetag {
    my $self  = shift;
    my $pname = shift;
    my $tag   = shift;

    $pname = name_to_id($pname);
    my $uri = $self->_make_uri(
        'pagetag',
        { pname => $pname, ws => $self->workspace, tag => $tag }
    );

    my ( $status, $content ) = $self->_request(
        uri    => $uri,
        method => 'PUT',
    );

    if ( $status == 204 || $status == 201 ) {
        return $content;
    }
    else {
        die "$status: $content\n";
    }
}

=head2 delete_workspacetag

    $Rester->workspace('wikiname');
    $Rester->delete_workspacetag('tag');

Delete the specified tag from the workspace.

=cut

sub delete_workspacetag {
    my $self  = shift;
    my $tag   = shift;

    my $uri = $self->_make_uri(
        'workspacetag',
        { ws => $self->workspace, tag => $tag }
    );

    my ( $status, $content ) = $self->_request(
        uri    => $uri,
        method => 'DELETE',
    );

    if ( $status == 204 ) {
        return $content;
    }
    else {
        die "$status: $content\n";
    }
}

=head2 delete_pagetag

    $Rester->workspace('wikiname');
    $Rester->delete_pagetag('page_name', 'tag');

Delete the specified tag from the page.

=cut

sub delete_pagetag {
    my $self  = shift;
    my $pname = shift;
    my $tag   = shift;

    $pname = name_to_id($pname);
    my $uri = $self->_make_uri(
        'pagetag',
        { pname => $pname, ws => $self->workspace, tag => $tag }
    );

    my ( $status, $content ) = $self->_request(
        uri    => $uri,
        method => 'DELETE',
    );

    if ( $status == 204 ) {
        return $content;
    }
    else {
        die "$status: $content\n";
    }
}

=head2 post_attachment

    $Rester->workspace('wikiname');
    $Rester->post_attachment('page_name',$id,$content,$mime_type);

Attach the file to the specified page

=cut

sub post_attachment {
    my $self               = shift;
    my $pname              = shift;
    my $attachment_id      = shift;
    my $attachment_content = shift;
    my $attachment_type    = shift;

    $pname = name_to_id($pname);
    my $uri = $self->_make_uri(
        'pageattachments',
        {
            pname => $pname,
            ws    => $self->workspace
        },
    );

    $uri .= "?name=$attachment_id";

    my ( $status, $content, $response ) = $self->_request(
        uri     => $uri,
        method  => 'POST',
        type    => $attachment_type,
        content => $attachment_content,
    );

    my $location = $response->header('location');
    $location =~ m{.*/attachments/([^/]+)};
    $location = URI::Escape::uri_unescape($1);

    if ( $status == 204 || $status == 201 ) {
        return $location;
    }
    else {
        die "$status: $content\n";
    }
}

=head2 post_comment

    $Rester->workspace('wikiname');
    $Rester->post_comment( 'page_name', "me too" );

Add a comment to a page.

=cut

sub post_comment {
    my $self    = shift;
    my $pname   = shift;
    my $comment = shift;

    $pname = name_to_id($pname);
    my $uri = $self->_make_uri(
        'pagecomments',
        {
            pname => $pname,
            ws    => $self->workspace
        },
    );

    my ( $status, $content ) = $self->_request(
        uri     => $uri,
        method  => 'POST',
        type    => 'text/x.socialtext-wiki',
        content => $comment,
    );

    die "$status: $content\n" unless $status == 204;
}

=head2 put_page

    $Rester->workspace('wikiname');
    $Rester->put_page('page_name',$content);

Save the content as a page in the wiki.  $content can either be a string,
which is treated as wikitext, or a hash with the following keys:

=over

=item content

A string which is the page's wiki content.

=item date

RFC 2616 HTTP Date format string of the time the page was last edited

=item from

A username of the last editor of the page. If the the user does not exist it
will be created, but will not be added to the workspace.

=back

=cut

sub put_page {
    my $self         = shift;
    my $pname        = shift;
    my $page_content = shift;

    my $workspace = $self->workspace;
    my $uri = $self->_make_uri(
        'page',
        { pname => $pname, ws => $workspace }
    );

    my $type = 'text/x.socialtext-wiki';
    if ( ref $page_content ) {
        $type         = 'application/json';
        $page_content = encode_json($page_content);
    }

    my %extra_opts;
    my $page_id = name_to_id($pname);
    if (my $prev_etag = $self->{etag_cache}{$workspace}{$page_id}) {
        $extra_opts{if_match} = $prev_etag;
    }

    my ( $status, $content ) = $self->_request(
        uri     => $uri,
        method  => 'PUT',
        type    => $type,
        content => $page_content,
        %extra_opts,
    );

    if ( $status == 204 || $status == 201 ) {
        return $content;
    }
    else {
        die "$status: $content\n";
    }
}

=head2 delete_page

    $Rester->workspace('wikiname');
    $Rester->delete_page('page_name');

Delete the specified page.

=cut

sub delete_page {
    my $self         = shift;
    my $pname        = shift;

    my $workspace = $self->workspace;
    my $uri = $self->_make_uri(
        'page',
        { pname => $pname, ws => $workspace }
    );

    my ( $status, $content ) = $self->_request(
        uri     => $uri,
        method  => 'DELETE',
        type    => 'application/json',
        content => '{}',
    );

    if ( $status == 204 ) {
        return $content;
    }
    else {
        die "$status: $content\n";
    }
}

# REVIEW: This is here because of escaping problems we have with
# apache web servers. This code effectively translate a Page->uri
# to a Page->id. By so doing the troublesome characters are factored
# out, getting us past a bug. This change should _not_ be maintained
# any longer than strictly necessary, primarily because it
# creates an informational dependency between client and server
# code by representing name_to_id translation code on both sides
# of the system. Since it is not used for page PUT, new pages
# will safely have correct page titles.
#
# This method is useful for clients, so lets make it public.  In the
# future, this call could go to the server to reduce code duplication.

=head2 name_to_id

    my $id = $Rester->name_to_id($name);
    my $id = Socialtext::Resting::name_to_id($name);

Convert a page name into a page ID.  Can be called as a method or 
as a function.

=cut

sub _name_to_id { name_to_id(@_) }
sub name_to_id {
    my $id = shift;
    $id = shift if ref($id); # handle being called as a method
    $id = '' if not defined $id;
    $id =~ s/[^\p{Letter}\p{Number}\p{ConnectorPunctuation}\pM]+/_/g;
    $id =~ s/_+/_/g;
    $id =~ s/^_(?=.)//;
    $id =~ s/(?<=.)_$//;
    $id =~ s/^0$/_/;
    $id = lc($id);
    return $id;
}


sub _make_uri {
    my $self         = shift;
    my $thing        = shift;
    my $replacements = shift;

    my $uri = $ROUTES{$thing};

    # REVIEW: tried to do this in on /g go but had issues where
    # syntax errors were happening...
    foreach my $stub ( keys(%$replacements) ) {
        my $replacement
            = URI::Escape::uri_escape_utf8( $replacements->{$stub} );
        $uri =~ s{/:$stub\b}{/$replacement};
    }

    return $uri;
}

=head2 get_pages

    $Rester->workspace('wikiname');
    $Rester->get_pages();

List all pages in the wiki.

=cut

sub get_pages {
    my $self = shift;

    return $self->_get_things('pages');
}

=head2 get_page_attachments 

    $Rester->get_page_attachments($page)

List all the attachments on a page.

=cut

sub get_page_attachments {
    my $self = shift;
    my $pname = shift;

    return $self->_get_things( 'pageattachments', pname => $pname );
}

=head2 get_sheet_cell

    $Rester->get_sheet_cell($page_id, $cellid)

Get the value of a cell in a spreadsheet.

=cut

sub get_sheet_cell {
    my $self = shift;
    my $pname = shift;
    my $cellid = shift;

    return $self->_get_things('sheetcells', pname => $pname,
        cellid => $cellid);
}

=head2 get_revisions

    $Rester->get_revisions($page)

List all the revisions of a page.

=cut

sub get_revisions {
    my $self = shift;
    my $pname = shift;

    return $self->_get_things( 'revisions', pname => $pname );
}

=head2 get_taghistory

    $Rester->workspace('wikiname');
    $Rester->get_taghistory($page)

Get a history, by revision, of all tags for a page.

=cut

sub get_taghistory {
    my $self = shift;
    my $pname = shift;

    return $self->_get_things( 'pagetaghistory', pname => $pname );
}

sub _extend_uri {
    my $self = shift;
    my $uri = shift;
    my @extend;

    if ( $self->filter ) {
        push (@extend, "filter=" . $self->filter);
    }
    if ( $self->query ) {
        push (@extend, "q=" . $self->query);
    }
    if ( $self->order ) {
        push (@extend, "order=" . $self->order);
    }
    if ( $self->offset ) {
        push (@extend, "offset=" . $self->offset);
    }
    if ( $self->count ) {
        push (@extend, "count=" . $self->count);
    }
    if (@extend) {
        $uri .= "?" . join(';', @extend);
    }
    return $uri;

}
sub _get_things {
    my $self         = shift;
    my $things       = shift;
    my %replacements = @_;
    my $accept = $self->accept || 'text/plain';

    my $uri = $self->_make_uri(
        $things,
        { ws => $self->workspace, %replacements }
    );
    $uri = $self->_extend_uri($uri);

    # Add query parameters from a
    if ( exists $replacements{_query} ) {
        my @params;
        for my $q ( keys %{ $replacements{_query} } ) {
            push @params, "$q=" . $replacements{_query}->{$q};
        }
        if (my $query = join( ';', @params )) {
            if ( $uri =~ /\?/ ) {
                $uri .= ";$query";
            }
            else {
                $uri .= "?$query";
            }
        }
    }

    $accept = 'application/json' if $accept eq 'perl_hash';
    my ( $status, $content ) = $self->_request(
        uri    => $uri,
        method => 'GET',
        accept => $accept,
    );

    if ( $status == 200 and wantarray ) {
        return ( grep defined, ( split "\n", $content ) );
    }
    elsif ( $status == 200 ) {
        return decode_json($content) 
            if (($self->accept || '') eq 'perl_hash');
        return $content;
    }
    elsif ( $status == 404 ) {
        return ();
    }
    elsif ( $status == 302 ) {
        return $self->response->header('Location');
    }
    else {
        die "$status: $content\n";
    }
}

=head2 get_workspace_tags

    $Rester->workspace('foo');
    $Rester->get_workspace_tags()

List all the tags in workspace foo.

=cut

sub get_workspace_tags {
    my $self = shift;
    return $self->_get_things( 'workspacetags' )
}

=head2 get_homepage

Return the page name of the homepage of the current workspace.

=cut

sub get_homepage {
    my $self = shift;
    my $uri = $self->_get_things( 'homepage' );
    my $workspace = $self->workspace;
    $uri =~ s#.*/data/workspaces/\Q$workspace\E/pages/(.+)#$1# if $uri;
    return $uri;
}

=head2 get_backlinks

    $Rester->workspace('wikiname');
    $Rester->get_backlinks('page_name');

List all backlinks to the specified page

=cut

sub get_backlinks {
    my $self  = shift;
    my $pname = shift;
    $pname = name_to_id($pname);
    return $self->_get_things( 'backlinks', pname => $pname );
}

=head2 get_frontlinks

    $Rester->workspace('wikiname');
    $Rester->get_frontlinks('page_name');

List all 'frontlinks' on the specified page

=cut

sub get_frontlinks {
    my $self       = shift;
    my $pname      = shift;
    my $incipients = shift || 0;
    $pname = name_to_id($pname);
    return $self->_get_things(
        'frontlinks', pname => $pname,
        ( $incipients ? ( _query => { incipient => 1 } ) : () )
    );
}

=head2 get_pagetags

    $Rester->workspace('wikiname');
    $Rester->get_pagetags('page_name');

List all pagetags on the specified page

=cut

sub get_pagetags {
    my $self  = shift;
    my $pname = shift;
    $pname = name_to_id($pname);
    return $self->_get_things( 'pagetags', pname => $pname );
}

=head2 get_taggedpages

    $Rester->worksapce('wikiname');
    $Rester->get_taggedpages('tag');

List all the pages that are tagged with 'tag'.

=cut
sub get_taggedpages {
    my $self  = shift;
    my $tag = shift;
    return $self->_get_things( 'taggedpages', tag => $tag );
}

=head2 get_tag

    $Rester->workspace('wikiname');
    $Rester->get_tag('tag');

Retrieves the specified tag from the workspace.
Note that the workspace method needs to be called first
to specify which workspace to operate on.

=cut

# REVIEW: dup with above, some
sub get_tag {
    my $self = shift;
    my $tag  = shift;

    my $accept = $self->accept || 'text/html';

    my $uri = $self->_make_uri(
        'workspacetag',
        { tag => $tag, ws => $self->workspace, }
    );

    my ( $status, $content ) = $self->_request(
        uri    => $uri,
        accept => $accept,
        method => 'GET',
    );

    if ( $status == 200 || $status == 404 ) {
        return $content;
    }
    else {
        die "$status: $content\n";
    }
}

=head2 get_breadcrumbs

    $Rester->get_breadcrumbs('workspace')

Get breadcrumbs for current user in this workspace

=cut

sub get_breadcrumbs {
    my $self = shift;

    return $self->_get_things('breadcrumbs');
}

=head2 get_workspace

    $Rester->get_workspace();

Return the metadata about a particular workspace.

=cut

sub get_workspace {
    my $self = shift;
    my $wksp = shift;

    my $prev_wksp = $self->workspace();
    $self->workspace($wksp) if $wksp;
    my $result = $self->_get_things('workspace');
    $self->workspace($prev_wksp) if $wksp;
    return $result;
}

=head2 get_workspaces

    $Rester->get_workspaces();

List all workspaces on the server

=cut

sub get_workspaces {
    my $self = shift;

    return $self->_get_things('workspaces');
}

=head2 get_user

    my $userinfo = $Rester->get_user($username);
    print $userinfo->{email_address};

Get information about a username

=cut

sub get_user {
    my $self = shift;
    my $uname = shift;

    my $uri = $self->_make_uri(
        'user',
        { user_id => $uname, ws => $self->workspace }
    );
    
    my ( $status, $content ) = $self->_request(
        uri    => $uri,
        accept => 'application/json',
        method => 'GET'
    );

    if ( $status == 200 ) {
        return decode_json( $content );
    } elsif ( $status == 404 ) {
        return $content;
    } else {
        die "$status: $content\n";
    }
}

=head2 create_user

    $Rester->create_user( { username => $username,
                            email_address => $email,
                            password => $password } );

Create a new user. Other parameters can be specified, see POD for
Socialtext::User. username is optional and will default to the email address,
as in most cases username and email_address will be the same.

=cut

sub create_user {
    my $self = shift;
    my $args = shift;

    $args->{ username } ||= $args->{ email_address };
    $args = encode_json($args);

    my ( $status, $content ) = $self->_request(
        uri     => $ROUTES{'users'},
        method  => 'POST',
        type    => 'application/json',
        content => $args
    );

    if ( $status == 201 || $status == 400 || $status == 409 ) {
        return $content;
    } else {
        die "$status: $content\n";
    }
}

=head2 add_user_to_workspace

    $Rester->add_user_to_workspace( $workspace, { username => $user, 
                                      rolename => $role,
                                      send_confirmation_invitation => 0 || 1,
                                      from_address => $from_email } );

Add a user that already exists to a workspace. rolename defaults to 'member',
send_confirmation_invitation defaults to '0'. from_address must refer to a
valid existing user, and is only needed if send_confirmation_invitation is set
to '1'. If the user is already a member of the workspace, this will reset their
role if you specify a role that's different from their current role.

=cut

sub add_user_to_workspace {
    my $self = shift;
    my $workspace = shift;
    my $args = shift;

    my $uri = $self->_make_uri(
        'workspaceusers',
        { ws => $workspace }
    );

    $args->{rolename} ||= 'member';
    $args->{send_confirmation_invitation} ||= 0;
    $args = encode_json($args);

    my ( $status, $content ) = $self->_request(
        uri     => $uri,
        method  => 'POST',
        type    => 'application/json',
        content => $args
    );

    if ( $status == 201 || $status == 400 ) {
        return $content;
    } else {
        die "$status: $content\n";
    }
}
    
=head2 get_users_for_workspace

    my @users = $Rester->get_users_for_workspace( $workspace );
    for ( @users ) { print "$_->{name}, $_->{role}, $->{is_workspace_admin}\n" }

Get a list of users in a workspace, and their roles and admin status.

=cut

sub get_users_for_workspace {
    my $self = shift;
    my $workspace = shift;

    my $uri = $self->_make_uri(
        'workspaceusers',
        { ws => $workspace }
    );
    
    my ( $status, $content ) = $self->_request(
        uri     => $uri,
        method  => 'GET',
        accept  => 'application/json'
    );

    if ( $status == 200 ) {
        return @{ decode_json( $content ) };
    } else {
        die "$status: $content\n";
    }
}

=head2 put_persontag

    $Rester->put_persontag( $person, $tag )

Tag a person.

=cut

sub put_persontag {
    my $self = shift;
    my $person = shift;
    my $tag = shift;

    my $uri = $self->_make_uri(
        'person_tag',
        { pname => $person }
    );
    
    my ( $status, $content ) = $self->_request(
        uri     => $uri,
        method  => 'POST',
        type    => 'application/json',
        content => encode_json({ tag_name => $tag }),
    );

    return if $status == 200;
    die "$status: $content\n";
}

=head2 get_persontags

    $Rester->get_persontags($person);

Retrieves all tags for a person

=cut

sub get_persontags {
    my ($self, $person, %opts) = @_;
    return $self->_get_things('person_tag',
        pname => $person,
        _query => \%opts);
}

=head2 get_people

    $Rester->get_people();

Retrieves all people.

=cut

sub get_people {
    my ($self, %opts) = @_;
    return $self->_get_things('people', _query => \%opts);
}

sub get_profile_photo {
    my $self    = shift;
    my $pname   = shift;
    my $version = shift;

    my $uri = $self->_make_uri( 'profile_photo', {
        pname => $pname,
        version => $version || 'max',
    });

    my ( $status, $content, $response ) = $self->_request(
        uri    => $uri,
        method => 'GET',
    );

    if ( $status == 200 ) {
        return $content;
    }
    else {
        die "$status: $content\n";
    }
}

=head2 get_person

    $Rester->get_person();

Retrieves a person.

=cut

sub get_person {
    my $self = shift;
    my $identifier = shift || $self->username;

    return $self->_get_things('person', pname => $identifier );
}


=head2 get_signals

    $Rester->get_signals();
    $Rester->get_signals(group_id => 42);
    $Rester->get_signals(account_id => 2);

Retrieves the list of signals.

Optional arguments are passed as query paramaters.

=cut

sub get_signals {
    my $self = shift;
    my %opts = @_;

    return $self->_get_things('signals', _query => \%opts);
}

=head2 post_signal

    $Rester->post_signal('O HAI');
    $Rester->post_signal('O HAI', group_id => 42);
    $Rester->post_signal('O HAI', group_ids => [2,3,4]);
    $Rester->post_signal('O HAI', account_id => 42);
    $Rester->post_signal('O HAI', account_ids => [2,3,4]);
    $Rester->post_signal('O HAI', in_reply_to => { signal_id => 142 });

Posts a signal.

Optional C<account_ids> and C<group_ids> arguments for targetting the signal.

Optional C<in_reply_to_id> for specifying a signal_id this signal is in reply to.

Optional C<annotations> to annotate the signal. C<annotations> should be an array
ref containing hashrefs that have one key (the annotation type) and a value that is
a hashref containing key/value pairs.

=cut

sub post_signal {
    my $self = shift;
    my $text = shift;
    my %args = @_;

    my %sig = ( signal => $text );

    for my $k (qw(account_id group_id)) {
        my @ids = @{ $args{$k.'s'} || [] };
        push @ids, $args{$k} if $args{$k}; # must be non-zero
        $sig{$k.'s'} = \@ids if @ids;
    }

    for my $k (qw(in_reply_to annotations attachments)) {
        next unless exists $args{$k};
        $sig{$k} = $args{$k};
    }

    my $uri = $self->_make_uri('signals');
    my ( $status, $content, $response ) = $self->_request(
        uri     => $uri,
        method  => 'POST',
        type    => "application/json",
        content => encode_json( \%sig ),
    );

    my $location = $response->header('location');
    $location = URI::Escape::uri_unescape($1);

    if ( $status == 204 || $status == 201 ) {
        return $location;
    }
    else {
        die "$status: $content\n";
    }
}

=head2 post_webhook

    $Rester->post_webhook( %args )

Creates a webhook.  Args will be encoded as JSON and put up.

=cut

sub post_webhook {
    my $self = shift;
    my %args = @_;

    my $uri = $self->_make_uri('webhooks');
    my ( $status, $content, $response ) = $self->_request(
        uri     => $uri,
        method  => 'POST',
        type    => "application/json",
        content => encode_json( \%args ),
    );

    if ( $status == 204 || $status == 201 ) {
        return $response->header('Location');
    }
    else {
        die "$status: $content\n";
    }
}

=head2 get_webhooks

    my $hooks = $Rester->get_webhooks();

Returns an arrayref containing hashrefs of each webhook on the server.

=cut

sub get_webhooks {
    my $self = shift;

    my $uri = $self->_make_uri('webhooks');
    my ( $status, $content, $response ) = $self->_request(
        uri     => $uri,
        method  => 'GET',
        type    => "application/json",
    );

    if ( $status == 200 ) {
        return decode_json($content);
    }
    else {
        die "$status: $content\n";
    }
}

=head2 delete_webhook

    $Rester->delete_webhook( id => $webhook_id );

Deletes the specified webhook.

=cut

sub delete_webhook {
    my $self = shift;
    my %args = @_;
    die "id is mandatory" unless $args{id};

    my $uri = $self->_make_uri('webhook', {id => $args{id}});
    my ( $status, $content, $response ) = $self->_request(
        uri     => $uri,
        method  => 'DELETE',
    );

    if ( $status == 204 ) {
        return;
    }
    else {
        die "$status: $content\n";
    }
}

sub _request {
    my $self = shift;
    my %p    = @_;
    my $ua   = LWP::UserAgent->new(agent => $self->agent_string);
    my $server = $self->server;
    die "No server defined!\n" unless $server;
    $server =~ s#/$##;
    my $uri  = "$server$p{uri}";
    warn "uri: $uri\n" if $self->verbose;

    my $request = HTTP::Request->new( $p{method}, $uri );
    if ( !$self->siteminder ) {
        if ( $self->user_cookie ) {
            $request->header( 'Cookie' => 'NLW-user=' . $self->user_cookie );
        }
        else {
            $request->authorization_basic( $self->username, $self->password );
        }
    }
    $request->header( 'Accept'       => $p{accept} )   if $p{accept};
    $request->header( 'Content-Type' => $p{type} )     if $p{type};
    $request->header( 'If-Match'     => $p{if_match} ) if $p{if_match};
    $request->header( 'X-On-Behalf-Of' => $self->on_behalf_of ) if $self->on_behalf_of;
    foreach my $key (keys %{$self->additional_headers}) {
        $request->header($key => $self->additional_headers->{$key});
    }

    if ($p{method} eq 'PUT') {
        my $content_len = 0;
        $content_len = do { use bytes; length $p{content} } if $p{content};
        $request->header( 'Content-Length' => $content_len );
    }

    if (my $cookie = $self->cookie) {
        $request->header('cookie' => $cookie);
    }
    $request->content( $p{content} ) if $p{content};
    $self->response( $ua->simple_request($request) );

    if ( $self->http_header_debug ) {
        use Data::Dumper;
        warn "Code: "
            . $self->response->code . "\n"
            . Dumper $self->response->headers;
    }

    # We should refactor to not return these response things
    return ( $self->response->code, $self->response->content,
        $self->response );
}

=head2 response

    my $resp = $Rester->response;

Return the HTTP::Response object from the last request.

=head1 AUTHORS / MAINTAINERS

Shawn Devlin C<< <shawn.devlin@socialtext.com> >>

Kevin Jones C<< <kevin.jones@socialtext.com> >>

Brandon Noard C<< <brandon.noard@socialtext.com> >>

=head2 CONTRIBUTORS

Luke Closs

Jeremy Stashewsky

Chris Dent

Kirsten Jones

Michele Berg - get_revisions()

=cut

1;

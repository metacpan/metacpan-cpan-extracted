=head1 NAME

Net::Backpack - Perl extension for interfacing with Backpack.

=head1 SYNOPSIS

    use strict; use warnings;
    use Net::Backpack;

    my $bp = Net::Backpack(
        user  => $your_backpack_username,
        token => $your_backpack_api_token,
        ssl   => $use_ssl
    );

    # Fill out a Perl data structure with information about your Backspace pages.
    my $std_pages = $bp->list_all_pages;

    # Alternatively get the same information in XML format
    my $xml_pages = $bp->list_all_pages(xml => 1);

    # Create a new page
    my $page = $bp->create_page(
        title       => 'A test page',
        description => 'Created with the Backpack API'
    );

    # Get the id of the new page
    my $page_id = $page->{page}{id};

    # Get details of the new page (in XML format)
    my $page_xml = $bp->show_page(id => $page->{page}{id});

    # Rename the page
    $bp->update_title(
        id    => $page_id,
        title => 'A new title'
    );

    # Change the body
    $bp->update_description(
        id          => $page_id,
        description => 'Something new'
    );

    # Remove the page
    $bp->destroy_page(id => $page_id);

=head1 DESCRIPTION

Net::Backpack provides a thin Perl wrapper around the L<Backpack API|http://backpackit.com/api>.
Currently it only implements the parts of the API that manipulate Backpack pages.
Future releases will increase the coverage.

=head2 Getting Started

In order to use the Backpack API, you'll need to have a Backpack API token.And in
order to get one of those, you'll need a Backpack account.But then again, the API
will be pretty  useless to you if you don't have a Backpack account to manipulate
with it.

You can get a Backpack account from L<here|http://backbackit.com/signup>.

=head2 Backback API

The Backpack API is  based on XML over HTTP. You send an XML message over HTTP to
the Backpack server  and the server sends a response to you which is also in XML.
The format of the various XML requests and responses are defined L<here|http://backpackit.com/api>.

This module removes the need to deal with any XML.You create an object to talk to
the Backpack server and  call  methods on that object to manipulate your Backpage
pages. The values  returned  from Backpack are  converted to Perl data structures
before being handed back to you (although it is also possible to get back the raw
XML).

=head1 IMPORTANT NOTE

C<Net::Backpack>  uses  L<XML::Simple>  to  parse  the data that is returned from
Backpack.From version 1.10 of C<Net::Backpack> has changed.By default we now pass
the parameter C<ForceArray =E<gt> 1> to L<XML::Simple>. This will change the Perl
data structure returned by most calls.

To get the old behaviour back, you can pass the parameter C<forcearray =E<gt> 0>
to the C<new> function.

=cut

package Net::Backpack;

use 5.006;
use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use HTTP::Request;
use XML::Simple;

our $VERSION = '1.15';

my %data = (
	    'list_all_pages' =>
	    {
	     url => '/ws/pages/all',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'create_page' =>
	    {
	     url => '/ws/pages/new',
	     req => '<request>
  <token>[S:token]</token>
  <page>
    <title>[P:title]</title>
    <description>[P:description]</description>
  </page>
</request>'
	    },
	    'show_page' =>
	    {
	     url => '/ws/page/[P:id]',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'destroy_page' =>
	    {
	     url => '/ws/page/[P:id]/destroy',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'update_title' =>
	    {
	     url => '/ws/page/[P:id]/update_title',
	     req => '<request>
  <token>[S:token]</token>
  <page><title>[P:title]</title></page>
</request>'
	    },
	    update_body =>
	    {
	     url => '/ws/page/[P:id]/update_body',
	     req => '<request>
  <token>[S:token]</token>
  <page><description>[P:description]</description></page>
</request>'
	    },
	    'duplicate_page' =>
	    {
	     url => '/ws/page/[P:id]/duplicate',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'link_page' =>
	    {
	     url => '/ws/page/[P:to_page]/link',
	     req => '<request>
  <token>[S:token]</token>
  <linked_page_id>[P:link_page]</linked_page_id>
</request>'
	    },
	    'unlink_page' =>
	    {
	     url => '/ws/page/[P:from_page]/link',
	     req => '<request>
  <token>[S:token]</token>
  <linked_page_id>[P:link_page]</linked_page_id>
</request>'
	    },
	    'share_people' =>
	    {
	     url => '/ws/page/[P:id]/share',
	     req => '<request>
  <token>[S:token]</token>
  <email_addresses>
    [P:people]
  </email_addresses>
</request>'
	    },
	    'make_page_public' =>
	    {
	     url => '/ws/page/[P:id]/share',
	     req => '<request>
  <token>[S:token]</token>
  <page>
    <public>[P:public]</public>
  </page>
</request>'
	    },
	    'unshare_friend_page' =>
	    {
	     url => '/ws/page/[P:id]/unshare_friend_page',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'email_page' =>
	    {
	     url => '/ws/page/[P:id]/email',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'list_all_items' =>
	    {
	     url => '/ws/page/[P:page_id]/items/list',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'create_item' =>
	    {
	     url => '/ws/page/[P:page_id]/items/add',
	     req => '<request>
  <token>[S:token]</token>
  <item>
    <content>[P:item]</content>
  </item>
</request>'
	    },
	    'update_item' =>
	    {
	     url => '/ws/page/[P:page_id]/items/update/[P:id]',
	     req => '<request>
  <token>[S:token]</token>
  <item>
    <content>[P:item]</content>
  </item>
</request>'
	    },
	    'toggle_item' =>
	    {
	     url => '/ws/page/[P:page_id]/items/toggle/[P:id]',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'destroy_item' =>
	    {
	     url => '/ws/page/[P:page_id]/items/destroy/[P:id]',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'move_item' =>
	    {
	     url => '/ws/page/[P:page_id]/items/move/[P:id]',
	     req => '<request>
  <token>[S:token]</token>
  <direction>[P:direction]</direction>
</request>'
	    },
	    'list_all_notes' =>
	    {
	     url => '/ws/page/[P:page_id]/notes/list',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'create_note' =>
	    {
	     url => '/ws/page/[P:page_id]/notes/create',
	     req => '<request>
  <token>[S:token]</token>
  <note>
    <title>[P:title]</title>
    <body>[P:body]</body>
  </note>
</request>'
	    },
	    'update_note' =>
	    {
	     url => '/ws/page/[P:page_id]/notes/update/[P:id]',
	     req => '<request>
  <token>[S:token]</token>
  <note>
    <title>[P:title]</title>
    <body>[P:body]</body>
  </note>
</request>'
	    },
	    'destroy_note' =>
	    {
	     url => '/ws/page/[P:page_id]/notes/destroy/[P:id]',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'get_tag_pages' =>
	    {
	     url => '/ws/tags/[P:page_id]',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'set_page_tags' =>
	    {
	     url => '/ws/page/[P:page_id]/tags/tag',
	     req => '<request>
  <token>[S:token]</token>
  <tags>[P:tags]</tags>
</request>'
	    },
	    'upcoming_reminders' =>
	    {
	     url => '/ws/reminders',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'create_reminder' =>
	    {
	     url => '/ws/reminders/create',
	     req => '<request>
  <token>[S:token]</token>
  <reminder>
    <content>[P:content]</content>
	<remind_at>[P:remind_at]</remind_at>
  </reminder>
</request>'
	    },
	    'update_reminder' =>
	    {
	     url => '/ws/reminders/update/[P:id]',
	     req => '<request>
  <token>[S:token]</token>
  <reminder>
    <content>[P:content]</content>
	<remind_at>[P:remind_at]</remind_at>
  </reminder>
</request>'
	    },
	    'destroy_reminder' =>
	    {
	     url => '/ws/reminders/destroy/[P:id]',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'list_all_emails' =>
	    {
	     url => '/ws/page/[P:page_id]/emails/list',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'show_email' =>
	    {
	     url => '/ws/page/[P:page_id]/emails/show/[P:id]',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'destroy_email' =>
	    {
	     url => '/ws/page/[P:page_id]/emails/destroy/[P:id]',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'export' =>
	    {
	     url => '/ws/account/export',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'list_all_lists' =>
	    {
	     url => '/ws/page/[P:page_id]/lists/list',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'list_this_list' =>
	    {
	     url => '/ws/page/[P:page_id]/items/list?list_id=[P:list_id]',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'create_list' =>
	    {
	     url => '/ws/page/[P:page_id]/lists/add',
	     req => '<request>
  <token>[S:token]</token>
    <name>[P:title]</name>
</request>'
	    },
	    'update_list' =>
	    {
	     url => '/ws/page/[P:page_id]/lists/update/[P:list_id]',
	     req =>	'<request>
  <token>[S:token]</token>
  <list>
    <name>[P:title]</name>
  </list>
</request>'
	    },
	    'destroy_list' =>
	    {
	     url => '/ws/page/[P:page_id]/lists/destroy/[P:list_id]',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'create_list_item' =>
	    {
	     url => '/ws/page/[P:page_id]/items/add?list_id=[P:list_id]',
	     req =>	'<request>
  <token>[S:token]</token>
  <item>
    <content>[P:item]</content>
  </item>
</request>'
	    },
	   );

=head1 METHODS

=head2 new(%params)

Creates a new Net::Backpack object. All communication with the Backpack server is
made through this object.

Takes two mandatory arguments,your Backpack API token and your Backpack username.
Returns the new C<Net:Backpack> object.

There is  also  an optional parameter, forcearray. This controls the value of the
C<ForceArray> parameter that is used by C<XML::Simple>. The default value is 1.

If the C<ssl> parameter is provided, then communication will take place over SSL.
This is required for Plus and Premium accounts.

    my $bp = Net::Backpack->new(
        token      => $token,
        user       => $user,
        forcearray => 0,
        ssl        => 0
    );

=cut

sub new {
    my $class  = shift;
    my %params = @_;

    my $self;
    $self->{token} = $params{token}
    || croak "No Backpack API token passed Net::Backpack::new\n";
    $self->{user}  = $params{user}
    || croak "No Backpack API user passed Net::Backpack::new\n";

    $self->{protocol}   = $params{ssl} ? 'https' : 'http';
    $self->{forcearray} = $params{forcearray} || 1;

    $self->{ua} = LWP::UserAgent->new;
    $self->{ua}->env_proxy;
    $self->{ua}->default_header('X-POST-DATA-FORMAT' => 'xml');

    $self->{base_url} = "$self->{protocol}://$self->{user}.backpackit.com";

    return bless $self, $class;
}

=head2 list_all_pages(%params)

Get a list of all of your Backpack pages.Returns a Perl data structure unless the
C<xml> parameter is true, in which case it returns the raw XML as returned by the
Backpack server.

    my $bp = Net::Backpack->new(
        token      => $token,
        user       => $user,
        forcearray => 0,
        ssl        => 0
    );

    $pages = $bp->list_all_pages(xml => 1);

=cut

sub list_all_pages {
    my $self   = shift;
    my %params = @_;

    my $req_data = $data{list_all_pages};
    my $url = $self->{base_url} . $req_data->{url};

    my $req = HTTP::Request->new('POST', $url);
    $req->content($self->_expand($req_data->{req}, %params));

    return $self->_call(%params, req => $req);
}

=head2 create_page(%param)

Create a new Backpack page with the given title and (optional) description.Returns
a Perl data structure unless the C<xml> parameter is true,in which case it returns
the raw XML as returned by the Backpack server.


    my $bp = Net::Backpack->new(
        token      => $token,
        user       => $user,
        forcearray => 0,
        ssl        => 0
    );

    my $page = $bp->create_page(
        title       => $title,
        description => $desc,
        xml         => 1
    );

=cut

sub create_page {
    my $self = shift;
    my %params = @_;

    croak 'No title for new page' unless $params{title};
    $params{description} ||= '';

    my $req_data = $data{create_page};
    my $url   = $self->{base_url} . $req_data->{url};

    my $req   = HTTP::Request->new(POST => $url);
    $req->content($self->_expand($req_data->{req}, %params));

    return $self->_call(%params, req => $req);
}

=head2 $rc = $bp->show_page(id => $id, [xml => 1]);

Get details of the Backpack page with the given id. Returns a Perl data
structure unless the C<xml> parameter is true, in which case it returns the
raw XML as returned by the Backpack server.

=cut

sub show_page {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{id};

  my $req_data = $data{show_page};
  my $url   = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $rc = $bp->destroy_page(id => $id, [xml => 1]);

Delete the Backpack page with the given id. Returns a Perl data structure
unless the C<xml> parameter is true, in which case it returns the raw XML
as returned by the Backpack server.

=cut

sub destroy_page {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{id};

  my $req_data = $data{destroy_page};
  my $url   = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $rc = $bp->update_title(id => $id, title => $title, [xml => 1]);

Update the title of the given Backpack page. Returns a Perl data structure
unless the C<xml> parameter is true, in which case it returns the raw XML
as returned by the Backpack server.

=cut

sub update_title {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{id};
  croak 'No title' unless $params{title};

  my $req_data = $data{update_title};
  my $url   = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $rc = $bp->update_body(id => $id, description => $desc, [xml => 1]);

Update the description of the given Backpack page. Returns a Perl data
structure unless the C<xml> parameter is true, in which case it returns the
raw XML as returned by the Backpack server.

=cut

sub update_body {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{id};
  croak 'No description' unless defined $params{description};

  my $req_data = $data{update_body};
  my $url   = $self->{base_url} .$self->_expand($req_data->{url}, %params);
  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $page = $bp->duplicate_page(id => $id, [xml => 1]);

Create a duplicate of the given Backpack page. Returns a Perl data
structure unless the C<xml> parameter is true, in which case it returns the
raw XML as returned by the Backpack server.

=cut

sub duplicate_page {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{id};

  my $req_data = $data{duplicate_page};
  my $url   = $self->{base_url} . $self->_expand($req_data->{url}, %params);
  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $rc = $bp->link_page(link_page => $id1, to_page => $id2, [xml => 1]);

Link one Backpack page to another. Returns a Perl data structure unless the
C<xml> parameter is true, in which case it returns the raw XML as returned
by the Backpack server.

=cut

sub link_page {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{link_page} and $params{to_page};

  my $req_data = $data{link_page};
  my $url   = $self->{base_url} . $self->_expand($req_data->{url}, %params);
  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $rc = $bp->unlink_page(link_page => $id1, from_page => $id2,
                              [xml => 1]);

Unlink one Backpack page from another. Returns a Perl data structure unless
the C<xml> parameter is true, in which case it returns the raw XML as returned
by the Backpack server.

=cut

sub unlink_page {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{link_page} and $params{from_page};

  my $req_data = $data{unlink_page};
  my $url   = $self->{base_url} . $self->_expand($req_data->{url}, %params);
  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $rc = $bp->share_page(id => $id, people => \@people,
                             [ xml => 1 ]);

Share a given Backpack page with a list of other people. The parameter
'people' is a list of email addresses of the people you wish to share the
page with.

=cut

sub share_page {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{id};
  croak 'No people' unless scalar @{$params{people}};

  $params{people} = join "\n", @{$params{people}};
  my $req_data = $data{share_people};
  my $url   = $self->{base_url} . $self->_expand($req_data->{url}, %params);
  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $rc = $bp->make_page_public(id => $id, public => $public,
                                   [ xml => 1 ]);

Make a given Backpage page public or private. The parameter 'public' is
a boolean flag indicating whether the page should be made public or
private

=cut

sub make_page_public {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{id};
  croak 'No public flag' unless exists $params{public};

  $params{public} = !!$params{public};
  my $req_data = $data{make_page_public};
  my $url   = $self->{base_url} . $self->_expand($req_data->{url}, %params);
  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $rc = $bp->unshare_friend_page(id => $id, [ xml => 1 ]);

Unshare yourself from a friend's page.

=cut

sub unshare_friend_page {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{id};

  my $req_data = $data{unshare_friend_page};
  my $url   = $self->{base_url} . $self->_expand($req_data->{url}, %params);
  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}


=head2 $rc = $bp->email_page(id => $id, [ xml => 1 ]);

Email a page to yourself.

=cut

sub email_page {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{id};

  my $req_data = $data{email_page};
  my $url   = $self->{base_url} . $self->_expand($req_data->{url}, %params);
  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $items = $bp->list_all_items(page_id => $page_id, [xml => 1]);

Get a list of all of your Backpack checklist items. Returns a Perl data structure
unless the C<xml> parameter is true, in which case it returns the raw
XML as returned by the Backpack server.

=cut

sub list_all_items {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{page_id};

  my $req_data = $data{list_all_items};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $item = $bp->create_item(page_id => $page_id, item => $item, [xml => 1]);

Create a Backpack checklist item given a page id and some item content.
Returns a Perl data structure unless the C<xml> parameter is true, in which case
it returns the raw XML as returned by the Backpack server.

=cut

sub create_item {
  my $self = shift;
  my %params = @_;

  croak 'No page id' unless $params{page_id};
  croak 'No item content' unless $params{item};

  my $req_data = $data{create_item};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $item = $bp->update_item(page_id => $page_id, item => $item, [xml => 1]
                                id => $item_id);

Updates a Backpack checklist item given a page id, item id, and new content.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Backpack server.

=cut

sub update_item {
  my $self = shift;
  my %params = @_;

  croak 'No page id' unless $params{page_id};
  croak 'No item id' unless $params{id};
  croak 'No item content' unless $params{item};

  my $req_data = $data{update_item};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $response = $bp->toggle_item(page_id => $page_id, id => $item_id,
                                    [xml => 1]);

Toggles a Backpack checklist item given a page id and an item id.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Backpack server.

=cut

sub toggle_item {
  my $self = shift;
  my %params = @_;

  croak 'No page id' unless $params{page_id};
  croak 'No item id' unless $params{id};

  my $req_data = $data{toggle_item};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $response = $bp->destroy_item(page_id => $page_id, id => $item_id,
                                     [xml => 1]);

Destroys a Backpack checklist item given a page id and an item id.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Backpack server.

=cut

sub destroy_item {
  my $self = shift;
  my %params = @_;

  croak 'No page id' unless $params{page_id};
  croak 'No item id' unless $params{id};

  my $req_data = $data{destroy_item};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $response = $bp->move_item(page_id => $page_id, id => $item_id,
                                  direction => $direction, [xml => 1]);

Modifies the location in the list of a Backpack checklist item. Requires a
page id, a direction and an item id. Valid values for direction are
"move_lower", "move_higher", "move_to_top", and "move_to_bottom". Returns a
Perl data structure unless the C<xml> parameter is true, in which case it
returns the raw XML as returned by the Backpack server.

=cut

sub move_item {
  my $self = shift;
  my %params = @_;

  croak 'No page id' unless $params{page_id};
  croak 'No item id' unless $params{id};
  unless (exists $params{direction} &&
          $params{direction} =~ /move_(lower|higher|to_top|to_bottom)/) {
    croak 'No direction specified';
  }

  my $req_data = $data{move_item};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);
  #print "url : $url\n";
  #sleep 2;
  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $notes = $bp->list_all_notes(page_id => $page_id, [xml => 1]);

Get a list of all of your Backpack notes. Returns a Perl data structure
unless the C<xml> parameter is true, in which case it returns the raw
XML as returned by the Backpack server.

=cut

sub list_all_notes {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{page_id};

  my $req_data = $data{list_all_notes};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $note = $bp->create_note(page_id => $page_id, title => $title,
                                body => $body, [xml => 1]);

Create a Backpack note given a page id and some content. Title is required,
body is optional. Returns a Perl data structure unless the C<xml> parameter
is true, in which case it returns the raw XML as returned by the Backpack
server.

=cut

sub create_note {
  my $self = shift;
  my %params = @_;

  croak 'No page id' unless $params{page_id};
  croak 'No note title' unless $params{title};

  $params{body} ||= "";

  my $req_data = $data{create_note};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  print "url: $url\n";

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $note = $bp->update_note(page_id => $page_id, id => $note_id, [xml => 1]
                                title => $title, body => $body);

Updates a Backpack note given a page id, note id, and new content.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Backpack server.

=cut

sub update_note {
  my $self = shift;
  my %params = @_;

  croak 'No page id' unless $params{page_id};
  croak 'No note id' unless $params{id};

  $params{title} ||= "";
  $params{body} ||= "";

  my $req_data = $data{update_note};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $response = $bp->destroy_note(page_id => $page_id, id => $note_id,
                                     [xml => 1]);

Destroys a Backpack note given a page id and an note id.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Backpack server.

=cut

sub destroy_note {
  my $self = shift;
  my %params = @_;

  croak 'No page id' unless $params{page_id};
  croak 'No note id' unless $params{id};

  my $req_data = $data{destroy_note};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $pages = $bp->get_tag_pages(page_id => $id, [ xml => 1 ]);

Retrieve all the pages associated with a particular tag id. Returns a Perl
data structure unless the C<xml> parameter is true, in which case it returns
the raw XML as returned by the Backpack server.

=cut

sub get_tag_pages {
  my $self = shift;
  my %params = @_;

  croak 'No page id' unless $params{page_id};

  my $req_data = $data{get_tag_pages};
  my $url   = $self->{base_url} . $self->_expand($req_data->{url}, %params);
  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $response = $bp->set_page_tags(page_id => $id, tags => \@tags,
                                         [ xml => 1 ]);

Set the tags for a given Backpack page. This method overwrites all tags for
the page. An empty set of tags serves to remove all the tags for the page.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Backpack server.

This is currently returning true, and though it seems to create and submit a
valid request, the tags are not being updated.

=cut

sub set_page_tags {
  my $self = shift;
  my %params = @_;

  croak 'No page id' unless $params{page_id};

  $params{tags} = join "\n", map { '"'.$_.'"' } @{$params{tags}};
  my $req_data = $data{set_page_tags};

  my $url   = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  # print $url.$self->_expand($req_data->{req}, %params);

  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $reminders = $bp->upcoming_reminders([ xml => 1 ]);

Gets the upcoming Backpack reminders for an account, in the time zone
specified per the account's settings.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Backpack server.

=cut

sub upcoming_reminders {
  my $self = shift;
  my %params = @_;

  my $req_data = $data{upcoming_reminders};

  my $url   = $self->{base_url} . $self->_expand($req_data->{url});
  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $reminder = $bp->create_reminder(content => $reminder, [xml => 1],
                                        [remind_at => $remind_at]);

Create a Backpack reminder given some reminder content. The content
takes fuzzy date/times like "+30 Do foo and bar" to set the reminder for 30
minutes from now. Optionally, specify a date in a relatively parseable date
format and use the remind_at parameter instead.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Backpack server.

=cut

sub create_reminder {
  my $self = shift;
  my %params = @_;

  croak 'No reminder content' unless $params{content};

  $params{remind_at} ||= "";

  my $req_data = $data{create_reminder};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $reminder = $bp->update_reminder(id => $reminder_id,
                                        [content => $reminder], [xml => 1],
                                        [remind_at => $remind_at);

Update a Backpack reminder given a reminder id. The content takes fuzzy
date/times like "+30 Do foo and bar" to set the reminder for 30 minutes
from now. Optionally, specify a date in a relatively parseable date format
and use the remind_at parameter instead.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Backpack server.

=cut

sub update_reminder {
  my $self = shift;
  my %params = @_;

  croak 'No reminder id' unless $params{id};
  unless (exists $params{content} && exists $params{remind_at}) {
    my $reminders = $self->upcoming_reminders();
    $params{content} ||=
      $reminders->{reminders}{reminder}{$params{id}}{content};
    $params{remind_at} ||=
      $reminders->{reminders}{reminder}{$params{id}}{remind_at};
  }

  my $req_data = $data{update_reminder};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $response = $bp->destroy_reminder( id => $reminder_id,  [xml => 1]);

Destroys a Backpack reminder given a reminder id.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Backpack server.

=cut

sub destroy_reminder {
  my $self = shift;
  my %params = @_;

  croak 'No reminder id' unless $params{id};

  my $req_data = $data{destroy_reminder};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $emails = $bp->list_all_emails(page_id => $page_id, [xml => 1]);

Get a list of all of your Backpack email items for a page. Returns a Perl
data structure unless the C<xml> parameter is true, in which case it returns
the raw XML as returned by the Backpack server.

=cut

sub list_all_emails {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{page_id};

  my $req_data = $data{list_all_emails};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $email = $bp->show_email(page_id => $page_id, id => $reminder_id,
                                [xml => 1]);

Returns a Backpack email item given a page id and an email id.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Backpack server.

=cut

sub show_email {
  my $self = shift;
  my %params = @_;

  croak 'No page id' unless $params{page_id};
  croak 'No email id' unless $params{id};

  my $req_data = $data{show_email};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $response = $bp->destroy_email(page_id => $page_id, id => $reminder_id,
                                      [xml => 1]);

Destroys a Backpack email item for a page given a page id and an email id.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Backpack server.

=cut

sub destroy_email {
  my $self = shift;
  my %params = @_;

  croak 'No page id' unless $params{page_id};
  croak 'No email id' unless $params{id};

  my $req_data = $data{destroy_email};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $exported_bp = $bp->export([xml => 1]);

Exports an account's entire Backpack. Returns a Perl data structure
unless the C<xml> parameter is true, in which case it returns the raw
XML as returned by the Backpack server.

=cut

sub export {
  my $self = shift;
  my %params = @_;

  my $req_data = $data{export};
  my $url = $self->{base_url} . $req_data->{url};

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $lists = $bp->list_all_lists(page_id => $page_id, [xml => 1]);

Get a list of *all* of your Backpack checklists for a specific page.
Returns a Perl data structure unless the C<xml> parameter is true,
in which case it returns the raw XML as returned by the Backpack server.

=cut

sub list_all_lists {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{page_id};

  my $req_data = $data{list_all_lists};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $list = $bp->list_this_list(page_id => $page_id, list_id => $list_id, [xml => 1]);

Get details of a specific list with the given list_id on a specific Backpack
page with the given page_id. Returns a Perl data structure unless the C<xml>
parameter is true, in which case it returns the raw XML as returned by the
Backpack server.

=cut

sub list_this_list {
  my $self = shift;
  my %params = @_;

  croak 'No page id' unless $params{page_id};
  croak 'No list id' unless $params{list_id};

  my $req_data = $data{list_this_list};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $list = $bp->create_list(page_id => $page_id, title => $title, [xml => 1]);

Create a new Backpack checklist given a page id and a list title.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Backpack server.

=cut

sub create_list {
  my $self = shift;
  my %params = @_;

  croak 'No page id' unless $params{page_id};
  croak 'No list title' unless $params{title};

  my $req_data = $data{create_list};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $list = $bp->update_list(page_id => $page_id, list_id => $list_id, title => $title, [xml => 1]);

Update the title of a specific list with the given list_id on a specific
Backpack page with the given page_id. Returns a Perl data structure unless
the C<xml> parameter is true, in which case it returns the raw XML as
returned by the Backpack server.

=cut

sub update_list {
  my $self = shift;
  my %params = @_;

  croak 'No page id' unless $params{page_id};
  croak 'No list id' unless $params{list_id};
  croak 'No title' unless $params{title};

  my $req_data = $data{update_list};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $list = $bp->destroy_list(page_id => $page_id, list_id => $list_id, [xml => 1]);

Destroy a specific list with the given list_id on a specific Backpack page
with the given page_id. Returns a Perl data structure unless the C<xml>
parameter is true, in which case it returns the raw XML as returned by the
Backpack server.

=cut

sub destroy_list {
  my $self = shift;
  my %params = @_;

  croak 'No page id' unless $params{page_id};
  croak 'No list id' unless $params{list_id};

  my $req_data = $data{destroy_list};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $list = $bp->create_list_item(page_id => $page_id, list_id => $list_id, item = $item, [xml => 1]);

Create an item on a specific list with the given list_id on a specific
Backpack page with the given page_id. This differs from the usual
"create_item" function in that you can specify which list on a page you want
to add the item to. Returns a Perl data structure unless the C<xml> parameter
is true, in which case it returns the raw XML as returned by the Backpack
server.

=cut

sub create_list_item {
  my $self = shift;
  my %params = @_;

  croak 'No page id' unless $params{page_id};
  croak 'No list id' unless $params{list_id};
  croak 'No item content' unless $params{item};

  my $req_data = $data{create_list_item};
  my $url      = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}


sub _call {
  my $self = shift;
  my %params = @_;

  my $resp = $self->{ua}->request($params{req});
  my $xml = $resp->content;

  if ($params{xml}) {
    return $xml;
  } else {
    my $data = XMLin($xml, ForceArray => $self->{forcearray});
    return $data;
  }
}

sub _expand {
  my $self = shift;
  my $string = shift;
  my %params = @_;

  $string =~ s/\[S:(\w+)]/$self->{$1}/g;
  $string =~ s/\[P:(\w+)]/$params{$1}/g;

  return $string;
}

=head1 AUTHOR

Dave Cross E<lt>dave@dave@mag-sol.comE<gt>

Please feel free to email me to tell me how you are using the module.

Lots of stuff implemented by neshura when I was being too tardy!

Currently maintained by Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/net-backpack>

=head1 BUGS

Please report bugs by email to E<lt>bug-Net-Backpack@rt.cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2005, Dave Cross.  All Rights Reserved.

This script is  free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=head1 SEE ALSO

L<http://backpackit.com/>, L<http://backpackit.com/api>

=cut

1;
__END__

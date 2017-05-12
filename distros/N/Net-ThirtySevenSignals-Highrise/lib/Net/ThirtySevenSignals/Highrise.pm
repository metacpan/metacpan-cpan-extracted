# $Id: Backpack.pm 29 2008-07-13 10:35:47Z dave $

=head1 NAME

Net::ThirtySevenSignals::Highrise - Perl extension for talking 37Signals' Highrise API

=head1 SYNOPSIS

  use Net::ThirtySevenSignals::Highrise;

  my $hr = Net::ThirtySevenSignals::Highrise(
                         user  => $your_highrise_url_prefix,
                         token => $your_highrise_api_token,
                         ssl   => $use_ssl);

  # Fill out a Perl data structure with information about
  my $people = $hr->list_all_people;

  # return a hashref of people
  my $people = $hr->people_list_by_criteria(email => 'danny@example.com');


=head1 DESCRIPTION

Net::ThirtySevenSignals::Highrise provides a thin Perl wrapper around the Highrise API
(L<http://developer.37signals.com/highrise/>). Currently it only implements a very few
API points. 

The API is unstable at this time.


=head2 Getting Started

In order to use the Highrise API, you'll need to have a Highrise
API token. And in order to get one of those, you'll need a Highrise
account. But then again, the API will be pretty useless to you if
you don't have a Highrise account to manipulate with it.

You can get a Highrise account from L<http://highrisehq.com>.

=head2 Highrise API

The Highrise API is based on XML over HTTP. You send an XML message
over HTTP to the Highrise server and the server sends a response to
you which is also in XML. The format of the various XML requests and
responses are defined at L<http://developer.37signals.com/highrise/>

This module removes the need to deal with any XML. You create an
object to talk to the Highrise server and call methods on that object
to manipulate your data. The values returned from Highrise
are converted to Perl data structures before being handed back to
you (although it is also possible to get back the raw XML).

=head1 XML

To get the XML back from the API, you can pass the parameter C<forcearray
=E<gt> 0> to the C<new> function.

=cut

package Net::ThirtySevenSignals::Highrise;
{
  $Net::ThirtySevenSignals::Highrise::VERSION = '0.03';
}

use 5.006;
use utf8;
use strict qw(vars subs);
no warnings;
use warnings qw(FATAL closed threads internal debugging pack malloc
                  portable prototype inplace io pipe unpack regexp
                  deprecated glob digit printf layer
                  reserved taint closure semicolon);
no warnings qw(exec newline unopened);

use Carp;
use LWP::UserAgent;
use URI;
use HTTP::Request;
use XML::Simple;
# use Log::Log4perl qw( get_logger );

# my $logger = get_logger();


my %data = (
    'people_list_all' =>
    {
	url => '/people.xml',
	return_key => 'person',
    },
    
    'person_get' =>
    {
	url => '/people/[P:id].xml',
    },


    tag_add =>{
	url => '/[P:subjectType]/[P:subjectID]/tags.xml',
	method => "POST",
	req => '<name>[P:tagName]</name>'
    },

    'person_create' =>
    {
	url => '/people.xml?reload=true',
	req => '
<person>
  <first-name>[P:firstName]</first-name>
  <last-name>[P:lastName]</last-name>
  <company-name>[P:companyName]</company-name>
  <contact-data>

    [% IF P:emailAddress %]
    <email-addresses>
      <email-address>
        <address>[P:emailAddress]</address>
        <location>Work</location>
      </email-address>
    </email-addresses>
    [% END %]


    [% IF P:workPhone %]
   <phone-numbers>
      <phone-number>
        <number>[P:workPhone]</number>
        <location>Work</location>
      </phone-number>
    </phone-numbers>
    [% END %]

  </contact-data>
</person>'
    },

    'person_destroy' =>
    {
	method => "DELETE",
	url => '/people/[P:id].xml',
    },

    'people_list_by_criteria' =>
    {
	url => '/people/search.xml',
	return_key => 'person',
    },

    'tags_list_all' =>
    {
	url => '/tags.xml',
	return_key=>'tag',
    },
    
    
    'tags_list_for_subject' =>
    {
	url => '/[P:subjectType]/[P:subjectID]/tags.xml',
	required_params => [qw(subjectType subjectID )],
	return_key => 'tag',
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

=head2 $hr = Net::ThirtySevenSignals::Highrise->new(token => $token, user => $user, [forcearray => 0], ssl => 0);

Creates a new Net::ThirtySevenSignals::Highrise object. All communication with the
Highrise server is made through this object.

Takes two mandatory arguments, your Highrise API token and your
Highrise username. Returns the new Net:Highrise object.

There is also an optional parameter, forcearray. This controls the
value of the C<ForceArray> parameter that is used by C<XML::Simple>. The 
default value is 1.

If the C<ssl> parameter is provided, then communication will take
place over SSL.  This is required for Plus and Premium accounts.

=cut

sub new {
  my $class = shift;
  my %params = @_;

  my $self;
  $self->{debug} = $params{debug};
  $self->{token} = $params{token}
    || croak "No Highrise API token passed Net::ThirtySevenSignals::Highrise::new\n";
  $self->{user}  = $params{user}
    || croak "No Highrise API user passed Net::ThirtySevenSignals::Highrise::new\n";

  $self->{protocol} = $params{ssl} ? 'https' : 'http';

  $self->{forcearray} = $params{forcearray} || 1;

  my $ua = $self->{ua} = LWP::UserAgent->new;

  $ua->env_proxy;
  $ua->default_header('X-POST-DATA-FORMAT' => 'xml');

  $ua->credentials($self->{user} . ".highrisehq.com:443","Application", $self->{token}, 'X');
  $ua->credentials($self->{user} . ".highrisehq.com:80","Application", $self->{token}, 'X');
  if( $self->{debug}){
      $ua->add_handler("request_send",sub{warn(shift->dump);return });
      $ua->add_handler("response_done",sub{warn(shift->dump);return });
  }

  $self->{base_url} = "$self->{protocol}://$self->{user}.highrisehq.com";

  return bless $self, $class;
}

=head2 $pages = $hr->people_list_all([xml => 1]);

Get a list of all of your Highrise people. Returns a Perl data structure
unless the C<xml> parameter is true, in which case it returns the raw
XML as returned by the Highrise server.

=cut

sub people_list_all {
  my $self = shift;
  my %params = @_;

  my $req_data = $data{people_list_all};
  my $url = $self->{base_url} . $req_data->{url};

  my $req = HTTP::Request->new('GET', $url);

  my $structure =  $self->_call(%params, req => $req);
  return $structure if $params{xml};
  return $structure->{$req_data->{return_key}};
}



=head2 $people = $hr->people_list_by_criteria([xml => 1], city => 'Oakland',country=>'US'...);

Returns a collection of people that match the criteria passed
in. Available criteria are:

city
state
country
zip
phone
email

Returns an arrayref or undef
unless the C<xml> parameter is true, in which case it returns the raw
XML as returned by the Highrise server.

=cut

sub people_list_by_criteria{
  my $self = shift;
  my %params = @_;

  my $req_data = $data{people_list_by_criteria};
  my $url = $self->{base_url} . $req_data->{url};

  my $expandedURL = new URI($self->_expand($url, %params));
  my %criteria = ();
  for my $key (qw(city state country zip phone email)){
      $criteria{"criteria[$key]"} = $params{$key} if exists $params{$key};
  }
  $expandedURL->query_form(%criteria);
  my $req = HTTP::Request->new('GET', $expandedURL);

  my $structure =  $self->_call(%params, req => $req);
  return $structure if $params{xml};
  return $structure->{$req_data->{return_key}};
}


=head2 $tags = $hr->tags_list_all([xml => 1]);

Get a list of all of your Highrise tags. Returns a Perl data structure
unless the C<xml> parameter is true, in which case it returns the raw
XML as returned by the Highrise server.

=cut

sub tags_list_all {
  my $self = shift;
  my %params = @_;

  my $req_data = $data{tags_list_all};
  my $url = $self->{base_url} . $req_data->{url};

  my $req = HTTP::Request->new('GET', $url);

  my $structure =  $self->_call(%params, req => $req);
  return $structure if $params{xml};
  return $structure->{$req_data->{return_key}};

}

=head2 $tags = $hr->tags_list_for_subject([xml => 1]);

Get a list of all of your Highrise tags. Returns a Perl data structure
unless the C<xml> parameter is true, in which case it returns the raw
XML as returned by the Highrise server.

=cut

sub tags_list_for_subject {
  my $self = shift;
  my %params = @_;

  my $req_data = $data{tags_list_for_subject};
  if( $req_data->{required_params} ){
      for my $name (@{$req_data->{required_params}}){
	  die "missing required param $name" unless defined $params{$name};
      }

  }
  my $url = $self->{base_url} . $req_data->{url};
  my $expandedURL = $self->_expand($url, %params);

  my $req = HTTP::Request->new('GET', $expandedURL);

  my $structure =  $self->_call(%params, req => $req);
  return $structure if $params{xml};
  return $structure->{$req_data->{return_key}};
}



=head2 $pages = $hr->person_get(id=> 123455,
                                [xml => 1]);

Get a list of all of your Highrise people. Returns a Perl data structure
unless the C<xml> parameter is true, in which case it returns the raw
XML as returned by the Highrise server.

returns a $person hashref or die()s if the person does not exist;

=cut

sub person_get {
  my $self = shift;
  my %params = @_;

  my $req_data = $data{person_get};
  my $url = $self->{base_url} . $req_data->{url};
  my $expandedURL = $self->_expand($url, %params);
  my $req = HTTP::Request->new('GET', $expandedURL);

  return $self->_call(%params, req => $req);
}



=head2 $pages = $hr->person_create(
                                [xml => 1]);

Create a person
unless the C<xml> parameter is true, in which case it returns the raw
XML as returned by the Highrise server.
Pass in parameters with keys:
   firstName
   lastName
   companyName
   emailAddress
   emailAddress

=cut

sub person_create {
  my $self = shift;
  my %params = @_;

  my $req_data = $data{person_create};
  my $url = $self->{base_url} . $req_data->{url};
  my $expandedURL = $self->_expand($url, %params);
  warn "url = $url, expanded = $expandedURL" if $self->{debug};
  my $req = HTTP::Request->new('POST', $expandedURL);
  my %encodedParams = ();
  while (my ($key, $value)  = each %params){
      $value =~ s/&/&amp;/g;
      $value =~ s/</&lt;/g;
      $value =~ s/>/&gt;/g;
      $encodedParams{$key} = $value;
  }
  $req->content($self->_expand($req_data->{req}, %encodedParams));

  return $self->_call(%params, req => $req);
}


=head2 $pages = $hr->tag_add(  $subject, $subjectType, $tagName );

add a tag to an item.  
$subject should be a perl structure returned from one of person_get, company_get etc.
$subjectType should be one of 
   people
   
=cut

sub tag_add {
  my $self = shift;
  my ($subject, $subjectType, $tagName ) = @_;

  my $req_data = $data{tag_add};
  use Data::Dumper;
  warn "tag add.  Subject = ".Dumper($subject);
  my %params = ( subjectType => $subjectType, 
		 tagName => $tagName,
		 subjectID => $subject->{id}[0]{content},
      );
  my $url = $self->{base_url} . $req_data->{url};

  my $expandedURL = $self->_expand($url, %params);
  my $req = HTTP::Request->new('POST', $expandedURL);
  my %encodedParams = ();
  while (my ($key, $value)  = each %params){
      $value =~ s/&/&amp;/g;
      $value =~ s/</&lt;/g;
      $value =~ s/>/&gt;/g;
      $encodedParams{$key} = $value;
  }
  $req->content($self->_expand($req_data->{req}, %encodedParams));

  return $self->_call(%params, req => $req);
}


=head2 $pages = $hr->person_destroy();

Destroy a person.  either returns undef or die()s.

Pass in parameters with keys:
   id => the personid to be destroyed
=cut

sub person_destroy {
  my $self = shift;
  my %params = @_;

  my $req_data = $data{person_destroy};
  my $url = $self->{base_url} . $req_data->{url};
  my $expandedURL = $self->_expand($url, %params);
  my $req = HTTP::Request->new($req_data->{method}, $expandedURL);

  if( $req_data->{req}){
      my %encodedParams = ();
      while (my ($key, $value)  = each %params){
	  $value =~ s/&/&amp;/g;
	  $value =~ s/</&lt;/g;
	  $value =~ s/>/&gt;/g;
	  $encodedParams{$key} = $value;
      }
      $req->content($self->_expand($req_data->{req}, %encodedParams));
  }
  
  $self->_call(%params, req => $req, xml=>1);
  return ;
}

=head2 $page = $hr->create_page(title => $title,
                                [description => $desc, xml => 1]);

Create a new Highrise page with the given title and (optional)
description. Returns a Perl data structure unless the C<xml> parameter is
true, in which case it returns the raw XML as returned by the Highrise server.

=cut

sub _call {
  my $self = shift;
  my %params = @_;

  my $resp = $self->{ua}->request($params{req});
  unless(  $resp->is_success){
      die "Request Failed: ".$resp->status_line."\t".$resp->content; 
  }
  my $xml = $resp->content;
  if( $self->{debug}){
      print "received xml: $xml\n";
  }

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
  my $startTag = qr"\Q[%\E";
  my $endTag = "%]";
  $string =~ s{ $startTag \s* IF \s* P:(\w+) \s*  $endTag
             (.+?)
              $startTag \s*  END \s*  $endTag
          } {
	      my ($condParam, $ifClause ) = ($1,$2);
	      if( $params{$1} ){
		  $2;
	      }
	      else{
		  '';
	      }
          }sexg;

  $string =~ s/\[S:(\w+)]/$self->{$1}/g;
  $string =~ s/\[P:(\w+)]/$params{$1}/g;
  # warn "expanded is $string\n";
  return $string;
}




=head2 $url = $hr->person_url($personHash);

Create an URL pointing at a person page.

=cut

sub person_url{
    my $self = shift;
    my ($person) = @_;
    return sprintf ("http://%s.highrisehq.com/people/%d", $self->{user}, $person->{id}->[0]->{content});
}




=head1 TO DO

=over 4

=item *

Improve documentation (I know, it's shameful)

=item *

More tests

=back

=head1 AUTHOR

Danny Sadinoff E<lt>danny@sadinoff.comE<gt>

derived directly from Dave Cross's Net::Backpack

Please feel free to email me to tell me how you are using the module.

=head1 BUGS

the API is incomplete, to say the least.

Please report bugs by email to danny@sadinoff.com

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2005,2010, Dave Cross, Danny Sadinoff.  All Rights Reserved.

This script is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<http://developer.37signals.com/highrise/>

=cut



1;
__END__




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

=head2 $rc = $hr->show_page(id => $id, [xml => 1]);

Get details of the Highrise page with the given id. Returns a Perl data
structure unless the C<xml> parameter is true, in which case it returns the
raw XML as returned by the Highrise server.

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

=head2 $rc = $hr->destroy_page(id => $id, [xml => 1]);

Delete the Highrise page with the given id. Returns a Perl data structure
unless the C<xml> parameter is true, in which case it returns the raw XML
as returned by the Highrise server.

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

=head2 $rc = $hr->update_title(id => $id, title => $title, [xml => 1]);

Update the title of the given Highrise page. Returns a Perl data structure
unless the C<xml> parameter is true, in which case it returns the raw XML 
as returned by the Highrise server.

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

=head2 $rc = $hr->update_body(id => $id, description => $desc, [xml => 1]);

Update the description of the given Highrise page. Returns a Perl data
structure unless the C<xml> parameter is true, in which case it returns the
raw XML as returned by the Highrise server.

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

=head2 $page = $hr->duplicate_page(id => $id, [xml => 1]);

Create a duplicate of the given Highrise page. Returns a Perl data
structure unless the C<xml> parameter is true, in which case it returns the
raw XML as returned by the Highrise server.

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

=head2 $rc = $hr->link_page(link_page => $id1, to_page => $id2, [xml => 1]);

Link one Highrise page to another. Returns a Perl data structure unless the
C<xml> parameter is true, in which case it returns the raw XML as returned
by the Highrise server.

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

=head2 $rc = $hr->unlink_page(link_page => $id1, from_page => $id2,
                              [xml => 1]);

Unlink one Highrise page from another. Returns a Perl data structure unless
the C<xml> parameter is true, in which case it returns the raw XML as returned
by the Highrise server.

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

=head2 $rc = $hr->share_page(id => $id, people => \@people,
                             [ xml => 1 ]);

Share a given Highrise page with a list of other people. The parameter
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

=head2 $rc = $hr->make_page_public(id => $id, public => $public,
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

=head2 $rc = $hr->unshare_friend_page(id => $id, [ xml => 1 ]);

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


=head2 $rc = $hr->email_page(id => $id, [ xml => 1 ]);

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

=head2 $items = $hr->list_all_items(page_id => $page_id, [xml => 1]);

Get a list of all of your Highrise checklist items. Returns a Perl data structure
unless the C<xml> parameter is true, in which case it returns the raw
XML as returned by the Highrise server.

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

=head2 $item = $hr->create_item(page_id => $page_id, item => $item, [xml => 1]);

Create a Highrise checklist item given a page id and some item content. 
Returns a Perl data structure unless the C<xml> parameter is true, in which case 
it returns the raw XML as returned by the Highrise server.

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

=head2 $item = $hr->update_item(page_id => $page_id, item => $item, [xml => 1]
                                id => $item_id);

Updates a Highrise checklist item given a page id, item id, and new content. 
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Highrise server.

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

=head2 $response = $hr->toggle_item(page_id => $page_id, id => $item_id,
                                    [xml => 1]);

Toggles a Highrise checklist item given a page id and an item id. 
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Highrise server.

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

=head2 $response = $hr->destroy_item(page_id => $page_id, id => $item_id,
                                     [xml => 1]);

Destroys a Highrise checklist item given a page id and an item id. 
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Highrise server.

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

=head2 $response = $hr->move_item(page_id => $page_id, id => $item_id, 
                                  direction => $direction, [xml => 1]);

Modifies the location in the list of a Highrise checklist item. Requires a 
page id, a direction and an item id. Valid values for direction are
"move_lower", "move_higher", "move_to_top", and "move_to_bottom". Returns a
Perl data structure unless the C<xml> parameter is true, in which case it
returns the raw XML as returned by the Highrise server.

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

=head2 $notes = $hr->list_all_notes(page_id => $page_id, [xml => 1]);

Get a list of all of your Highrise notes. Returns a Perl data structure
unless the C<xml> parameter is true, in which case it returns the raw
XML as returned by the Highrise server.

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

=head2 $note = $hr->create_note(page_id => $page_id, title => $title,
                                body => $body, [xml => 1]);

Create a Highrise note given a page id and some content. Title is required,
body is optional. Returns a Perl data structure unless the C<xml> parameter
is true, in which case it returns the raw XML as returned by the Highrise
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

=head2 $note = $hr->update_note(page_id => $page_id, id => $note_id, [xml => 1]
                                title => $title, body => $body);

Updates a Highrise note given a page id, note id, and new content. 
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Highrise server.

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

=head2 $response = $hr->destroy_note(page_id => $page_id, id => $note_id,
                                     [xml => 1]);

Destroys a Highrise note given a page id and an note id. 
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Highrise server.

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

=head2 $pages = $hr->get_tag_pages(page_id => $id, [ xml => 1 ]);

Retrieve all the pages associated with a particular tag id. Returns a Perl
data structure unless the C<xml> parameter is true, in which case it returns
the raw XML as returned by the Highrise server.

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

=head2 $response = $hr->set_page_tags(page_id => $id, tags => \@tags,
                                         [ xml => 1 ]);

Set the tags for a given Highrise page. This method overwrites all tags for
the page. An empty set of tags serves to remove all the tags for the page.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Highrise server.

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

=head2 $reminders = $hr->upcoming_reminders([ xml => 1 ]);

Gets the upcoming Highrise reminders for an account, in the time zone
specified per the account's settings.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Highrise server.

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

=head2 $reminder = $hr->create_reminder(content => $reminder, [xml => 1],
                                        [remind_at => $remind_at]);

Create a Highrise reminder given some reminder content. The content
takes fuzzy date/times like "+30 Do foo and bar" to set the reminder for 30
minutes from now. Optionally, specify a date in a relatively parseable date
format and use the remind_at parameter instead.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Highrise server.

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

=head2 $reminder = $hr->update_reminder(id => $reminder_id,
                                        [content => $reminder], [xml => 1],
                                        [remind_at => $remind_at);

Update a Highrise reminder given a reminder id. The content takes fuzzy
date/times like "+30 Do foo and bar" to set the reminder for 30 minutes
from now. Optionally, specify a date in a relatively parseable date format
and use the remind_at parameter instead.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Highrise server.

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

=head2 $response = $hr->destroy_reminder( id => $reminder_id,  [xml => 1]);

Destroys a Highrise reminder given a reminder id. 
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Highrise server.

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

=head2 $emails = $hr->list_all_emails(page_id => $page_id, [xml => 1]);

Get a list of all of your Highrise email items for a page. Returns a Perl
data structure unless the C<xml> parameter is true, in which case it returns
the raw XML as returned by the Highrise server.

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

=head2 $email = $hr->show_email(page_id => $page_id, id => $reminder_id, 
                                [xml => 1]);

Returns a Highrise email item given a page id and an email id. 
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Highrise server.

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

=head2 $response = $hr->destroy_email(page_id => $page_id, id => $reminder_id, 
                                      [xml => 1]);

Destroys a Highrise email item for a page given a page id and an email id. 
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Highrise server.

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

=head2 $exported_bp = $hr->export([xml => 1]);

Exports an account's entire Highrise. Returns a Perl data structure
unless the C<xml> parameter is true, in which case it returns the raw
XML as returned by the Highrise server.

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

=head2 $lists = $hr->list_all_lists(page_id => $page_id, [xml => 1]);

Get a list of *all* of your Highrise checklists for a specific page.
Returns a Perl data structure unless the C<xml> parameter is true,
in which case it returns the raw XML as returned by the Highrise server.

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

=head2 $list = $hr->list_this_list(page_id => $page_id, list_id => $list_id, [xml => 1]);

Get details of a specific list with the given list_id on a specific Highrise
page with the given page_id. Returns a Perl data structure unless the C<xml>
parameter is true, in which case it returns the raw XML as returned by the
Highrise server.

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

=head2 $list = $hr->create_list(page_id => $page_id, title => $title, [xml => 1]);

Create a new Highrise checklist given a page id and a list title.
Returns a Perl data structure unless the C<xml> parameter is true, in which
case it returns the raw XML as returned by the Highrise server.

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

=head2 $list = $hr->update_list(page_id => $page_id, list_id => $list_id, title => $title, [xml => 1]);

Update the title of a specific list with the given list_id on a specific
Highrise page with the given page_id. Returns a Perl data structure unless
the C<xml> parameter is true, in which case it returns the raw XML as
returned by the Highrise server.

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

=head2 $list = $hr->destroy_list(page_id => $page_id, list_id => $list_id, [xml => 1]);

Destroy a specific list with the given list_id on a specific Highrise page
with the given page_id. Returns a Perl data structure unless the C<xml>
parameter is true, in which case it returns the raw XML as returned by the
Highrise server.

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

=head2 $list = $hr->create_list_item(page_id => $page_id, list_id => $list_id, item = $item, [xml => 1]);

Create an item on a specific list with the given list_id on a specific
Highrise page with the given page_id. This differs from the usual
"create_item" function in that you can specify which list on a page you want
to add the item to. Returns a Perl data structure unless the C<xml> parameter
is true, in which case it returns the raw XML as returned by the Highrise
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



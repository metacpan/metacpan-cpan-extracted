use strict;

=head1 NAME

Net::ITE - OOP-ish interface to the Internet Topic Exchange

=head1 SYNOPSIS

 use Net::ITE;
 my $ite = Net::ITE->new();

 # Get all the posts for a topic

 my $topic = $ite->topic("montreal_quebec_canada");
 my $posts = $topic->posts();

 while (my $item = $posts->next()) {
    print $item->title()."\n";
    print $item->excerpt()."\n";
 }

 # Add your post to a topic listing

 $topic->ping({title=>"foo",
	       url=>"http://foo.com/123",
	       excerpt=>"yadda yadda yadda"});

 # Create a new topic

 $ite->new_topic("foobars");

=head1 DESCRIPTION

OOP-ish interface to the Internet Topic Exchange.

=head1 NOTES

=over 4

=item *

The error handling sucks and will be addressed in future releases.

=back

=cut

package Net::ITE;

$Net::ITE::VERSION = '0.05';

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new($blogname)

Returns an object.Woot!

=cut

sub new {
  my $pkg  = shift;
  my $blog = shift;
  return bless \$blog,$pkg;
}

=head1 OBJECT METHODS

=cut

=head1 Net::ITE

=cut

=head2 $ite->topics()

When called in a scalar context, returns an I<Net::ITE::Iterator> 
object of I<Net::ITE::Topic> objects.

When called in an array context, returns a list of I<Net::ITE::Topic>
objects.

=cut

sub topics {
  my $self = shift;

  my $data = Net::ITE::Network->get(Net::ITE::Constants->TOPICS."rss");

  if (! $data) {
    warn "Unable to topics.\n";
    return undef;
  }

  my $items = Parser->parse_feed($data);

  if (! $items) {
    warn "Unable to parse topics.\n";
    return undef;
  }

  map { $_ = {title=>$_->{title},blog=>$self} } @$items;

  return wantarray ?
    map { Net::ITE::Topic->new($_); } @$items :
      Net::ITE::Iterator->new("Net::ITE::Topic",$items);
}

=head2 $ite->topic($topic)

Returns a I<Net::ITE::Topic> object.

=cut

sub topic {
  my $self = shift;
  return Net::ITE::Topic->new({title=>$_[0],blog=>$self});
}

=head2 $ite->new_topic($topic)

Returns true or false.

=cut

sub new_topic {
  my $self = shift;

  my $post = Net::ITE::Network->post(Net::ITE::Constants->NEWTOPIC,
				     {catname=>$_[0]});

  if (! $post) {
    warn "There was a transport error trying to create new topic.\n";
    return 0;
  }

  if ($$post =~ /<b>An error occurred<\/b>:(?:\s)+(.*)$/) {
    warn $1,"\n";
    return 0;
  }

  return 1;
}

=head1 Net::ITE::Topic

=cut

package Net::ITE::Topic;

my $tb = undef;

sub new {
  my $pkg  = shift;
  return bless $_[0],$pkg;
}

=head2 $topic->title()

=cut

sub title { return shift->{title}; }

=head2 $topic->about()

I<Not implemented (yet)>

=cut

=head2 $topic->url()

=cut

sub url {
  my $self = shift;
  return Net::ITE::Constants->TOPIC.$self->title()."/";
}

=head2 $topic->posts()

When called in a scalar context, returns an I<Net::ITE::Iterator>
object of I<Net::ITE::Post> objects.

When called in an array context, returns a list of I<Net::ITE::Post>
objects.

=cut

sub posts {
  my $self = shift;

  my $data = Net::ITE::Network->get($self->url()."rss");

  if (! $data) {
    warn "Unable to retrieve posts for topic.\n";
    return undef;
  }

  my $posts = Parser->parse_feed($data);

  if (! $posts) {
    warn "Unable to parse posts for topic.\n";
    return undef;
  }

  return wantarray ?
    map { Net::ITE::Post->new($_); } @$posts :
      Net::ITE::Iterator->new("Net::ITE::Post",$posts);
}

=head2 $topic->ping(\%args)

=over 4

=item *

B<blog_name>

If this property is not passed then the value passed to the I<Net::ITE>
constructor will be used.

=item *

B<title>

=item *

B<url>

=item *

B<excerpt>

=back

Returns true or false.

=cut

sub ping {
  my $self = shift;
  my $data = shift;

  $data->{ping_url} = $self->url();
  $data->{blog_name} ||= ${$self->{blog}};

  if (! $tb) {
    require Net::TrackBack;
    $tb = Net::TrackBack->new();
  }

  $tb->send_ping($data);

  if (! $tb->is_success()) {
    warn $tb->message();
    return 0;
  }

  return 1;
}

=head1 Net::ITE::Post

=cut

package Net::ITE::Post;

sub new {
  my $pkg  = shift;
  return bless $_[0],$pkg;
}

=head2 $post->title()

=cut

sub title   { return shift->{title} }

=head2 $post->url()

=cut

sub url     { return shift->{link}; }

=head2 $post->excerpt()

=cut

sub excerpt { return shift->{description}; }

=head1 Net::ITE::Iterator

=cut

package Net::ITE::Iterator;

sub new {
  my $pkg = shift;
  return bless {pkg=>$_[0],data=>$_[1],count=>0}, $pkg;
}

=head2 $it->count()

=cut

sub count {
  my $self = shift;
  return scalar @{$self->{data}};
}

=head2 $it->next()

Returns an object.Woot!

=cut 

sub next {
  my $self = shift;
  if (my $data = $self->{data}->[$self->{count}++]) {
    return $self->{pkg}->new($data);
  }
}

package Net::ITE::Network;
my $ua = undef;

use HTTP::Request;

sub get {
  my $pkg = shift;
  return &send_request(HTTP::Request->new(GET=>$_[0]));
}

sub post {
  my $pkg  = shift;
  my $uri  = shift;
  my $args = shift;

  my @params = ();

  foreach my $param (keys %$args) {
    my $value = $args->{$param};
    $value =~ s!([^a-zA-Z0-9_.-])!uc sprintf "%%%02x", ord($1)!eg;
    push @params,"$param=$value";
  }

  my $req = HTTP::Request->new(POST =>$uri);
  $req->content_type('application/x-www-form-urlencoded');
  $req->content(join('&',@params));

  return &send_request($req);
}

sub ua {
  if (! $ua) {
    require LWP::UserAgent;
    $ua = LWP::UserAgent->new();
  }

  return $ua;
}

sub send_request {
  my $res = &ua()->request($_[0]);

  if (! $res->is_success()) {
    warn "Failed to retrieve data, ".$res->message()."\n";
    return undef;
  }

  return $res->content_ref();
}

package Parser;
use XML::RSS;

my $rss = undef;

sub parse_feed {
  my $pkg    = shift;
  my $sr_rss = shift;

  $rss ||= XML::RSS->new();

  eval { $rss->parse($$sr_rss); };
  if ($@) { 
    warn $@,"\n";
    return undef;
  }

  return $rss->{items};
}

package Net::ITE::Constants;

use constant ITE      => "http://topicexchange.com";
use constant TOPICS   => ITE."/topics/";
use constant TOPIC    => ITE."/t/";
use constant NEWTOPIC => ITE."/new";

return 1;

=head1 VERSION

0.05

=head1 DATE

$Date: 2003/03/20 05:09:14 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

http://topicexchange.com

=head1 LICENSE

Copyright (c) 2003 Aaron Straup Cope, All Rights Reserved.

This is free software, you may use it and distribute it under the same
terms as Perl itself.

=cut


package Posterous;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03';

use LWP::UserAgent;
use HTTP::Request;
use MIME::Base64;
use Rubyish::Attribute;
use Data::Dumper;
use Attribute::Protected;


our $DOMAIN = "http://posterous.com";

our $AUTH_PATH = $DOMAIN."/api/getsites";
our $NEWPOST_PATH = $DOMAIN."/api/newpost";
our $COMMMENT_PATH = $DOMAIN."/api/newcomment";
our $READPOST_PATH = $DOMAIN."/api/readposts";

our $UA = LWP::UserAgent->new();

BEGIN {
  attr_accessor "user", "pass", "site_id";
}

sub new {
  my ($class, $user, $pass, $site_id) = @_;
  die "didn\'t give user\' email or password" unless defined($user) && defined($pass);
  my $self = bless {}, $class;
  __user__ = $user;
  __pass__ = $pass;
  __site_id__ = $site_id if $site_id;
  $self;
}

sub auth_key : Public {
  my ($self) = @_;
  state $auth_key;
  $auth_key //= encode_base64($self->user.":".$self->pass);
  $auth_key;
}

sub account_info : Public {
  my ($self) = @_;
  state $account_info;
  $account_info //= HTTP::Request->new( GET => $AUTH_PATH )
                                 ->basic_auth($self->auth_key)
                                 ->submit_by($UA)
                                 ->xmlized_content;
  $account_info;
}

sub read_posts : Public {
  my ($self, %options) = @_;
  HTTP::Request->new( GET => $READPOST_PATH . "?" . options2query(%options) )
               ->basic_auth($self->auth_key)
               ->submit_by($UA)
               ->xmlized_content;
}

sub read_public_posts : Public {
  my ($self, %options) = @_;
  $options{site_id} = $self->site_id unless exists($options{site_id});
  die "no site_id or hostname is given" unless exists($options{site_id}) or exists($options{hostname});
  HTTP::Request->new( GET => $READPOST_PATH . "?" . options2query(%options) )
               ->submit_by($UA)
               ->xmlized_content;
}

sub primary_site : Public {
  my ($self) = @_;
  state $primary_site;
  while ( my ($key, $value) = each %{ $self->account_info->{site} } ) {
    $primary_site = $value->{id} if $value->{primary} eq "true"
  }
  $primary_site;
}

sub add_post : Public {
  my ($self, %options) = @_;
  my $request = HTTP::Request->new( POST => $NEWPOST_PATH )->basic_auth($self->auth_key);
  $request->content(options2query(%options));
  $UA->request($request)->xmlized_content;
}

sub add_comment :Public {
  my ($self, %options) = @_;
  my $request = HTTP::Request->new( POST => $COMMMENT_PATH )->basic_auth($self->auth_key);
  $request->content(options2query(%options));
  $UA->request($request)->xmlized_content;
}

sub options2query : Protected {
  my (%options) = @_;
  my $query;
  while ( my ($key,$value) = each %options) {
    $query .= "$key=$value&";
  }
  $query //= " ";         # avoid warning $query was not initialized
  $query =~ s/&$//g;
  $query;
}

package HTTP::Request;

# authorization_basic($user, $pass) is another way,
# but basic_auth($auth_key) reutrn request object itself.
sub basic_auth {
  my ($self, $key) = @_;
  $self->header(Authorization => "Basic $key");
  $self;
}

sub submit_by {
  my ($self, $ua) = @_;
  $ua->request($self);
}

package HTTP::Response;
use XML::Simple;

sub xmlized_content {
  my ($self) = @_;
  XMLin($self->content);
}

1;
__END__

=head1 NAME

Posterous - API to posterous.com

=head1 SYNOPSIS

  use Posterous;

  $posterous = Posterous->new($user, $pass, $site_id);

  $posterous->account_info;     # list all sites owned by $user

  $posterous->add_post( title => "hello posterous", body => "Post through Posterous.pm" );

=head1 DESCRIPTION

Posterous.pm just implement interface to posterous.com in Perl

=head1 Class Method



=head2 new($user_mail, $pass, $site_id)

constructor, $user_mail and $pass are required. 

$site_id is optional for specifying which one of your site would be involved in process.



=head1 Instance Method



=head2 auth_key()

always return Base64 encoded "$user_mail:$pass" for Basic HTTP Authentication



=head2 account_info()

GET /api/getsites, return a list of all sites owned by specified user



=head2 read_posts(%options)

GET /api/readposts, return a list of list.

Available %options key include site_id, hostname, num_posts, page, tag.



=head2 read_public_posts(%options)

GET /api/readposts, without Basci HTTP Authentication. 

Since, site_id or hostname should be specified in %options.

Available %options key is the same as read_posts()

return a list of public posts.


=head2 add_post(%options)

POST /api/newpost, return post callback.

Available %options key include site_id, media, title, body, autopost, private, data, tags, source, sourceLink.


=head2 add_comment(%options)

POST /api/newcomment, return comment callback.

Available %options key include post_id, comment.


=head2 primary_site()

return user's primay site id


=head1 SEE ALSO

Official API detail

  http://posterous.com/api

Posterous API Ruby version

  https://rubyforge.org/projects/posterous/

  http://github.com/jordandobson/Posterous/tree/master

=head1 AUTHOR

shelling, E<lt>shelling@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by shelling

Release under MIT (X11) Lincence

=cut

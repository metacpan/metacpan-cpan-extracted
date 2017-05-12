package Net::Posterous;

use warnings;
use strict;
use LWP::UserAgent;
use LWP::Simple;
use MIME::Base64;
use XML::Simple;
use Data::Dumper;

use Net::Posterous::Site;
use Net::Posterous::Post;
use Net::Posterous::Media;
use Net::Posterous::Tag;
use Net::Posterous::Comment;


use HTTP::Request::Common;

our $VERSION = "0.8";
our $DOMAIN  = "http://posterous.com";



=head1 NAME

Net::Posterous - read and post from Posterous blogs

=head1 SYNOPSIS

    my $api   = Net::Posterous->new($user, $pass);
    
    # Get a list of sites the user owns as Net::Posterous::Site objects
    my @sites = $api->get_sites;
    
    # Set the site to use
    $api->site($sites[0]); 

    # Create a post 
    my $post = Net::Posterous::Post->new(%opts);
    my $res  = $api->post($post);
    
    # Update the post
    $post->title("New Title");
    my $res  = $api->post($post);
    
    # Get a list of posts
    my @posts = $api->get_posts;
    
    # Get an individual post using the http://post.ly shortcode
    # i.e 123abc in http://post.ly/123abc
    my $post  = $api->get_post($post->short_code);
    
    
    # Get a list of tags
    my @tags  = $api->get_tags;
    
    # Create a post with an video attached
    my $video = Net::Posterous::Media::Local->new(file => $path_to_movie);
    my $vpost = Net::Posterous::Media::Post->new( title => "My movie", media => $video );
    my $res   = $api->post($vpost);
    
    # Create a post with a flipbook of pictures
    my @images = map {  Net::Posterous::Media::Local->new(file => $_) } qw(1.jpg 2.jpg 3.jpg);
    my $ipost  = Net::Posterous::Media::Post->new( title => "My flipbook", media => \@images );
    my $res    = $api->post($ipost);
    
    # Add a comment
    my $comment = Net::Posterous::Comment->new( body => "Nice flipbook!" );
    my $res     = $api->comment($ipost, $comment);
    
    
    
=head1 DESCRIPTION

This allows reading a writing from Posterous sites.

It's very similar to the C<Posterous> module but:

=over 4

=item It doesn't require Perl 5.10

=item It's slightly more user friendly

=item It's more CPAN namespace friendly

=back

=head1 METHODS

=head2 new <username> <password> [site]

Create a new client object. 

Requires a username and a password.

Optionally you can pass in either a site id or a C<Net::Posterous::Site> object to
specify which site to read/write from. 

If it's not passed in then it can be passed in later or your default site will be used.

=cut
sub new {
   my $class = shift;
   # TODO none authenticated
   my $user  = shift || die "You must pass a username";
   my $pass  = shift || die "You must pass a password";
   my $self  = bless { user => $user, pass => $pass, ua => _get_ua(), auth_key => encode_base64($user.":".$pass) };

   $self->site(@_);

   return $self;
    
}

sub _get_ua {
    return LWP::UserAgent->new( agent => __PACKAGE__."-".$VERSION );
}

=head2 site [site]

Get or set the current site being used.

May return undef.

=cut
sub site {
    my $self = shift;

    if (@_) {
        ($self->{site_id}, $self->{site}) = $self->_load_site(shift);
    } 
    return $self->{site};
}

sub _load_site {
    my $self  = shift;
    my $site  = shift || return;
    
    if (ref($site)) {
        return ($site->id, $site);
    } else {
        return ($site, $self->site_from_id($site));
    }    
}

=head2 site_from_id <id>

Return a C<Net::Posterous::Site> object based on a site id.

Returns undef if the site can't be found.

=cut


sub site_from_id {
    my $self = shift;
    my $id   = shift;
    $self->get_sites; # Force loading of sites
    return $self->{sites}->{$id};
}

=head2 get_sites 

Get a list of all the user's sites.

=cut
sub get_sites {
    my $self  = shift;
    my @sites = $self->_load("GET", "${DOMAIN}/api/getsites", 'site', 'name', 'Net::Posterous::Site');
    $self->{sites}->{$_->id} = $_ for @sites;
    return @sites;
}

=head2 get_posts [opt[s]]

Get the posts from a site. 

Uses, in order - the site passed in using the option key C<site>, the site set by the user, the default site.

The options are 

=over 4

=item site_id 

The id of the site to read from

=item hostname

Subdomain of the site to read from 

=item num_posts

How many posts you want. Default is 10, max is 50.

=item page

What 'page' you want (based on num_posts). Default is 1

=item tag

Only get items with this tag.

=back


=cut
sub get_posts {
    my $self   = shift;
    my %opts   = @_;
    my $site   = $self->_load_site(delete $opts{site} || $self->site); # normalise the site to an object
    my %params = $site ? ( %opts, site_id => $site->id ) : %opts;
    return $self->_load("GET", "${DOMAIN}/api/readposts", 'post', 'id', 'Net::Posterous::Post', %params);
}

=head2 get_post <short code>

Get an id via the http://post.ly short code i.e 123abc in http://post.ly/123abc

=cut

sub get_post {
    my $self = shift;
    my $id   = shift;
    
    $id =~ s!^http://post\.ly/!!; # be liberal in what you accept etc etc
    
    my @posts = $self->_load("GET", "${DOMAIN}/api/getpost", 'post', 'id', 'Net::Posterous::Post', id => $id);
    return shift @posts;
}

=head2 get_tags [opt[s]]

Get a list of tags for a site.

Uses, in order - the site passed in using the option key C<site>, the site set by the user, the default site.

The options are

=over 4

=item site_id

Optional. Id of the site to read from 

=item hostname

Optional. Subdomain of the site to read from

=back

=cut
sub get_tags {
    my $self   = shift;
    my %opts   = @_;
    my $site   = $self->_load_site(delete $opts{site} || $self->site); # normalise the site to an object
    my %params = $site ? ( %opts, site_id => $site->id ) : %opts;
    return $self->_load("GET", "${DOMAIN}/api/gettags", 'tag', 'id', 'Net::Posterous::Tag', %params);
}

=head2 post <post> [opt[s]]

Post or update a C<Net::Posterous::Post> or <Net::Posterous::Media> object.

Uses, in order - the site passed in using the option key C<site>, the site set by the user, the default site.

=cut
sub post {
    my $self = shift;
    my $post = shift;
    my %opts   = @_;
    my $site   = $self->_load_site(delete $opts{site} || $self->site); # normalise the site to an object
   
    my %params = $post->_to_params();
     
    my $url    = $DOMAIN;
    # Update or Create depending on whether the Post already has an id
    if (my $id = delete $params{id}) {
        $url  .= "/api/updatepost";
        $params{post_id} = $id;
    } else {
        $url  .= "/api/newpost"; 
        $params{site_id} = $site->id if $site;
    }
    return $self->_post($post, $url , "post", %params);
}

=head2 comment <post> <comment>

Add a comment to the post.

=cut
sub comment {
    my $self    = shift;
    my $post    = shift;
    my $comment = shift;
      
    my $post_id = ref($post) ? $post->id : $post;
    my %params  = ($comment->_to_params, post_id => $post_id);
    return $self->_post($comment, "${DOMAIN}/api/newcomment" , "comment", %params);
}

sub _post {
    my $self   = shift;
    my $obj    = shift;
    my $url    = shift;
    my $key    = shift;
    my %params = @_;
    
    my $res  = $self->_request("POST", $url, %params) || return undef;
    
    my $data = eval { XMLin($res->content) };
    if ($@) {
        $self->error("Couldn't parse XML response: $@");
        return undef;
    }
    
    # Check to see if we got an error, despite getting a 200 ok
    if (my $error = $self->_xml_nok($data)) {
        $self->error("Couldn't POST $url - $error");
        return undef;
    }
    
    # Merge the new data with object
    # It would be awesome if Posterous returned a full representation of the new object after a POST 
    my $tmp    = $data->{$key} || {};
    foreach my $key (keys %$tmp) {
        $obj->$key($tmp->{$key});
    }
    return $obj;
}



sub _load {
    my $self    = shift;
    my $meth    = shift;
    my $url     = shift;
    my $key     = shift;
    my $id_name = shift;
    my $class   = shift;
    my %params  = @_;
    
    # TODO paging
    
    my $res  = $self->_request($meth, $url, %params) || return ();
    my $data = eval { XMLin($res->content, ForceArray => [$key, 'media'], KeyAttr => $id_name) };
    if ($@) {
        $self->error("Couldn't parse XML response: $@");
        return undef;
    }
    
    # Check to see if we got an error, despite getting a 200 ok
    if (my $error = $self->_xml_nok($data)) {
        $self->error("Couldn't $meth $url - $error");
        return undef;
    }
    
    # Create new objects from the results
    my $items  = $data->{$key} || {};
    my @results;
    foreach my $id (keys %$items) {
        my $obj    = $items->{$id};
        $obj->{$id_name} = $id;
        push @results, $class->new(%$obj);
    }
    return @results;
}

# Check the XML for errors
sub _xml_nok {
    my $self = shift;
    my $data = shift;
    return 0 if "ok" eq $data->{stat};
    return $data->{err}->{code}.": ".$data->{err}->{msg};
}

sub _request {
    my $self = shift;
    my $meth = shift;
    my $url  = shift;
    my %opts = @_;
    my $ua   = $self->{ua};

    $self->{error} = undef;
    
  
    my $req;
    my $req_url = URI->new($url);
    $req_url->query_form(%opts);
    if ('GET' eq $meth || 'PUT' eq $meth) {
        $req  = HTTP::Request->new( $meth => $req_url);
    } else {
        my @content;
        # This little shennanigans is to allow us to post multiple file uploads 
        # by getting round HTTP::Request::Common's helper feature
        foreach my $key (keys %opts) {
            my $value = $opts{$key};
            $value    = [$value] unless ref($value);
            push @content, ($key, $_) for @$value;
        }
        $req  = POST($url, Content_Type => 'form-data', Content => [ @content ]);
    }
    $req->header(Authorization => "Basic ".$self->{auth_key});

    my $res      = $ua->request($req);
    unless ($res->is_success) {
        $self->error("Couldn't $meth $url: ".$res->content);
        return undef;
    }
    return $res;
}

=head2 error

Get or set the last error

=cut
sub error {
    my $self = shift;
    $self->{error} = shift if @_;
    return $self->{error};
}

=head1 ADDING MEDIA

The way to add media is to create a new C<Net::Posterous::Media::Local> file and then add that to the
C<Net::Posterous::Post> object that's going to be created or updated.

It will then be turned into a proper C<Net::Posterous::Media> object when the Post is retrieved.

=head1 BUGS

The Posterous API docs mention being able to post "common document formats" but there's no docs for it.

I'll add it when I come across it.

=head1 DEVELOPERS

The latest code for this module can be found at

    https://svn.unixbeard.net/simon/Net-Posterous

=head1 AUTHOR

Simon Wistow, C<<simon@thegestalt.org >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-posterous at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Posterous>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Posterous

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Posterous>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Posterous>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Posterous>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Posterous/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Simon Wistow, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
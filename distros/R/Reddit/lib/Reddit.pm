package Reddit;
use 5.010001;

use strict;
use warnings;

use JSON;
use HTTP::Cookies;
use LWP::UserAgent;

use Moose;

=head1 NAME

Reddit - Perl extension for http://www.reddit.com

See github for the most up to date/development branch: https://github.com/three18ti/Reddit.pm

=head1 SYNOPSIS

  use Reddit;
  
  # instantatiate a new reddit object
  # Automajically handles logging in and cookie handling
  $r = Reddit->new(
      {
          user_name => 'Foo', 
		  password  => 'Bar', 
		  subreddit => 'Perl'
	  }
  );

  # Submit a link
  # $title, $url, $subreddit
  # This overrides a subreddit set duriing instantiation
  $r->submit_link( 'Test', 'http://example.com', 'NotPerl');

  # Submit a Self Post
  # $title, $text, $subreddit
  # This overrides a subreddit set during instantiation
  $r->submit_story( 'Self.test', 'Some Text Here', 'shareCoding');  

  # Post a top level comment to a URL or .self post 
  $r->comment($post_id, $comment);
  
  # Post a reply to a comment
  $r->comment($comment_id, $comment);

=head1 DESCRIPTION

Perl module for interacting with Reddit.

This module is still largely inprogress.

=head2 Requires

  common::sense
  LWP::UserAgent
  JSON
  HTTP::Cookies

  For Testing:
  Data::Dumper

=head2 EXPORT

None.

=cut

# for testing purposes only
#use lib './';

use Reddit::Type::User;
#use Reddit::Type::Subreddit;

has 'base_url' => (
	is	=> 'ro',
	isa => 'Str',
	default => 'http://www.reddit.com/',
);

has 'api_url' => (
	is	=> 'ro',
	isa => 'Str',
	lazy	=> 1,
	default => sub { $_[0]->base_url . 'api/' },
);

has 'login_api' => (
	is => 'ro',
	isa => 'Str',
	lazy	=> 1,
	default => sub { $_[0]->api_url . 'login' },
); 

has 'submit_api' => (
	is => 'ro',
	isa => 'Str',
	lazy	=> 1,
	default => sub { $_[0]->api_url . 'submit' },	
);

has 'comment_api' => (
	is => 'ro',
	isa => 'Str',
	lazy	=> 1,
	default => sub { $_[0]->api_url . 'comment' },	
);

has 'vote_api' => (
	is => 'ro',
	isa => 'Str',
	lazy	=> 1,
	default => sub { $_[0]->api_url . 'vote' },	
);

has 'api_type'	=> (
	is => 'ro',
	isa => 'Str',
	default => 'json',
);

has 'ua' => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    default => sub { LWP::UserAgent->new },
#    handles => qr/^(?:head|get|post|agent|request.*)/,
	handles => { 
		post				=> 'post',
		get					=> 'get',
		agent_cookie_jar 	=> 'cookie_jar' 
	}
);

has 'cookie_jar' => (
	is => 'rw',
	isa => 'HTTP::Cookies',
	lazy => 1,
	default => sub { HTTP::Cookies->new },	
);

has [ 'user_name', 'password', ] => (
	is => 'rw',
	isa => 'Str',
	required => 1,	
	trigger => \&_login,
);

has 'subreddit' => (
	is => 'rw',
	isa => 'Str',
);

has 'modhash' => (
	is => 'rw',
	isa => 'Str',
);

has '_user_search_name' => (
	is => 'rw',
	isa => 'Str',
	lazy => 1,
	default => '',
);

has 'about_user_api' => (
	is => 'rw',
	isa => 'Str',
	lazy => 1,
	default => sub { $_[0]->base_url . 'user/' . $_[0]->_user_search_name . '/about.json' },
);

has 'user_info' => (
	is => 'rw',
	isa => 'Reddit::Type::User',
	lazy => 1,
	default => sub { Reddit::Type::User->new },
);

sub _login {
	my $self = shift;
	
	my $response = $self->ua->post($self->login_api,
        {
            api_type    => $self->api_type,
            user        => $self->user_name,
            passwd      => $self->password,
        }
    );

    $self->_set_cookie($response);
}

sub _set_cookie {
    my $self        = shift;
    my $response    = shift;

    $self->cookie_jar->extract_cookies ($response);
    $self->agent_cookie_jar ($self->cookie_jar);
    $self->_parse_modhash ($response);
}

sub _parse_modhash {
    my $self        = shift;
    my $response    = shift;

    my $decoded = from_json ($response->content);
    $self->modhash ($decoded->{json}{data}{modhash});
}

sub _parse_link {
    my $self = shift;
    my $link = shift;

    my ($id) = $link =~ /comments\/(\w+)\//i;
    return 't3_' . $id;
}

sub _parse_comment_id {
    # ID's require a t3_ or t1_ prefix depending on whether it is a
    # post or comment id respectively.
	my $id = shift;
	if (length($id) == 5){ $id = "t3_" . $id}
	elsif (length($id) == 7){ $id = "t1_" . $id}
	else { die "Invalid ID length"}
	return $id;
}

=head1 Provided Methods

=over 2

=item B<submit_link($title, $url, $subreddit)>

    $r->submit_link( 'Test', 'http://example.com', 'NotPerl');

This method posts links to the specified subreddit.  The subreddit parameter is optional if it is not set at the time of instantiation
$subreddit is required in one place or the other, subreddit specified here will take precedence over the subreddit specified at time of instantiation.

=back

=cut

# Submit link to reddit
sub submit_link {
    my $self = shift;
    my ($title, $url, $subreddit) = @_;

    my $kind        = 'link';

    my $newpost     = $self->ua->post($self->submit_api,
        {
            uh      => $self->modhash,
            kind    => $kind,
            sr      => $subreddit || $self->subreddit,
            title   => $title,
            r       => $subreddit || $self->subreddit,
            url     => $url,
        }
    );

    my $json_content    = $newpost->content;
    my $decoded         = from_json $json_content;

    #returns link to new post if successful
    my $link = $decoded->{jquery}[18][3][0];
    my $id = $self->parse_link($link);

    return $id, $link;
}

=over 2

=item B<submit_story($title, $text, $subreddit)>

    $r->submit_story( 'Self.test', 'Some Text Here', 'shareCoding');

This method makes a Self.post to the specified subreddit.  The subreddit parameter is optional if it is not set at the time of instantiation
$subreddit is required in one place or the other, subreddit specified here will take precedence over the subreddit specified at time of instantiation.

=back

=cut

sub submit_story {
    my $self = shift;
    my ($title, $text, $subreddit) = @_;
 
    my $kind        = 'self';
    my $newpost     = $self->post($self->submit_api,
        {
            uh       => $self->modhash,
            kind     => $kind,
            sr       => $subreddit || $self->subreddit,
            r        => $subreddit || $self->subreddit,
            title    => $title,
            text     => $text,
        },
    );

    my $json_content    = $newpost->content;
    my $decoded         = from_json $json_content;

    #returns id and link to new post if successful
    my $link = $decoded->{jquery}[12][3][0];
    my $id = $self->_parse_link($link);

    return $id, $link;
}

=over 2

=item B<comment($post_id, $comment)>
   
To post a top level comment to a URL or .self post 

    $r->comment($post_id, $comment);

To post a reply to a comment
    
    $r->comment($comment_id, $comment);

This methid requires you pass in the cannonical thing ID with the correct thing prefix.
Submit methods return cannonical thing IDs, L<See the FULLNAME Glossary|https://github.com/reddit/reddit/wiki/API> for futher information

The post_id is the alphanumeric string after the name of the subreddit, before the title of the post
The comment_id is the alphanumeric string after the title of the post

=back

=cut

sub comment {
    my $self = shift;
    my ($thing_id, $comment) = @_;
    $thing_id = $self->_parse_comment_id($thing_id);
    my $response = $self->post($self->comment_api,
        {
            thing_id    => $thing_id,
            text        => $comment,
            uh          => $self->modhash,
        },
    );

    my $decoded = from_json $response->content;
    return $decoded->{jquery}[18][3][0][0]->{data}{id};
}

sub get_user_info {
	my $self = shift;
	my $search_name = shift;

	$self->_user_search_name($search_name);

	my $response = $self->get ($self->about_user_api);
	my $decoded = from_json $response->content;
	my $data = $decoded->{data};

	while (my ($key, $value) = each %{$data}) {
   		if (JSON::is_bool ref $value){
	    	$value = $value ? '1' : '0' ;
		}
		$self->user_info->$key($value);	
	}
	return $self->user_info;
}

sub vote {
	my $self = shift; 
	my ($thing_id, $direction) = @_;
	
	given ($direction) {
		when ( /up/i || 1) {
			$direction = 1;
		}
		when ( /down/i || -1) {
			$direction = -1;
		}
		when ( /rescind/i || 0 ) {
			$direction = 0;
		}
		default {
			warn "Please enter a valid direction";
			return 0;
		}
	}

	my $response = $self->post ( $self->vote_api, 
		{
			id	=> $thing_id,
			dir => $direction,
			uh	=> $self->modhash
		}
	);
	
	return $response->content;
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 SEE ALSO

L<https://github.com/reddit/reddit/wiki>

=head1 AUTHOR

Jon A, E<lt>info[replacewithat]cyberspacelogistics[replacewithdot]comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by jon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

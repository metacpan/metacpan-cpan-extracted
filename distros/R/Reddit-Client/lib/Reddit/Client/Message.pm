package Reddit::Client::Message;

use strict;
use warnings;
use Carp;

require Reddit::Client::Thing;

use base   qw/Reddit::Client::Thing/;
use fields qw/
	author
	body
	body_html
	context
	created
	created_utc
	dest
	distinguished
	first_message
	first_message_name
	likes				
	link_title
	new
	parent_id
	permalink
	replies
	subject
	subreddit
	was_comment
	/;


use constant type => "t4";

sub get_web_url {
	my $this = shift;
	return $this->{session}->get_origin()."/message/messages/".$this->{id};
}

1; 
__END__

=pod

=head1 NAME

Reddit::Client::Message

=head1 DESCRIPTION

A thing that can appear in a user's inbox (comment or message, t1 or t4).

=cut


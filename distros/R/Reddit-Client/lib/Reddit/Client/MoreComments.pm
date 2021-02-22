package Reddit::Client::MoreComments;

use strict;
use warnings;
use Carp;

require Reddit::Client::Thing;

use base   qw/Reddit::Client::Thing/;
use fields qw/ 
	children count depth parent_id link_id
/;

use constant type => "more";

sub get_collapsed_comments {
	my ($this, %param) = @_;
	my $linkid = $this->{link_id} || $param{link_id} || undef;
	print "MoreComments::get_collapsed_comments: link_id is required. Normally this should populate on its own. It being undefined could be the sign of an issue elsewhere. You can set it manually by passing in a link_id." unless $linkid;
	return unless $linkid;

	my %data = (
		link_id	=> $linkid,
		children=> $this->{children},
	);
	$data{sort}	= $param{sort} if $param{sort};
	$data{id}	= $param{id} if $param{id};

	return $this->{session}->get_collapsed_comments( %data );
}

1;

__END__

=pod

  get_collapsed_commnts in Client.pm

C<link_id> is the ID of the link the comments are under. 

C<children> is a reference to an array containing the comment IDs. 

If C<limit_children> is true, return only the requested comments, not replies to them. Otherwise return as many replies as possible (possibly resulting in more MoreComments objects down the line).

C<sort> is one of 'confidence', 'top', 'new', 'controversial', 'old', 'random', 'qa', 'live'. Default seems to be 'confidence'.

=cut

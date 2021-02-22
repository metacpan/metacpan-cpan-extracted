package Reddit::Client::Link;

use strict;
use warnings;
use Carp;

require Reddit::Client::VotableThing;
# is_original_content in base class
use base   qw/Reddit::Client::VotableThing/;
use fields qw/
approved_at_utc
approved_by
archived
author
author_flair_background_color
author_flair_css_class
author_flair_richtext
author_flair_template_id
author_flair_text
author_flair_text_color
author_flair_type
author_fullname
author_patreon_flair
author_premium
awarders
banned_at_utc
banned_by
brand_safe
can_gild
can_mod_post
category
clicked
content_categories
contest_mode
created
created_utc
crosspost_parent
discussion_type
distinguished
domain
gilded
gildings
hidden
hide_score
is_crosspostable
is_meta
is_reddit_media_domain
is_robot_indexable
is_self
is_video
link_flair_background_color
link_flair_css_class
link_flair_richtext
link_flair_template_id
link_flair_text
link_flair_text_color
link_flair_type
locked
media
media_embed
mod_reports
morecomments
num_comments
num_reports
over_18
permalink
pwls
quarantine
removal_reason
removed
removed_by
removed_by_category
report_reasons
saved
secure_media
selftext
selftext_html
send_replies
spam
spoiler
sr_detail
steward_reports
stickied
subreddit
subreddit_id
subreddit_name_prefixed
subreddit_subscribers
subreddit_type
suggested_sort
thumbnail
thumbnail_height
thumbnail_width
title
total_awards_received
url
user_reports
view_count
visited
whitelist_status
wls
/;

use constant type => "t3";

sub reply {
    my ($self, $text) = @_;
	$text || croak "need comment text";	
	my $cmtid = $self->{session}->submit_comment(parent_id=>$self->{name}, text=>$text);
	return "t1_".$cmtid if $cmtid;
	return $cmtid;
}
sub remove {
	my $self = shift;
	return $self->{session}->remove($self->{name});
}
sub spam {
	my $self = shift;
	return $self->{session}->spam($self->{name});
}
sub edit {
    my ($self, $text) = @_;
	croak 'This is not a self post' unless $self->{is_self};
	my $post = $self->{session}->edit($self->{name}, $text);
	$self->{selftext} = $text if $post;
	return $post;
}
sub delete {
  	my $self = shift;
	my $cmtid = $self->{session}->delete($self->{name});
	return $cmtid;
}

sub hide {
    my $self = shift;
    $self->{session}->hide($self->{name});
}

sub unhide {
    my $self = shift;
    $self->{session}->unhide($self->{name});
}

sub get_permalink { # deprecated
	my $self = shift;
	return $self->{session}->get_origin().$self->{permalink};
}
sub get_web_url {
	my $self = shift;
	return $self->{session}->get_origin().$self->{permalink};
}

sub comments { # deprecated. Only existed briefly.
    my $self = shift;
    return $self->get_comments();
}
sub get_comments {
	my $self = shift;
	return $self->{session}->get_comments(permalink=>$self->{permalink});
}

1;

__END__

=pod

=head1 NAME

Reddit::Client::Link

=head1 DESCRIPTION

Wraps a posted link or "self-post".

=head1 SUBROUTINES/METHODS

=over

=item comments()

Wraps C<Reddit::Client::get_comments>, implicitly providing the permalink parameter.

=back

=head1 AUTHOR

<mailto:earthtone.rc@gmail.com>

=head1 LICENSE

BSD license

=cut

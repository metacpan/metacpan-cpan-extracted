package Reddit::Client::Link;

use strict;
use warnings;
use Carp;

require Reddit::Client::VotableThing;

use base   qw/Reddit::Client::VotableThing/;
use fields qw/link_flair_text media url link_flair_css_class num_reports
              created_utc banned_by subreddit title author_flair_text is_self
              author media_embed author_flair_css_class selftext domain
              num_comments clicked saved thumbnail subreddit_id approved_by
              selftext_html created hidden over_18 permalink
		user_reports mod_reports/;

use constant type => "t3";

sub reply {
    my ($self, $text) = @_;
	$text || croak "need comment text";	
	my $cmtid = $self->{session}->submit_comment(parent_id=>$self->{name}, text=>$text);
	return "t1_".$cmtid if $cmtid;
	return $cmtid;
}
sub comments {
    my $self = shift;
    return $self->{session}->get_comments(permalink => $self->{permalink});
}

sub hide {
    my $self = shift;
    $self->{session}->hide($self->{name});
}

sub unhide {
    my $self = shift;
    $self->{session}->unhide($self->{name});
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

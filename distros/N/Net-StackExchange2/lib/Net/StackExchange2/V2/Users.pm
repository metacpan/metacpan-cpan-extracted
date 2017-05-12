package Net::StackExchange2::V2::Users;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Sub::Name qw(subname);
use Net::StackExchange2::V2::Common qw(query no_params one_param two_params);

our $VERSION = "0.05";

sub new {
	my ($class, $params) = @_;
    my $self = $params;
    bless $self, $class;

	*users_all = subname(
	   "Net::StackExchange2::V2::Users::users_all",
	   no_params("users"),
	);
	*users = subname(
	   "Net::StackExchange2::V2::Users::users",
	   one_param("users"),
	);
	*users_badges = subname(
	   "Net::StackExchange2::V2::Users::users_badges",
	   one_param("users", "badges"),
	);
	*users_comments = subname(
	   "Net::StackExchange2::V2::Users::users_comments",
	   one_param("users", "comments"),
	);
	*users_comments_toid = subname(
	   "Net::StackExchange2::V2::Users::users_comments_toid",
	   two_params("users", "comments"),
	);
	*users_favorites = subname(
	   "Net::StackExchange2::V2::Users::users_favorites",
	   one_param("users", "favorites"),
	);
	*users_mentioned = subname(
	   "Net::StackExchange2::V2::Users::users_mentioned",
	   one_param("users", "mentioned"),
	);
	*users_merges = subname(
	   "Net::StackExchange2::V2::Users::users_merges",
	   one_param("users", "merges", { no_site => 1}),
	);
	*users_notifications = subname(
	   "Net::StackExchange2::V2::Users::users_notifications",
	   one_param("users", "notifications"),
	);
	*users_notifications_unread = subname(
	   "Net::StackExchange2::V2::Users::users_notifications_unread",
	   one_param("users", "notifications/unread"),
	);
	*users_privileges = subname(
	   "Net::StackExchange2::V2::Users::users_privileges",
	   one_param("users", "privileges"),
	);
	*users_questions = subname(
	   "Net::StackExchange2::V2::Users::users_questions",
	   one_param("users", "questions"),
	);
	*users_questions_featured = subname(
	   "Net::StackExchange2::V2::Users::users_questions_featured",
	   one_param("users", "questions/featured"),
	);
	*users_questions_no_answers = subname(
	   "Net::StackExchange2::V2::Users::users_questions_no_answers",
	   one_param("users", "questions/no-answers"),
	);
	*users_questions_unaccepted = subname(
	   "Net::StackExchange2::V2::Users::users_questions_unaccepted",
	   one_param("users", "questions/unaccepted"),
	);
	*users_questions_unanswered = subname(
	   "Net::StackExchange2::V2::Users::users_questions_unanswered",
	   one_param("users", "questions/unanswered"),
	);
	*users_reputation = subname(
	   "Net::StackExchange2::V2::Users::users_reputation",
	   one_param("users", "reputation"),
	);
	*users_reputation_history = subname(
	   "Net::StackExchange2::V2::Users::users_reputation_history",
	   one_param("users", "reputation-history"),
	);
	*users_reputation_history_full = subname(
	   "Net::StackExchange2::V2::Users::users_reputation_history_full",
	   one_param("users", "reputation-history/full"),
	);
	*users_suggested_edits = subname(
	   "Net::StackExchange2::V2::Users::users_suggested_edits",
	   one_param("users", "suggested-edits"),
	);
	*users_tags = subname(
	   "Net::StackExchange2::V2::Users::users_tags",
	   one_param("users", "tags"),
	);

	*users_tags_top_answers = subname(
	   "Net::StackExchange2::V2::Users::users_tags_top_answers",
		#refined quite nicely. two params in this case takes three parts 
		#to the url
	   two_params("users", "tags", "top-answers"),
	);
	*users_tags_top_questions = subname(
	   "Net::StackExchange2::V2::Users::users_tags_top_answers",
	   two_params("users", "tags","top-questions"),
	);
	#-------------------
	*users_timeline = subname(
	   "Net::StackExchange2::V2::Users::users_timeline",
	   one_param("users", "timeline"),
	);
	*users_top_answers_tags = subname(
	   "Net::StackExchange2::V2::Users::users_top_answers_tags",
	   one_param("users", "top-answer-tags"),
	);
	*users_top_question_tags = subname(
	   "Net::StackExchange2::V2::Users::users_top_question_tags",
	   one_param("users", "top-question-tags"),
	);
	*users_write_permissions = subname(
	   "Net::StackExchange2::V2::Users::users_write_permissions",
	   one_param("users", "write-permissions"),
	);
	*users_moderators = subname(
	   "Net::StackExchange2::V2::Users::users_write_permissions",
	   no_params("users/moderators"),
	);    
	*users_moderators_elected = subname(
	   "Net::StackExchange2::V2::Users::users_moderators_elected",
	   no_params("users/moderators/elected"),
	);    
	*users_associated = subname(
	   "Net::StackExchange2::V2::Users::users_associated",
	   one_param("users","associated", {no_site => 1}),
	);
	*users_inbox = subname(
	   "Net::StackExchange2::V2::Users::users_inbox",
	   one_param("users", "inbox"),
	);
	*users_inbox_unread = subname(
	   "Net::StackExchange2::V2::Users::users_inbox_unread",
	   one_param("users", "inbox/unread"),
	);
	return $self;
}
1;#end of Net::StackExchange2::V2::Users
__END__


=head1 NAME

Net::StackExchange2::V2::Users - Users

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS


=head1 Description

Access Tokens

=head2 Methods

=head3 method1


=head1 AUTHOR

Gideon Israel Dsouza, C<< <gideon at cpan.org> >>

=head1 BUGS

See L<Net::StackExchange2>.

=head1 SUPPORT

See L<Net::StackExchange2>.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Gideon Israel Dsouza.

This library is distributed under the freebsd license:

L<http://opensource.org/licenses/BSD-3-Clause> 
See FreeBsd in TLDR : L<http://www.tldrlegal.com/license/bsd-3-clause-license-(revised)>

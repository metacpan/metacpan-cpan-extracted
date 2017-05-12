package Net::StackExchange2::V2::Questions;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Sub::Name qw(subname);
use Net::StackExchange2::V2::Common qw(query no_params one_param);

our $VERSION = "0.05";

sub new {
	my ($class, $params) = @_;
    my $self = $params;
    bless $self, $class;

	*questions_all = subname(
	   "Net::StackExchange2::V2::Questions::questions_all",
	   no_params("questions"),
	);
	*questions = subname(
	   "Net::StackExchange2::V2::Questions::questions",
	   one_param("questions"),
	);
	*questions_answers = subname(
	   "Net::StackExchange2::V2::Questions::questions_answers",
	   one_param("questions", "answers"),
	);
	*questions_comments = subname(
	   "Net::StackExchange2::V2::Questions::questions_comments",
	   one_param("questions", "comments"),
	);
	*questions_linked = subname(
	   "Net::StackExchange2::V2::Questions::questions_linked",
	   one_param("questions", "linked"),
	);
	*questions_related = subname(
	   "Net::StackExchange2::V2::Questions::questions_related",
	   one_param("questions", "related"),
	);
	*questions_timeline = subname(
	   "Net::StackExchange2::V2::Questions::questions_timeline",
	   one_param("questions", "timeline"),
	);
	*questions_featured = subname(
	   "Net::StackExchange2::V2::Questions::questions_featured",
	   no_params("questions/featured"),
	);
	*questions_unanswered = subname(
	   "Net::StackExchange2::V2::Questions::questions_unanswered",
	   no_params("questions/unanswered"),
	);
	*questions_no_answers = subname(
	   "Net::StackExchange2::V2::Questions::questions_no_answers",
	   no_params("questions/no-answers"),
	);
    return $self;
}
1; #END of Net::StackExchange2::V2::Questions
__END__



=head1 NAME

Net::StackExchange2::V2::Questions - Questions

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

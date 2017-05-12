package Net::StackExchange2::V2::Posts;

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

	*posts_all = subname(
	   "Net::StackExchange2::V2::Posts::posts_all",
	   no_params("posts"),
	);
	*posts = subname(
	   "Net::StackExchange2::V2::Posts::posts",
	   one_param("posts"),
	);
	*posts_comments = subname(
	   "Net::StackExchange2::V2::Posts::posts_comments",
	   one_param("posts", "comments"),
	);
	*posts_comments_add = subname(
	   "Net::StackExchange2::V2::Posts::posts_comments_add",
	   one_param("posts", "comments/add", {post => 1}),
	);
	
	*posts_revisions = subname(
	   "Net::StackExchange2::V2::Posts::posts_revisions",
	   one_param("posts", "revisions"),
	);
	*posts_suggested_edits = subname(
	   "Net::StackExchange2::V2::Posts::posts_suggested_edits",
	   one_param("posts", "suggested-edits"),
	);
    return $self;
}
1; #END of Net::StackExchange2::V2::Posts
__END__

=head1 NAME

Net::StackExchange2::V2::Posts - Posts

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

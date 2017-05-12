package Net::StackExchange2::V2::Tags;

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

	*tags_all = subname(
	   "Net::StackExchange2::V2::Tags::tags_all",
	   no_params("tags"),
	);
	*tags_info = subname(
	   "Net::StackExchange2::V2::Tags::tags_info",
	   one_param("tags", "info"),
	);
	*tags_moderator_only = subname(
	   "Net::StackExchange2::V2::Tags::tags_moderator_only",
	   no_params("tags/moderator-only"),
	);
	*tags_required = subname(
	   "Net::StackExchange2::V2::Tags::tags_required",
	   no_params("tags/required"),
	);
	*tags_synonyms_all = subname(
	   "Net::StackExchange2::V2::Tags::tags_synonyms_all",
	   no_params("tags/synonyms"),
	);
	*tags_faq = subname(
	   "Net::StackExchange2::V2::Tags::tags_faq",
	   one_param("tags", "faq"),
	);
	*tags_related = subname(
	   "Net::StackExchange2::V2::Tags::tags_related",
	   one_param("tags", "related"),
	);
	*tags_synonyms = subname(
	   "Net::StackExchange2::V2::Tags::tags_synonyms",
	   one_param("tags", "synonyms"),
	);
	*tags_top_answerers = subname(
	   "Net::StackExchange2::V2::Tags::tags_top_answerers",
	   two_params("tags", "top-answerers"),
	);
	*tags_top_askers = subname(
	   "Net::StackExchange2::V2::Tags::tags_top_askers",
	   two_params("tags", "top-askers"),
	);
	*tags_wikis = subname(
	   "Net::StackExchange2::V2::Tags::tags_wikis",
	   one_param("tags", "wikis"),
	);	
    return $self;
}
1; # End of Net::StackExchange2::V2::Tags
__END__


=head1 NAME

Net::StackExchange2::V2::Tags - Tags

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

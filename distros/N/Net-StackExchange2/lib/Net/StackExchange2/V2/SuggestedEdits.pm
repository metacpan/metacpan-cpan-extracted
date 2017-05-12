package Net::StackExchange2::V2::SuggestedEdits;

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

	*suggested_edits_all = subname(
	   "Net::StackExchange2::V2::SuggestedEdits::suggested_edits_all",
	   no_params("suggested-edits"),
	);
	*suggested_edits = subname(
	   "Net::StackExchange2::V2::SuggestedEdits::suggested_edits_all",
	   one_param("suggested-edits"),
	);
    return $self;
}
1; # End of Net::StackExchange2::V2::SuggestedEdits
__END__


=head1 NAME

Net::StackExchange2::V2::SuggestedEdits - Suggested-Edits

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

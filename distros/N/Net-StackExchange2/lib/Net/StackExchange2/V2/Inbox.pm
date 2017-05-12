package Net::StackExchange2::V2::Inbox;

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

	*inbox = subname(
	   "Net::StackExchange2::V2::Inbox::inbox",
	   no_params("inbox", {no_site => 1}),
	);
	*inbox_unread = subname(
	   "Net::StackExchange2::V2::Inbox::inbox_unread",
	   no_params("inbox/unread",{no_site => 1}),
	);
		
    return $self;
}
1; #END of Net::StackExchange2::V2::Inbox
__END__


=head1 NAME

Net::StackExchange2::V2::Inbox - Inbox

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

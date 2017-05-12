package Net::Async::SPORE;
# ABSTRACT: IO::Async support for SPORE REST definitions
use strict;
use warnings;

our $VERSION = '0.003';

=head1 NAME

Net::Async::SPORE - IO::Async support for the portable REST specification

=head1 VERSION

Version 0.003

=head1 DESCRIPTION

B< WARNING >: This is a very early alpha release with only rudimentary client support
included, and no middleware.

Very basic SPORE client implementation for L<IO::Async>. See L<Net::Async::SPORE::Loader>
for information.

=head2 spore

This distribution will also install the C< spore > utility for running methods
against a SPORE definition from the commandline:

 spore -s github.json list_repos username=tm604

=cut

1;

__END__

=head1 SEE ALSO

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2012-2014. Licensed under the same terms as Perl itself.

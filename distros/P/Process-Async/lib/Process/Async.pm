package Process::Async;
# ABSTRACT: wrapper for using an IO::Async loop inside an IO::Async subprocess
use strict;
use warnings;

our $VERSION = '0.003';

=head1 NAME

Process::Async - nested loop-using process support

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use Process::Async;
 use IO::Async::Loop;
 
 my $loop = IO::Async::Loop->new;
 $loop->add(
 	my $pm = Process::Async::Manager->new(
 		worker => 'Demo::Worker',
 		child  => 'Demo::Child',
 	)
 );
 my $child = $pm->spawn;
 $child->finished->get;

=head1 DESCRIPTION

Provides a thin wrapper around L<IO::Async::Process>. See the examples
directory.

=head1 METHODS

=cut

use Process::Async::Manager;
use Process::Async::Child;
use Process::Async::Worker;

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<IO::Async::Process>

=item * L<IO::Async::Routine>

=item * L<IO::Async::Channel>

=back

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2014-2015. Licensed under the same terms as Perl itself.

package Pipeline::Segment::Async::Handler;

use strict;
use warnings;
use Pipeline::Base;
use base qw( Pipeline::Base );

our $VERSION = "3.12";

sub canop { abstract() }
sub run { abstract() }
sub reattach { abstract() }
sub discard { abstract() }

sub abstract { die "abstract method called" }

1;

__END__

=head1 NAME

Pipeline::Segment::Async::Handler - interface for asynchronous segment models

=head1 SYNOPSIS

  use Pipeline::Segment::Async::Handler;
  use base qw( Pipeline::Segment::Async::Handler );

=head1 DESCRIPTION

The C<Pipeline::Segment::Async::Handler> module is provided only as an under which
an asynchronous segment model is going to work.

=head1 METHODS

=over 4

=item canop()

C<canop()> returns true if the asynchronous model will work under the current system
configuration.

=item run()

C<run()> starts the asynchronous mode segment.

=item reattach()

C<reattach()> provides a means to reconnect an asynchronous segment to obtain its
results.

=item discard()

C<discard()> throws away an asynchronous segment, indicating that its results will
never be used.

=back

=head1 SEE ALSO

Pipeline::Segment::Async::Fork, Pipeline::Segment::Async::IThreads

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

This module is released under the same terms as Perl itself.

=cut

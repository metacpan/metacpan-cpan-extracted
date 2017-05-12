package SmokeRunner::Multi::Reporter::Screen;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: Prints runner output to STDOUT
$SmokeRunner::Multi::Reporter::Screen::VERSION = '0.21';
use strict;
use warnings;

use base 'SmokeRunner::Multi::Reporter';

sub report
{
    my $self = shift;

    print "\n";
    print 'Output from running tests for ', $self->runner()->set()->name(), "\n";

    print $self->runner()->output();

    print "\n";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SmokeRunner::Multi::Reporter::Screen - Prints runner output to STDOUT

=head1 VERSION

version 0.21

=head1 SYNOPSIS

  my $reporter =
      SmokeRunner::Multi::Reporter::Screen->new( runner => $runner );

  $reporter->report();

=head1 DESCRIPTION

This class implements test reporting by simply printing the output
from the runner to STDOUT. It can be handy if you're trying to debug
the SmokeRunner code, or your tests fails mysteriously under the smoke
runner but not when run by hand.

=head1 METHODS

This class provides the following methods:

=head2 SmokeRunner::Multi::Reporter::Smolder->new(...)

This method creates a new reporter object. It requires one parameter:

=over 4

=item * runner

A C<SmokeRunner::Multi::Runner> object. You should already have called
C<< $runner->run_tests() >> on this object.

=back

=head2 $reporter->report()

This simply prints the return value of C<< $runner->output() >>.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-smokerunner-multi@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 LiveText, Inc., All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by LiveText, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

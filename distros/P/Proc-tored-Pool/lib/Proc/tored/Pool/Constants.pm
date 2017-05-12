package Proc::tored::Pool::Constants;
# ABSTRACT: Constants used by Proc::tored::Pool
$Proc::tored::Pool::Constants::VERSION = '0.07';
use strict;
use warnings;
use parent 'Exporter';

use constant assignment => 'assignment';
use constant success => 'success';
use constant failure => 'failure';

BEGIN {
  our %EXPORT_TAGS = (events => [qw(assignment success failure)]);
  our @EXPORT_OK = map { @$_ } values %EXPORT_TAGS;
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Proc::tored::Pool::Constants - Constants used by Proc::tored::Pool

=head1 VERSION

version 0.07

=head1 EVENT CONSTANTS

=head2 assignment

Triggered immediately after a task has been assigned to a worker process.

=head2 success

Triggered once the manager collects the result of the successful execution of a
task.

=head2 failure

Triggered once the manager collects the result of a task which died or that had
a non-zero exit status.

=head1 AUTHOR

Jeff Ober <jeffober@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package StackTrace::HiPerf;

use 5.008;
use strict;
use warnings;
use XSLoader;

=head1 NAME

StackTrace::HiPerf - High performance stacktraces

=head1 VERSION

0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

 use StackTrace::HiPerf;
 my $trace = StackTrace::HiPerf::trace();

=head1 DESCRIPTION

This module's purpose is to provide the most efficient way to generate a
stacktrace.  The traces it generates are delimited strings.  Each entry
contains the line number and the file name of the sub or eval invocation.

An example trace could look like this "79|Foo.pm||34|Bar.pm||56|Baz.pm||".

As its implemented now this module isn't very flexible or general purpose.
If generalizing it proves useful then that may happen in the future.

=head1 FUNCTIONS

=over

=item trace

Returns the current stack trace in string form.  Takes an optional
integer argument indicating at which stack level to start the trace.

=back

=cut

XSLoader::load( 'StackTrace::HiPerf', $VERSION );

=head1 AUTHOR

Justin DeVuyst, C<justin@devuyst.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Justin DeVuyst.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

package Proc::Simple::Async;

use Proc::Simple;

require Exporter;

use strict;
use warnings;

our @ISA = qw/Exporter/;

our $VERSION = 0.03;

our $AUTHORITY = 'cpan:BERLE';

our @EXPORT = qw/async/;

sub async (&;@) {
  my $proc = Proc::Simple->new;

  $proc->start (@_);

  return $proc;
}

1;

__END__

=pod

=head1 NAME

Proc::Simple::Async - Keyword sugar for Proc::Simple

=head1 SYNOPSIS

  async { some_task() };

  my $proc = async { some_other_task(@_) } 1,2,3,4;

=head1 DESCRIPTION

This module lets you fork off code that does not require synchronous
execution in a simple way. It's syntactically similar to
implementations of the async function found in other modules such as
L<forks>, L<threads>, and even L<Coro>. Unfortunately, all those
modules assumes you want to build your code around the framework
they provide and sometimes you do not want more than a simple way to
run code asynchronously. This module is a simple wrapper around
L<Proc::Simple> and provides nothing more than a convinient way of
forking off a task.

=head1 FUNCTIONS

=over 4

=item B<async>

  my $proc = async { some_task() };

Is just a more convinient way of doing:

  my $proc = Proc::Simple->new;

  $proc->start (sub { some_task() });

Any additional arguments passed to the function as shown in the
synopsis section is passed to the code provided in the first
argument.

=back

=head1 SEE ALSO

=over 4

=item L<Proc::Simple>

=back

=head1 BUGS

Most software has bugs. This module probably isn't an exception. 
If you find a bug please either email me, or add the bug to cpan-RT.

=head1 AUTHOR

Anders Nor Berle E<lt>berle@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Anders Nor Berle.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


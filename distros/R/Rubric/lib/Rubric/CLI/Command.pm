use strict;
use warnings;
package Rubric::CLI::Command;
# ABSTRACT: base class for Rubric::CLI commands
$Rubric::CLI::Command::VERSION = '0.156';
use parent qw(App::Cmd::Command);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rubric::CLI::Command - base class for Rubric::CLI commands

=head1 VERSION

version 0.156

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

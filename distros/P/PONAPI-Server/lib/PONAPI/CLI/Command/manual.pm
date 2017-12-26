# ABSTRACT: ponapi manual
package PONAPI::CLI::Command::manual;

use PONAPI::CLI -command;

use strict;
use warnings;

use Pod::Perldoc;

sub abstract      { "Show the PONAPI server manual" }
sub description   { "This tool will run perldoc PONAPI::Manual" }
sub opt_spec      {}
sub validate_args {}

sub execute {
    local $ARGV[0] = "PONAPI::Manual";
    Pod::Perldoc->run()
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::CLI::Command::manual - ponapi manual

=head1 VERSION

version 0.003002

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Test::BDD::Cucumber::Definitions;

use 5.006;
use strict;
use warnings;

use Exporter qw(import);
use Test::BDD::Cucumber::StepFile qw(Given When Then);

=head1 NAME

Test::BDD::Cucumber::Definitions - a collection of step definitions for Test
Driven Development

=head1 VERSION

Version 0.37

=cut

our $VERSION = '0.37';

=head1 SYNOPSIS

In file B<features/step_definitions/http_steps.pl>:

    #!/usr/bin/perl

    use strict;
    use warnings;

    use Test::BDD::Cucumber::Definitions::HTTP::In;

In file B<features/http.feature>:

    Feature: HTTP
        Site test by HTTP

    Scenario: Loading the page
        When http request "GET" send "http://metacpan.org"
        Then http response code eq "200"

... and, finally, in the terminal:

    $ pherkin

      HTTP
        Site test by HTTP

        Scenario: Loading the page
          When http request "GET" send "http://metacpan.org"
          Then http response code eq "200"


=head1 EXPORT

The module exports functions C<S>, C<C>, C<Given>, C<When> and C<Then>.
These functions are identical to the same functions from the module
L<Test::BDD::Cucumber>.

By default, no functions are exported. All functions must be imported
explicitly.

=cut

our @EXPORT_OK = qw(
    S C Given When Then
);

sub S { return Test::BDD::Cucumber::StepFile::S }
sub C { return Test::BDD::Cucumber::StepFile::C }

=head1 AUTHOR

Mikhail Ivanov C<< <m.ivanych@gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Mikhail Ivanov.

This is free software; you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system itself.

=cut

1;

use strict;
use warnings;
package Rubric::CLI::Command::linkcheck;
# ABSTRACT: check validity of links in the database
$Rubric::CLI::Command::linkcheck::VERSION = '0.156';
use parent qw(Rubric::CLI::Command);

use LWP::Simple ();
use Rubric::DBI::Setup;

sub run {
  my ($self, $opt, $args) = @_;

  my $links = Rubric::Link->retrieve_all;

  while (my $link = $links->next) {
    my $uri = $link->uri;
    if ($uri->scheme ne 'http') {
      print "unknown scheme on link $link\n";
      next;
    }

    unless (LWP::Simple::head($uri)) {
      print "couldn't get headers for $uri\n";
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rubric::CLI::Command::linkcheck - check validity of links in the database

=head1 VERSION

version 0.156

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

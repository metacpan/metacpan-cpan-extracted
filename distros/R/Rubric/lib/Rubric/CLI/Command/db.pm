use strict;
use warnings;
package Rubric::CLI::Command::db;
# ABSTRACT: database management
$Rubric::CLI::Command::db::VERSION = '0.156';
use parent qw(Rubric::CLI::Command);

use Rubric::DBI::Setup;

sub usage_desc { "rubric database %o" }

sub opt_spec {
  return (
    [ mode => hidden => {
      one_of => [
        [ "setup|s",  "set up a new database"       ],
        [ "update|u", "update your database schema" ],
      ],
      }
    ],
  );
}

sub validate_args {
  my ($self, $opt, $arg) = @_;

  die $self->usage->text unless $opt->{mode};
}

sub run {
  my ($self, $opt, $arg) = @_;

  if ($opt->{mode} eq 'setup') {
    Rubric::DBI::Setup->setup_tables;
  } elsif ($opt->{mode} eq 'update') {
    Rubric::DBI::Setup->update_schema;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rubric::CLI::Command::db - database management

=head1 VERSION

version 0.156

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

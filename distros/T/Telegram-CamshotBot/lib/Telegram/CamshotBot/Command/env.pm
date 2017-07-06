package Telegram::CamshotBot::Command::env;
$Telegram::CamshotBot::Command::env::VERSION = '0.03';
# ABSTRACT: prints list of all environment variables

use Mojo::Base 'Mojolicious::Command';
use Data::Printer;

has description => 'Prints list of set CAMSHOTBOT_* environment variables and its values';
has usage       => "Usage: APPLICATION env\n";

sub run {
  my $self = shift;
  print "### SETTED ENVIRONMENT VARIABLES ###\n";
  print `printenv | grep CAMSHOTBOT_* | sort -u`;
  print "\n\n";
  print "### VARIABLES FROM CONFIG ###\n";
  p $self->app->config;
  print "\n\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::CamshotBot::Command::env - prints list of all environment variables

=head1 VERSION

version 0.03

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use v5.14;
use warnings;

package Pantry::App::Command::init;
# ABSTRACT: Implements pantry init subcommand
our $VERSION = '0.012'; # VERSION

use Pantry::App -command;
use autodie;

sub abstract {
  return 'Initialize a pantry in the current directory';
}

my @pantry_dirs = qw(
  cookbooks
  environments
  reports
  roles
  data_bags
);

sub _init {
  my ($self, $opt) = @_;

  for my $d ( @pantry_dirs ) {
    if ( -d $d ) {
      say "Directory '$d' already exists";
    }
    else {
      mkdir $d;
      say "Directory '$d' created";
    }
  }
  return;
}

1;



# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=head1 NAME

Pantry::App::Command::init - Implements pantry init subcommand

=head1 VERSION

version 0.012

=head1 SYNOPSIS

  $ pantry init

=head1 DESCRIPTION

This class implements the C<pantry init> command, which creates subdirectories needed for
correct pantry operation.

=for Pod::Coverage options validate

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

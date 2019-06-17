package PMLTQ::Loader;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Loader::VERSION = '3.0.2';
# ABSTRACT: Module loader for L<PMLTQ::Relation|PMLTQ::Relation>s inspired by L<Mojo::Loader>


#use PMLTQ::Base -strict;
use strict;
use warnings;
use utf8;
use feature ":5.10";

use Exporter 'import';
use File::Basename 'fileparse';
use File::Spec;

our @EXPORT_OK
  = qw(find_modules load_class);

sub class_to_path { join '.', join('/', split /::|'/, shift), 'pm' }

sub load_class {
  my ($class) = @_;

  # Check module name
  return if !$class || $class !~ /^\w(?:[\w:']*\w)?$/;

  # Loaded
  return 1 if $class->can('new') || eval {
    my $file = class_to_path($class);
    require $file;
    1;
  };

  # Exists
  return if $@ =~ /^Can't locate \Q@{[class_to_path $class]}\E in \@INC/;

  # Real error
  die $@;
}

sub find_modules {
  my ($ns) = @_;

  my %modules;
  for my $directory (@INC) {
    next unless -d (my $path = File::Spec->catdir($directory, split(/::|'/, $ns)));

    # List "*.pm" files in directory
    opendir(my $dir, $path);
    for my $file (grep /\.pm$/, readdir $dir) {
      next if -d File::Spec->catfile(File::Spec->splitdir($path), $file);
      $modules{"${ns}::" . fileparse $file, qr/\.pm/}++;
    }
  }

  return keys %modules;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Loader - Module loader for L<PMLTQ::Relation|PMLTQ::Relation>s inspired by L<Mojo::Loader>

=head1 VERSION

version 3.0.2

=head1 SYNOPSIS

  use PMLTQ::Loader qw/find_modules load_class/;
  for my $module (find_modules('PMLTQ::Relation')) {
    print "Loading module: '$module'\n";
    load_class($module);
  }

=head1 DESCRIPTION

L<PMLTQ::Loader|PMLTQ::Loader> is a class loader and a part of the module
framework allowing users to define their own PML-TQ relations.

=head1 AUTHORS

=over 4

=item *

Petr Pajas <pajas@ufal.mff.cuni.cz>

=item *

Jan Štěpánek <stepanek@ufal.mff.cuni.cz>

=item *

Michal Sedlák <sedlak@ufal.mff.cuni.cz>

=item *

Matyáš Kopp <matyas.kopp@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Institute of Formal and Applied Linguistics (http://ufal.mff.cuni.cz).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

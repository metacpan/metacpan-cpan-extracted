package Module::CPANTS::Generator::Files;
use strict;
use Clone qw(clone);
use File::Spec::Functions;
use Module::CPANTS::Generator;
use base 'Module::CPANTS::Generator';

use vars qw($VERSION);
$VERSION = "0.004";

sub generate {
  my $self = shift;

  my $cpants = $self->grab_cpants;

  foreach my $dist (sort grep { -d } <*>) {
    if (exists $cpants->{$dist}->{files}) {
      $cpants->{cpants}->{$dist}->{files} = clone($cpants->{$dist}->{files});
      next;
    }

    my @files;
    foreach my $file (qw(Makefile.PL README Build.PL META.yml SIGNATURE MANIFEST)) {
      if (-f catfile($dist, $file)) {
	push @files, $file;
      }
      $cpants->{$dist}->{files} = \@files;
      $cpants->{cpants}->{$dist}->{files} = clone($cpants->{$dist}->{files});
    }
  }

  $self->save_cpants($cpants);
}

1;


__END__

=head1 NAME

Module::CPANTS::Generator::Files - Generate file information

=head1 SYNOPSIS

  use Module::CPANTS::Generator::Files;

  my $f = Module::CPANTS::Generator::Files->new;
  $f->directory("unpacked");
  $f->generate;

=head1 DESCRIPTION

This module is part of the beta CPANTS project. It scans through an
unpacked CPAN looking for specific files.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 LICENSE

This code is distributed under the same license as Perl.

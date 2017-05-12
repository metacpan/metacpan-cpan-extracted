package Module::CPANTS::Generator::Backpan;
use strict;
use File::Find::Rule;
use Module::CPANTS::Generator;
use base 'Module::CPANTS::Generator';

use vars qw($VERSION);
$VERSION = "0.004";

sub generate {
  my $self = shift;

  my $cpants = $self->grab_cpants;

  my $backpan;
  foreach my $file (sort File::Find::Rule->file()
    ->in("/home/acme/backpan/BACKPAN")) {
    $file =~ s{^.+/}{};
    next if $file =~ /.readme/;
    my $newfile = $self->massage($file);
#    print "$file -> $newfile\n";
    $backpan->{$newfile}++;
  }

  foreach my $dist (sort grep { -d } <*>) {
    my $newdist = $self->massage($dist);
    my $releases = $backpan->{$newdist};
#    print "$dist: $releases\n";
    $cpants->{cpants}->{$dist}->{releases} = $releases;
  }

  $self->save_cpants($cpants);
}

sub massage {
  my($self, $file) = @_;
  $file =~ s/\.tar.gz$//;
  $file =~ s/\.tgz$//;
  $file =~ s/\.zip$//;
  $file =~ s/-(\d|\.)+//;
  return $file;
}

1;


__END__

=head1 NAME

Module::CPANTS::Generator::Backpan - Generate release information

=head1 SYNOPSIS

  use Module::CPANTS::Generator::Backpan;

  my $b = Module::CPANTS::Generator::Backpan->new;
  $b->directory("unpacked");
  $b->generate;

=head1 DESCRIPTION

This module is part of the beta CPANTS project. It scans through a
Backpan mirror and generates the number of releases a distribution has
made.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 LICENSE

This code is distributed under the same license as Perl.

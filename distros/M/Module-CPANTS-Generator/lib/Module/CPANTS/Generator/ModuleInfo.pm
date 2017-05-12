package Module::CPANTS::Generator::ModuleInfo;
use strict;
use Carp;
use Clone qw(clone);
use File::Find::Rule;
use Pod::POM;
use Module::CPANTS::Generator;
use String::Approx qw(adist);
use base 'Module::CPANTS::Generator';

use vars qw($VERSION);
$VERSION = "0.005";

sub generate {
  my $self = shift;

  my $cpants = $self->grab_cpants;
  my $cp = $self->cpanplus || croak("No CPANPLUS object");

  my %seen;
  my $count;
#  foreach my $module (sort { $a->package cmp $b->package } values %{$cp->module_tree}) {
  foreach my $module (values %{$cp->module_tree}) {
    my $package = $module->package;
    next unless $package;
    next unless -d $package;
    next if $seen{$package}++;

    # copy over the size
    $cpants->{cpants}->{$package}->{size} = clone($cpants->{$package}->{size});

    if (not exists $cpants->{$package}->{author}) {
      my $author = $module->author;
      $cpants->{$package}->{author} = $author;
    }
    $cpants->{cpants}->{$package}->{author} = clone($cpants->{$package}->{author});

    if (not exists $cpants->{$package}->{description}) {
      my $description = $module->description;
      $description ||= $self->get_description($module->module, $package);
      $cpants->{$package}->{description} = $description;
    }
    $cpants->{cpants}->{$package}->{description} = clone($cpants->{$package}->{description});
  }

  $self->save_cpants($cpants);
}

sub get_description {
  my($self, $module, $package) = @_;
  my $cpanplus = $self->cpanplus;

  # get all the files in the package
  my @files = File::Find::Rule->file()
    ->name('*.pm')
    ->in($package);

  # find the main file in the package

print "* $package *\n";
  my $bestfile;
  my $bestscore = 1000;
  foreach my $file (@files) {
    my $origfile = $file;
    $file =~ s/$package//;
    $file =~ s{/}{-}g;
    $file =~ s/^-//;
    $file =~ s/\.pm$//;
    $file =~ s/^lib-//;
#    my $dist = adist($package, $file);
    my $dist = abs(adist($file, $package));
#    print "$file: $dist\n";
    if ($dist < $bestscore) {
      $bestfile = $origfile;
      $bestscore = $dist;
    }
  }
  print "  $bestfile\n";

  # parse the file and try and get the description

  my $parser = Pod::POM->new();

  my($name, $description);

  eval {
    my $pom = $parser->parse($bestfile)
      || return undef;

    foreach my $head1 ($pom->head1()) {
      my $title = $head1->title;
      next unless "$title" eq 'NAME';
      my $content = $head1->content;
      $content =~ s/\n/ /g;
      $content =~ s/ +/ /g;
      $content =~ s/ $//g;
      ($name, $description) = split /- ?/, $content, 2;
      print "  $description\n";
      last;
    }
  };

  if ($@) {
    print "  NOT FOUND DESCRIPTION\n";
  }

  return $description;
}

1;

__END__

=head1 NAME

Module::CPANTS::Generator::ModuleInfo - Find author, description

=head1 SYNOPSIS

  use Module::CPANTS::Generator::ModuleInfo;

  my $m = Module::CPANTS::Generator::ModuleInfo->new;
  $m->cpanplus($cpanplus);
  $m->generate;

=head1 DESCRIPTION

This module is part of the beta CPANTS project. It goes through the
CPANPLUS module tree and adds information about distribution author
and description. If the description is missing, it tries to find it
from the POD of the main module in the distribution.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 LICENSE

This code is distributed under the same license as Perl.

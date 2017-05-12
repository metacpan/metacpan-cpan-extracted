package Module::CPANTS::Generator;
use Carp;
use Cwd;
use Storable;
use strict;
use vars qw($VERSION);
$VERSION = "0.006";

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
}

sub cpanplus {
  my($self, $cpanplus) = @_;
  if (defined $cpanplus) {
    $self->{CPANPLUS} = $cpanplus;
  } else {
    return $self->{CPANPLUS};
  }
}

sub directory {
  my($self, $dir) = @_;
  if (defined $dir) {
    $self->{DIR} = $dir;
  } else {
    return $self->{DIR};
  }
}

sub origdir {
  my($self, $dir) = @_;
  if (defined $dir) {
    $self->{OLDDIR} = $dir;
  } else {
    return $self->{OLDDIR};
  }
}

# fetch the storabled thingy, and chdir to the unpacked root
sub grab_cpants {
  my $self = shift;

  my $cpants = {};
  eval {
    $cpants = retrieve("cpants.store");
  };
  # warn $@ if $@;
  $self->origdir(cwd);

  my $dir = $self->directory || croak("No directory specified");
  chdir $dir || croak("Could not chdir into $dir");

  return $cpants;
}

# chdir back, and store cpants
sub save_cpants {
  my $self = shift;
  my $cpants = shift;

  chdir $self->origdir;
  store($cpants, "cpants.store");
}

sub generate {
  die "ruh roh - virtual method call";
}


1;

__END__

=head1 NAME

Module::CPANTS::Generator - Generate Module::CPANTS

=head1 DESCRIPTION

This module is part of the beta CPANTS project. It consists of many
modules that unpack CPAN, gather meta information about it and create
the Module::CPANTS distribution. You only need this if you want to add
more metrics to Module::CPANTS.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 LICENSE

This code is distributed under the same license as Perl.


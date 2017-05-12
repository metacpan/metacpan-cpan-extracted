#!/usr/bin/env perl
use 5.006;
use strict; use warnings;

package App::Perl::Tags;
use Getopt::Long ();
use Pod::Usage qw/pod2usage/;
use File::Find::Rule;

use Perl::Tags;
use Perl::Tags::Hybrid;
use Perl::Tags::Naive::Moose; # includes ::Naive

our $VERSION = '0.032';

sub run {
  my $class = shift;

  my %options = (
    outfile => 'perltags',
    files => undef,
    depth => 10,
    variables => 1,
    ppi => 0,
    prune => [ ],
    help => sub { $class->usage() },
    version => sub { $class->version() },
  );

  Getopt::Long::GetOptions(
    \%options,
    'help|h',
    'version|v',
    'outfile|o=s',
    'files|L=s',
    'prune=s@',
    'depth|d=i',
    'variables|vars!',
    'ppi|p!',
  );

  if (defined $options{files}) {
    # Do not descend into explicitly specified files.
    $options{depth} = 1;
  } else {
    # If not files are specified via -files options, we expect some
    # paths after all the options.
    $class->usage() unless @ARGV
  }

  $options{paths} = \@ARGV;

  my $self = $class->new(%options);
  $self->main();
  exit();
}

sub new {
  my ($class, %options) = @_;
  $options{prune} = [ '.git', '.svn' ] unless @{ $options{prune} || [] };
  return bless \%options, $class;
}

sub version {
  print "perl-tags v. $VERSION (Perl Tags v. $Perl::Tags::VERSION)\n";
  exit();
}

sub usage {
  pod2usage(0);
}

sub main {
  my $self = shift;

  my %args = (
    max_level    => $self->{depth},
    exts         => 1,
    do_variables => $self->{variables},
  );

  my @taggers = ( Perl::Tags::Naive::Moose->new( %args ) );
  if ($self->{ppi}) {
    require Perl::Tags::PPI;
    push @taggers, Perl::Tags::PPI->new( %args );
  }

  my $ptag = Perl::Tags::Hybrid->new( %args, taggers => \@taggers );

  my @files = do {
    if (defined $self->{files}) {
      if ('-' eq $self->{files}) {
        map { chomp; $_ } <STDIN>;
      } else {
        my $fh = IO::File->new($self->{files})
          or die "cannot open $$self{files} for reading: $!";
        map { chomp; $_ } <$fh>;
      }
    } else {
      $self->get_files;
    }
  };

  $ptag->process(files => \@files);
  $ptag->output(outfile => $self->{outfile}); 
  return;
}

sub get_files {
  my $self = shift;
  my @prune = @{ $self->{prune} };
  my @paths = @{ $self->{paths} };

  my $rule = File::Find::Rule->new;

  my @files = 
    $rule->or(
      $rule->new
           ->directory
           ->name(@prune)
           ->prune
           ->discard,
      $rule->new
        ->file,
    )->in(@paths);

  return @files;
}

=head1 AUTHOR

Copyright 2009-2014, Steffen Mueller, with contributions from osfameron

=cut

# vim:ts=2:sw=2

1;

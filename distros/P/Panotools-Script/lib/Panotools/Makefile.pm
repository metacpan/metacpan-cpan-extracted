package Panotools::Makefile;

=head1 NAME

Panotools::Makefile - Makefile creation

=head1 SYNOPSIS

Simple object interface for generating Makefiles

=head1 DESCRIPTION

Writing Makefiles directly from perl scripts with print and "\t" etc... is
prone to error, this library provides a simple perl interface for assembling
Makefiles.

Note GNU make syntax is assumed, i.e. on BSD systems where pmake is the default
you will have to switch to gmake if you want to work with weirdly named targets
containing special characters such as spaces or parentheses.

=cut

use strict;
use warnings;

use Panotools::Script;
use Panotools::Makefile::Rule;
use Panotools::Makefile::Variable;
use Panotools::Makefile::Comment;
use File::Temp qw/tempdir/;
use File::Spec;

=head1 USAGE

  use Panotools::Makefile;

Create a new Makefile object:

  my $makefile = new Panotools::Makefile;

=cut

sub new
{
    my $class = shift;
    $class = ref $class || $class;
    my $self = bless {items => []}, $class;
    return $self;
}

=pod

Start adding items to the Makefile:

Rule() returns a new L<Panotools::Makefile::Rule> object, Variable() returns a
new L<Panotools::Makefile::Variable> object and Comment() returns a new
L<Panotools::Makefile::Comment> object:

  my $var_user = $makefile->Variable ('USER');
  $var_user->Values ("Dr. Largio d'Apalansius (MB)");

  my $rule_all = $makefile->Rule ('all');
  $rule_all->Command ('echo', '$(USER_SHELL)', '>', 'My File.txt');

  $makefile->Comment ('.PHONY target isn't strictly necessary in this case');
  my $rule_phony = $makefile->Rule;
  $rule_phony->Targets ('.PHONY');
  $rule_phony->Prerequisites ('all');

=cut

sub Rule
{
    my $self = shift;
    my $rule = new Panotools::Makefile::Rule (@_);
    push @{$self->{items}}, $rule;
    return $rule;
}

sub Variable
{
    my $self = shift;
    my $variable = new Panotools::Makefile::Variable (@_);
    push @{$self->{items}}, $variable;
    return $variable;
}

sub Comment
{
    my $self = shift;
    my $comment = new Panotools::Makefile::Comment (@_);
    push @{$self->{items}}, $comment;
    return $comment;
}

=pod

Assemble all this into string that can be written to a Makefile:

  my $string = $makefile->Assemble;

=cut

sub Assemble
{
    my $self = shift;
    "# Created by Panotools::Script $Panotools::Script::VERSION\n\n"
      . join '', map {$_->Assemble} @{$self->{items}};
}

=pod

..or write the Makefile:

  $makefile->Write ('/path/to/Makefile');

=cut

sub Write
{
    my $self = shift;
    my $path_makefile = shift;
    open MAKE, ">", $path_makefile or warn "cannot write-open $path_makefile";
    print MAKE $self->Assemble;
    close MAKE;
}

=pod

..or let the module execute rules with 'make' directly:

  $makefile->DoIt ('all') || warn "Didn't work :-(";

The following command will be executed, something that isn't possible with perl
system() or exec(), and would otherwise require careful assembly with backticks:

  echo Dr.\ Largio\ d\'Apalansius\ \(MB\) > My\ File.txt

On the Windows platform you get appropriate quoting:

  echo "Dr. Largio d'Apalansius (MB)" > "My File.txt"

=cut

sub DoIt
{
    my $self = shift;
    my $tempdir = tempdir (CLEANUP => 1);
    my $path_makefile = File::Spec->catfile ($tempdir, 'Makefile');
    $self->Write ($path_makefile);
    my $make_exe = 'make';
    $make_exe = 'gmake' if ($^O =~ /^(.*bsd|dragonfly|irix|solaris|sunos)$/);
    system ($make_exe, '-f', $path_makefile, @_);
    return 1 if ($? == 0);
    return 0;
}

1;


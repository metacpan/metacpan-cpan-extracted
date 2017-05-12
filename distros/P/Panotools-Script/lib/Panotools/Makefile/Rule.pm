package Panotools::Makefile::Rule;

=head1 NAME

Panotools::Makefile::Rule - Assemble Makefile rules

=head1 SYNOPSIS

Simple interface for generating Makefile syntax

=head1 DESCRIPTION

Writing Makefiles directly from perl scripts with print and "\t" etc... is
prone to error, this library provides a simple perl interface for assembling
Makefile rules.

=cut

use strict;
use warnings;

use Panotools::Makefile::Utils qw/quotetarget quoteprerequisite quoteshell/;

=head1 USAGE

  my $rule = new Panotools::Makefile::Rule;

..or additionally specify targets at creation time

  my $rule = new Panotools::Makefile::Rule ('all');

=cut

sub new
{
    my $class = shift;
    $class = ref $class || $class;
    my $self = bless {targets => [@_], prerequisites => [], command => []}, $class;
    return $self;
}

=pod

A Makefile rule always has one or more 'targets', these are typically
filenames, but can be 'phony' non-files.

(phony targets should be listed as perequisites of the special .PHONY target)

  $rule->Targets ('output1.txt', 'output2.txt');

..or equivalently:

  $rule->Targets ('output1.txt');
  $rule->Targets ('output2.txt');

=cut

sub Targets
{
    my $self = shift;
    push @{$self->{targets}}, @_;
    #warn 'Error: unescapable =;:% in targets: '. join (' ', @_) if grep /[=;:%]/, @_;
    #warn 'Warning: non-portable target name: '. join (' ', @_) if grep /[?<>:*|"^]/, @_;
}

=pod

Rules can have zero or more 'prerequisites', again these are typically
filenames, but can be 'phony' non-files.

  $rule->Prerequisites ('input1.txt', 'input2.txt');

..or equivalently:

  $rule->Prerequisites ('input1.txt');
  $rule->Prerequisites ('input2.txt');

=cut

sub Prerequisites
{
    my $self = shift;
    push @{$self->{prerequisites}}, @_;
    #warn 'Error: unescapable =;:% in prerequisites: '. join (' ', @_) if grep /[=;:%]/, @_;
    #warn 'Warning: non-portable target name: '. join (' ', @_) if grep /[?<>:*|"^]/, @_;
}

=pod

Rules zero or more 'commands':

  $rule->Command ('cp', 'input1.txt', 'output1.txt');
  $rule->Command ('cp', 'input2.txt', 'output2.txt');

=cut

sub Command
{
    my $self = shift;
    push @{$self->{command}}, [@_];
}

=pod

Assemble all this into string that can be written to a Makefile:

  my $string = $rule->Assemble;

=cut

sub Assemble
{
    my $self = shift;
    my $opts = shift || {};
    return '' unless scalar @{$self->{targets}};

    my $text;
    $text .= join ' ', (map { quotetarget ($_)} @{$self->{targets}});
    $text .= ' : ';
    $text .= join ' ', (map { quoteprerequisite ($_)} @{$self->{prerequisites}});
    for my $command (@{$self->{command}})
    {
        $text .= "\n\t";
        $text .= join ' ', (map { quoteshell ($_)} @{$command});
        next unless defined $opts->{warnings};
        for my $token (@{$command})
        {
            my @vars = $token =~ /\$\([[:alnum:]_]+\)/g;
            for my $var (@vars)
            {
                warn "underquoted \"$token\"" unless $var =~ /\$\([[:alnum:]_]+_SHELL\)/;
            }
        }
    }
    $text .= "\n\n";
    return $text;
}

1;

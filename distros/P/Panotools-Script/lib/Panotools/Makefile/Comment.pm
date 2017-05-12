package Panotools::Makefile::Comment;

=head1 NAME

Panotools::Makefile::Comment - Assemble Makefile Comment lines

=head1 SYNOPSIS

Simple interface for generating Makefile syntax

=head1 DESCRIPTION

Writing Makefiles directly from perl scripts with print and "\t" etc... is
prone to error, this library provides a simple perl interface for assembling
Makefiles.

=cut

use strict;
use warnings;

=head1 USAGE

  my $note = new Panotools::Makefile::Comment;

..or add text at the same time:

  my $note = new Panotools::Makefile::Comment ('Warning, may not eat your cat!');

=cut

sub new
{
    my $class = shift;
    $class = ref $class || $class;
    my $self = bless [@_], $class;
    return $self;
}

=pod

Add lines to the comment:

  $note->Lines ('..but it might...', '...sometimes');

=cut

sub Name
{
    my $self = shift;
    push @{$self}, @_;
}

=pod

Construct a text fragment suitable for use in a Makefile like so:

  $text = $note->Assemble;

=cut

sub Assemble
{
    my $self = shift;
    return '' unless scalar @{$self};

    my $text = "\n# ";
    $text .= join "\n# ", @{$self};
    return $text . "\n";
}

1;

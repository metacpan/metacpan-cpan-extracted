package Panotools::Makefile::Variable;

=head1 NAME

Panotools::Makefile::Variable - Assemble Makefile Variable definitions

=head1 SYNOPSIS

Simple interface for generating Makefile syntax

=head1 DESCRIPTION

Writing Makefiles directly from perl scripts with print and "\t" etc... is
prone to error, this library provides a simple perl interface for assembling
Makefiles.

=cut

use strict;
use warnings;

use Panotools::Makefile::Utils qw/quotetarget quoteprerequisite quoteshell/;

=head1 USAGE

  $var = new Panotools::Makefile::Variable;

..or define the 'variable name' at the same time:

  $var = new Panotools::Makefile::Variable ('USERS');

..or define the name and values at the same time:

  $var = new Panotools::Makefile::Variable ('USERS', 'Andy Pandy');

=cut

sub new
{
    my $class = shift;
    $class = ref $class || $class;
    my $self = bless {name => shift, value => [@_]}, $class;
    return $self;
}

=pod

Set or query the name:

  $var->Name ('USERS');
  $text = $var->Name;

=cut

sub Name
{
    my $self = shift;
    $self->{name} = shift if @_;
    return $self->{name};
}

sub NameRef
{
    my $self = shift;
    return '$('. $self->Name .')';
}

sub NameRefShell
{
    my $self = shift;
    return '$('. $self->Name .'_SHELL)';
}

=pod

  $var->Values ('James Brine', 'George Loveless');
  $var->Values ('Thomas Standfield');

=cut

sub Values
{
    my $self = shift;
    push @{$self->{value}}, @_;
    return $self->{value};
}

=pod

Construct a text fragment that defines this variable suitable for use in a
Makefile like so:

  $text = $var->Assemble;

=cut

sub Assemble
{
    my $self = shift;
    return '' unless defined $self->{name};

    my $text;
    $text .= quotetarget ($self->{name});
    $text .= ' = ';
    $text .= join ' ', (map { quotetarget ($_)} grep /./, @{$self->{value}});
    $text .= "\n";
    $text .= quotetarget ($self->{name} .'_SHELL');
    $text .= ' = ';
    my @items = map { quoteshell ($_)} grep /./, @{$self->{value}};
    @items = map {s/\$\(([^)]+)\)/\$($1_SHELL)/g; $_} @items;
    $text .= join ' ', @items;
    $text .= "\n";
    return $text;
}

1;

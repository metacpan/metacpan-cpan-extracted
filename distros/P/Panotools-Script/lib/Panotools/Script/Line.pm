package Panotools::Script::Line;

use strict;
use warnings;

use Storable qw/ dclone /;

=head1 NAME

Panotools::Script::Line - Panorama Tools script data

=head1 SYNOPSIS

Base class for a line in a panotools script

=head1 DESCRIPTION

A line starts with a single letter identifier then a series of
namevalue items separated by whitespace

=head1 USAGE

  my $line = new Panotools::Script::Line::Foo;

=cut

sub new
{
    my $class = shift;
    $class = ref $class || $class;
    my $self = bless {}, $class;
    $self->_defaults;
    return $self;
}

=pod

  my $identifier = $line->Identifier;

=cut

sub Identifier
{
    return '#';
}

=pod

  $line->Parse ('f a1.0 b2.0 bar3.0');

=cut

sub Parse
{
    my $self = shift;
    my $string = shift || return 0;
    my $valid = $self->_valid;
    my @res = $string =~ / ([a-zA-Z][^ "]+)|([a-zA-Z][a-z]*"[^"]+")/g;
    for my $token (grep { defined $_ } @res)
    {
        my ($key, $value) = $token =~ /$valid/;
        next unless defined $key;
        $self->{$key} = $value;
    }
    $self->_sanitise;
    return 1;
}

=pod

  my $string = $line->Assemble;

=cut

sub Assemble
{
    my $self = shift;
    $self->_sanitise;
    my @tokens;
    for my $entry (sort keys %{$self})
    {
        push @tokens, $entry . $self->{$entry};
    }
    return (join ' ', ($self->Identifier, @tokens)) ."\n" if (@tokens);
    return '';
}

=pod

  $line->Set (a => 'something', b => 2);

=cut

sub Set
{
    my $self = shift;
    my %hash = @_;
    for my $entry (sort keys %hash)
    {
        $self->{$entry} = $hash{$entry};
    }
    $self->_sanitise;
}

=pod

Clone a line object

 $clone = $l->Clone;

=cut

sub Clone
{
    my $self = shift;
    dclone ($self);
}

sub _defaults {}

sub _valid { return '^(.)(.*)' }

sub _sanitise
{
    my $self = shift;
    my $valid = $self->_valid;
    for my $key (keys %{$self})
    {
        delete $self->{$key} unless (grep /$valid/, $key);
    }
}

1;


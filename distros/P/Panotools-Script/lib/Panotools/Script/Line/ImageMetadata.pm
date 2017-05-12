package Panotools::Script::Line::ImageMetadata;

use strict;
use warnings;
use Panotools::Script::Line;

use vars qw /@ISA/;
@ISA = qw /Panotools::Script::Line/;

=head1 NAME

Panotools::Script::Line::ImageMetadata - hugin input image metadata

=head1 SYNOPSIS

A single input image is described by an 'i' line, this is optionally prefixed
by a '#-hugin' line containing metadata in a key=value format

=head1 DESCRIPTION

=cut

sub Assemble
{
    my $self = shift;
    $self->_sanitise;
    my @tokens;
    for my $entry (sort keys %{$self})
    {
        if ($entry eq "disabled")
	{
	    push @tokens, $entry;
	}
	else
	{
	    push @tokens, $entry .'='. $self->{$entry};
	}
    }
    return (join ' ', ($self->Identifier, @tokens)) ."\n" if (@tokens);
    return '';
}

sub _defaults
{
    my $self = shift;
}

sub _valid { return '^([^=]+)(?:=(.*)|)$' }

sub Identifier
{
    my $self = shift;
    return "#-hugin";
}

sub _sanitise
{
    my $self = shift;
    my $valid = $self->_valid;
    for my $key (keys %{$self})
    {
        delete $self->{$key} unless ( grep /$valid/, "$key=" || grep /$valid/, "$key" );
    }
}

sub Report
{
    my $self = shift;
    my @report;
    for my $entry (sort keys %{$self})
    {
	if ($entry eq "disabled")
	{
	    push @report, ["State",$entry];
	}
	else
	{
	    my @tokens = $entry =~ /(^[a-z]+|[A-Z][a-z]+|[A-Z][A-Z]+(?=[A-Z][a-z]))/g;
	    my $name = join ' ', @tokens;
	    push @report, [$name, $self->{$entry}] unless ($self->{$entry} =~ /false/i);
	}
    }
    [@report];
}


1;


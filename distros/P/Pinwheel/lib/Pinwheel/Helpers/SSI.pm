package Pinwheel::Helpers::SSI;

use strict;
use warnings;

use Exporter;

require Pinwheel::Controller;
use Pinwheel::View::String;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    ssi_if_exists
    ssi_if_not_exists
    ssi_include
    ssi_set
);


sub ssi_if_exists
{
    my $fn = pop;
    my $path = (scalar(@_) > 1) ? Pinwheel::Controller::url_for(@_) : shift;
    return ssi_flastmod($path, '!=', [&$fn()]);
}

sub ssi_if_not_exists
{
    my $fn = pop;
    my $path = (scalar(@_) > 1) ? Pinwheel::Controller::url_for(@_) : shift;
    return ssi_flastmod($path, '=', [&$fn()]);
}

sub ssi_flastmod
{
    # Not exposed to the templates, but useful as a building block for other
    # helpers
    my ($path, $cond, $content, $else_content) = @_;
    my ($s);

    $s = [
        ['<!--#func var="file" func="flastmod" virtual="'], $path, ["\" -->\n"],
        ['<!--#if expr="(${file} '], $cond, [' /\(none\)/)" -->' . "\n"],
        $content,
    ];
    push @$s, ["<!--#else -->\n"], $else_content if defined($else_content);
    push @$s, ["<!--#endif -->\n"];

    return Pinwheel::View::String->new($s);
}

sub ssi_include
{
    my ($path);

    $path = (scalar(@_) > 1) ? Pinwheel::Controller::url_for(@_) : shift;
    return Pinwheel::View::String->new([
        ['<!--#include virtual="'], $path, ['" -->']
    ]);
}

sub ssi_set
{
    my ($var, $value) = @_;

    return Pinwheel::View::String->new([
        ['<!--#set var="'], $var, ['" value="'], $value, ['" -->'],
    ]);
}


1;

package AbbrevApp::Cmd::ThuruksPride;

use strict;
use warnings;

BEGIN
{
    my $moodel = $ENV{WHICH_MOODEL} || "Moo";
    eval "use $moodel;";
    $@ and die $@;
    $moodel->import;
}
use MooX::Cmd;

has race           => is => ro => default   => "Split";
has security_level => is => ro => default   => "Core";
has planets        => is => ro => predicate => 1 => default => "3";
has stations       => is => ro => predicate => 1 => default => "11";
has asteroids      => is => ro => predicate => 1 => default => "1";
has north_gate     => is => ro => predicate => 1 => default => "FamilyZein";
has south_gate     => is => ro => predicate => 1 => default => "RhonkarsFire";
has east_gate      => is => ro => predicate => 1 => default => "CompanyPride";
has west_gate      => is => ro => predicate => 1;

sub execute { @_ }

1;

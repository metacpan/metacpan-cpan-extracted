package AbbrevApp::Cmd::ThuruksBeard;

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
has security_level => is => ro => default   => "Border";
has planets        => is => ro => predicate => 1 => default => "1";
has stations       => is => ro => predicate => 1 => default => "13";
has asteroids      => is => ro => predicate => 1 => default => "0";
has north_gate     => is => ro => predicate => 1 => default => "FamilyRhonkar";
has south_gate     => is => ro => predicate => 1 => default => "HatikvahsFaith";
has east_gate      => is => ro => predicate => 1;
has west_gate      => is => ro => predicate => 1 => default => "CompanyPride";

sub execute { @_ }

1;

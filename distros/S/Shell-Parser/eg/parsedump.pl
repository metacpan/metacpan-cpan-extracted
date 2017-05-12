#!/usr/bin/perl
use strict;
use Shell::Parser;

my $parser = new Shell::Parser handlers => { default => \&dumpnode };
$parser->parse(join '', <>);

sub dumpnode {
    my $self = shift;
    my %args = @_;
    print "$args{type}: <$args{token}>\n"
}

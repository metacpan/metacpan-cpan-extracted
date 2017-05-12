#!/usr/bin/perl -w
########################################################################
# This is not designed to be a serious application but is designed to
# be part of the testing of the RPG::Traveller::Person module.
#
# However if a game master wanted to create a bunch of raw recruits
# this program would do the trick... :-)
#
# PODNAME: CreateBasePeople.pl -- Create a bunch of "base" people.
# ABSTRACT:  CreateBasePeople.pl [--qty=10] [--debug]

use strict;
use RPG::Traveller::Person;
use Getopt::Long;
use Data::Dumper;
my $debug  = 0;
my $nchars = 10;

my $res = GetOptions(
    "qty=i" => \$nchars,
    "debug" => \$debug
);    # debug is really for the author only

my $person = undef;

foreach ( 1 .. $nchars ) {
    $person = RPG::Traveller::Person->new();
    print Dumper($person) if $debug;
    exit if !$person;
    $person->initUPP();
    printf "%s\n", $person->toString();
}

exit(0);

__END__

=pod

=head1 NAME

CreateBasePeople.pl -- Create a bunch of "base" people. - CreateBasePeople.pl [--qty=10] [--debug]

=head1 VERSION

version 1.020

=head1 AUTHOR

Peter L. Berghold <cpan@berghold.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Peter L. Berghold.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

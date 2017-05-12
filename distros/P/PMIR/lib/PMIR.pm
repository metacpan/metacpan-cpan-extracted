package PMIR;
use 5.006001;
use strict;
use warnings;
$PMIR::VERSION = '0.01';

my $base;
BEGIN {
    $base = $ENV{PMIR_BASE}
        or die "PMIR_BASE environment variable not set";
}

sub import {
    use lib "$base/perl5/lib";
}

1;

=head1 NAME

PMIR - Personally Man, I'd Relax

=head1 SYNOPSIS

    use PMIR;

=head1 DESCRIPTION

PMIR is the new CPAN. Stay tuned...

=head1 AUTHOR

Ingy döt Net

=head1 COPYRIGHT

Copyright (c) 2007. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

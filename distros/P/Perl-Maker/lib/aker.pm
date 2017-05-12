package aker;
use strict;
use warnings;

use Perl::Maker;

sub import {
    my $spec_file = shift || 'perl-spec.yaml';
    Perl::Maker->new(
        spec_file => $spec_file,
    )->write_makefile;
}

1;

=encoding utf8

=head1 NAME

aker - Support Modules for 'perl -Maker'

=head1 SYNOPSIS

    > perl -Maker

=head1 DESCRIPTION

This is the sugar module for Perl Maker. Instead of writing:

    perl -MPerl::Maker -e 'Perl::Maker->new(spec_file => 'perl-spec.yaml')->write_makefile'

You can just write:

    perl -Maker perl-spec.yaml

Or simply:

    perl -Maker

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2011. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

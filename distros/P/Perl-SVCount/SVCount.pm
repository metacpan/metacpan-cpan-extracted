package Perl::SVCount;
use XSLoader ();

our $VERSION = '0.02';

XSLoader::load 'Perl::SVCount', $VERSION;

# keep it lightweight, since this is an instrumentation module
sub import {
    *{caller() . '::sv_count'} = *sv_count;
}

1;

__END__

=head1 NAME

Perl::SVCount - Get global count of allocated SVs

=head1 SYNOPSIS

    my $count = sv_count();
    ... # some code here
    say "Allocated " . (sv_count() - $count) . " more SVs";

=head1 DESCRIPTION

This module allows to access perl's internal global counters of allocated SVs.
This might be useful for quickly detecting memory leaks.

C<sv_count()> returns how many SVs (scalar values) are currently allocated.

=head1 AUTHOR

Copyright (c) 2012 Rafael Garcia-Suarez.

The git repository for this module can be found at L<https://github.com/rgs/Perl-SVCount>.

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

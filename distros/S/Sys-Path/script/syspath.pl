#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long 'GetOptions';
use Pod::Usage 'pod2usage';
use Sys::Path::SPc;

exit main();

sub main {
    my $help;
    GetOptions('help|h' => \$help) or pod2usage(-exitval => 2);
    pod2usage({
        -exitval  => 0,
        -verbose  => 99,
        -sections => 'NAME|SYNOPSIS|DESCRIPTION',
    }) if $help;

    my @path_types = Sys::Path::SPc->_path_types;
    my %is_path_type = map { ($_ => 1) } @path_types;
    my @selected = @ARGV ? @ARGV : @path_types;

    for my $path_type (@selected) {
        pod2usage(
            -exitval => 2,
            -message => qq{Unknown path key "$path_type"},
        ) if not $is_path_type{$path_type};
    }

    for my $path_type (@selected) {
        print $path_type, "\t", Sys::Path::SPc->$path_type, "\n";
    }

    return 0;
}

__END__

=encoding utf-8

=head1 NAME

syspath.pl - print configured system paths

=head1 SYNOPSIS

    syspath.pl
    syspath.pl sysconfdir sharedstatedir
    syspath.pl --help

=head1 DESCRIPTION

Print the active L<Sys::Path::SPc> path keys and their configured values. Each
line contains a key and value separated by a tab.

With no arguments, print every active path in canonical order. With arguments,
print only the named paths in command-line order.

C<--help> and C<-h> print this documentation. Accepted path keys are:

    prefix
    localstatedir
    sysconfdir
    datadir
    docdir
    cachedir
    logdir
    spooldir
    rundir
    lockdir
    localedir
    sharedstatedir
    webdir
    srvdir

=head1 ERRORS

An unknown path key terminates the program with a usage error. No path output
is produced if any requested key is unknown.

=cut

#!/usr/bin/env perl

# Taken from
# http://www.chrisdolan.net/talk/index.php/2005/11/14/private-regression-tests/.

use 5.008004;
use utf8;
use strict;
use warnings;

use version; our $VERSION = qv('v1.18.0');

use File::Find;
use File::Slurp;

use Test::More qw< no_plan >;


my $no_file_message = 'Failed to find any files with $VERSION.'; ## no critic (RequireInterpolationOfMetachars)


my $last_version = undef;
find(
    {wanted => \&check_version, no_chdir => 1},
    grep { -e $_ } qw< lib bin t xt >,
);
if (not defined $last_version) {
    fail($no_file_message);
} # end if


sub check_version {
    # $_ is the full path to the file
    return if not m<bin/>xms and not m< [.] (?: pm | t ) \z >xms;

    my $content = read_file($_);

    # only look at perl scripts, not sh scripts
    return if m<bin/>xms and $content !~ m< \A \#![^\r\n]+?perl >xms;

    my @version_lines = $content =~ m< ( [^\n]* \$ VERSION [^\n]* ) >xmsg;

    # Avoid self-violation.
    @version_lines = grep { 0 > index $_, $no_file_message } @version_lines;

    if (@version_lines == 0) {
       fail($_);
    } # end if
    foreach my $line (@version_lines) {
        if (not defined $last_version) {
            $last_version = shift @version_lines;
            pass($_);
        } else {
            is($line, $last_version, $_);
        } # end if
    } # end foreach

    return;
} # end check_version()

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 wrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :

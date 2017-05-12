#!/usr/bin/env perl

#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic-Compatibility/xt/author/consistent_version_numbers.t $
#     $Date: 2008-05-09 10:51:28 -0500 (Fri, 09 May 2008) $
#   $Author: clonezone $
# $Revision: 2333 $

# Taken from
# http://www.chrisdolan.net/talk/index.php/2005/11/14/private-regression-tests/.

use 5.006;

use strict;
use warnings;

use version; our $VERSION = qv('v1.1');

use File::Find;
use File::Slurp;

use Test::More qw(no_plan); ## no critic (Bangs::ProhibitNoPlan)


my $last_version = undef;
find({wanted => \&check_version, no_chdir => 1}, 'blib');
if (! defined $last_version) {
    ## no critic (RequireInterpolationOfMetachars)
    fail('Failed to find any files with $VERSION');
    ## use critic
} # end if


sub check_version {
    # $_ is the full path to the file
    return if ! m{blib/script/}xms && ! m{ [.] pm \z}xms;

    my $content = read_file($_);

    # only look at perl scripts, not sh scripts
    return if m{blib/script/}xms && $content !~ m/\A \#![^\r\n]+?perl/xms;

    my @version_lines = $content =~ m/ ( [^\n]* \$VERSION [^\n]* ) /gxms;
    if (@version_lines == 0) {
       fail($_);
    } # end if
    foreach my $line (@version_lines) {
        if (!defined $last_version) {
            $last_version = shift @version_lines;
            pass($_);
        } else {
            is($line, $last_version, $_);
        } # end if
    } # end foreach

    return;
} # end check_version()

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :

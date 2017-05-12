#!/usr/bin/env perl

#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/PPIx-Utilities/xt/author/copyright.t $
#     $Date: 2010-12-01 20:31:47 -0600 (Wed, 01 Dec 2010) $
#   $Author: clonezone $
# $Revision: 4001 $

# Taken from
# http://www.chrisdolan.net/talk/index.php/2005/11/14/private-regression-tests/.

## no critic (ProhibitFlagComments, ProhibitUnusualDelimiters, RequireBracesForMultiline)
## TODO: enable these once the policies accept other braces.

use 5.006;

use strict;
use warnings;

our $VERSION = '1.001000';

use File::Find;
use File::Slurp;
use Readonly;

use Test::More qw(no_plan);


Readonly my $LOCALTIME_YEAR_FIELD_NUMBER => 5;
Readonly my $LOCALTIME_YEAR_OFFSET       => 1900;


my $this_year =
    (localtime)[$LOCALTIME_YEAR_FIELD_NUMBER] + $LOCALTIME_YEAR_OFFSET;
my $copyrights_found = 0;
find({wanted => \&check_file, no_chdir => 1}, 'blib');
foreach ( grep { m/^readme/ixms } read_dir(q<.>) ) {
    check_file();
} # end foreach

ok($copyrights_found != 0, 'found a copyright statement');


sub check_file {
    # $_ is the path to a filename, relative to the root of the
    # distribution

    # Only test plain files
    return if (! -f $_);

    # Filter the list of filenames
    return if not
        m<
            ^
            (?: README.*          # docs
                |  .*/scripts/[^/]+  # programs
                |  .*/script/[^/]+   # programs
                |  .*/bin/[^/]+      # programs
                |  .* [.] (?:
                            pl        # program ext
                        |   pm        # module ext
                        |   html      # doc ext
                        |   3pm       # doc ext
                        |   [13]      # doc ext
                    )
            )
            $
        >xms;
    ## use critic

    my $content = read_file($_);

    # Note: man pages will fail to match if the correct form of the
    # copyright symbol is used because the man page translators don't
    # handle UTF-8.
    #
    # For some reason, Vim writes a bad utf8 version of the copyright sign
    # if I attempt to modify the line.  So, disable the violation.  *sigh*
    ## no critic (ProhibitEscapedMetacharacters)
    my @copyright_years = $content =~ m/
                                       (?: copyright | \(c\) )
                                       \s*
                                       (?: \d{4} \\? - )?
                                       (\d{4})
                                       /gixms;
    if (0 < grep {$_ ne $this_year} @copyright_years) {
        fail("$_ copyrights: @copyright_years");
    } elsif (0 == @copyright_years) {
        pass("$_, no copyright found");
    } else {
        pass($_);
    } # end if

    return $copyrights_found += @copyright_years;
} # end check_file()

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :

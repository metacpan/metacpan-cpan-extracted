#!/usr/bin/perl

use strict;
use warnings;

our $VERSION = '0.999_001';

use File::Find;
use File::Slurp;    ## no critic (DiscouragedModules)
use Readonly;

use Test::More qw(no_plan);    ## no critic (Bangs::ProhibitNoPlan)

Readonly my $LOCALTIME_YEAR_FIELD_NUMBER => 5;
Readonly my $LOCALTIME_YEAR_OFFSET       => 1900;

my $this_year = (localtime)[$LOCALTIME_YEAR_FIELD_NUMBER] + $LOCALTIME_YEAR_OFFSET;
my $copyrights_found = 0;
find({ wanted => \&check_file, no_chdir => 1 }, 'lib');
foreach (grep { m/^readme/ixms } read_dir(q<.>)) {
    check_file();
}                              # end foreach

ok($copyrights_found != 0, 'found a copyright statement');

sub check_file {

    # $_ is the path to a filename, relative to the root of the
    # distribution

    # Only test plain files
    return if (!-f $_);

    ## no critic (ProhibitComplexRegexes)
    # Filter the list of filenames
    return if not m<
            ^
            (?: README.*          # docs
                |  .*/scripts/[^/]+  # programs
                |  .*/script/[^/]+   # programs
                |  .*/bin/[^/]+      # programs
                |  .*\.(?:
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
    my @copyright_years = $content =~ m<
                                       (?: copyright(?:\s\(c\))? | \(c\) )
                                       \s*
                                       (?: \d{4} \\? [-,]\s*)*
                                       (\d{4})
                                       >gixms;
    if (0 < grep { $_ eq $this_year } @copyright_years) {
        pass($_);
    } elsif (0 == @copyright_years) {
        pass("$_, no copyright found");
    } else {
        fail("$_ copyrights: @copyright_years");
    }    # end if

    return $copyrights_found += @copyright_years;
}    # end check_file()

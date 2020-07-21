# Helper functions for PGP::Sign tests.
#
# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

package Test::PGP 1.00;

use 5.020;
use autodie;
use warnings;

use Exporter qw(import);
use IPC::Cmd qw(run);

our @EXPORT_OK = qw(gpg_is_gpg1);

# Test if the gpg binary found first on PATH is actually gpg1.
#
# Returns: 1 if so, undef if not or on any errors
sub gpg_is_gpg1 {
    my $output;
    if (!run(command => ['gpg', '--version'], buffer => \$output)) {
        return;
    }
    return $output =~ m{ ^ gpg [^\n]* \s 1 [.] }xms;
}

1;

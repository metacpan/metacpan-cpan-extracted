#!/usr/local/bin/perl -w

# Experimental code, written by Rodger Anderson <rodger@boi.hp.com>

# Someone asked for a version of NNTPClient that had some sort of
# progress indicator.  Here is one example that does it.  It is a
# "sub-class" of the News::NNTPClient module and replaces one function
# and creates a new version of a second function.  To use this code,
# just replace the "use News::NNTPClient" expression in your code with
# "use News::NNTPFetchProgress", and copy this file to the News
# directory in your perl library.

# If you want a progress indicator for all fetches, delete the "article"
# sub-routine and change the name of the "progressfetch" routine to just
# "fetch".

package News::NNTPFetchProgress;

require 5.000;

use Carp;
use News::NNTPClient;

@ISA = qw(News::NNTPClient);

$VERSION = $VERSION = 0.1;

# Fetch an article.
sub article {
    my $me = shift;
    my $msgid = shift || "";

    $me->{CMND} = "progressfetch";
    $me->command("ARTICLE $msgid");
}

# Fetch text from server until single dot.
sub progressfetch {
    my $me = shift;
    local $/ = "\012";         # Only use LF to account for possible missing CR
    local $\ = "";             # Guarantee that no other EOL is in use
    local $_;

    return unless $me->okprint;

    my @lines;
    my $line = 0;

    my $SOCK = $me->{SOCK};

    # Loop reading lines until we receive a line with a single period.
    while (<$SOCK>) {
	s/\015?\012$/$me->{EOL}/; # Change termination

	last if $_ eq ".$me->{EOL}";

	s/^\.\././;		# Fix up escaped dots.

######################################################################
# Print progress indication
######################################################################
	print "Fetching line ", ++$line, "\r";

	push @lines, $_;	# Save each line.
    }

    1 < $me->{DBUG} and	warn "$SOCK received ${\scalar @lines} lines\n";

    wantarray ? @lines : \@lines;
}

1;

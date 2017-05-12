# makepm.PL -- Builds PGP/Sign.pm from PGP/Sign.in.  -*- perl -*-
# $Id: makepm.PL 172 2007-04-23 04:46:02Z eagle $
#
# The main reason why we have this script is to figure out where PGP is on
# the system and code that and the PGP style to use into PGP::Sign before we
# install the module.  While we're at it, we also pull in our version number
# from a separate file to give us some flexibility in release numbering.

# Unbuffer output, since we'll be prompting.
$| = 1;

# First, grab the line to set the version number, since we'll need to
# substitute that in to PGP/Sign.pm when we build it.  It's the second line
# of VERSION.pm.
open (VERSION, 'VERSION.pm') or die "Cannot open VERSION.pm: $!\n";
<VERSION>;
my $version = <VERSION>;
close VERSION;

# Search for PGP, prefering GPG, then PGP v6.5 or v2.6, then PGP v5.0.  We
# start by searching the user's PATH, and then check a few other standard
# directories.  We just look for the program used for signing, assuming the
# program used for verification will be found in the same place.
sub find_pgp {
    my @directories = map { s/^$/./; $_ } split (':', $ENV{PATH});
    push (@directories, qw(/usr/local/bin /usr/bin /opt/bin));
    my @programs = qw(gpg pgp pgp65 pgp6 pgps pgp2 pgp26 pgp263 pgp262);
    my $directory;
    for $directory (@directories) {
        next unless -d $directory;
        for (@programs) {
            my $program = "$directory/$_";
            next unless -x $program;
            return $program;
        }
    }
}

# Used for heredocs to make them more readable.
sub unquote { my ($string) = @_; $string =~ s/^: {0,7}//gm; $string }

# We need to know PGPS (program used for signing), PGPV (program used for
# verifying), and PGPSTYLE.  First, check to see if a file named "paths"
# exists; if so, this was given to Makefile.PL and we should just use those
# values.  Otherwise, we'll have to find it out for ourselves.
if (-r './paths') { require './paths' }
unless ($PGPV && $PGPS && $PGPSTYLE) {
    $PGPS = find_pgp;
    print unquote (<<'EOM');
:
:       PGP::Sign needs to know the path to PGP; this path will be encoded
:       in the installed module as the default path to PGP (it can be
:       overridden at runtime).  Please enter the full path to the PGP
:       program you want to use to sign messages (if you are using version
:       5.0 or 6.5, this should be the path to pgps) or just press Enter if
:       the guess is correct.
:
EOM
    $PGPS ||= '/usr/local/bin/pgp';
    print "Program to sign data [$PGPS]: ";
    my $input = <STDIN>;
    chomp $input;
    $PGPS = $input || $PGPS;
    if ($PGPS =~ m%pgps[^/]*$%) {
        ($PGPV = $PGPS) =~ s%pgps([^/]*)$%pgpv$1%;
    } else {
        $PGPV = $PGPS;
    }
    print "Program to verify signatures [$PGPV]: ";
    $input = <STDIN>;
    chomp $input;
    $PGPV = $input || $PGPV;
    print unquote (<<'EOM');
:
:       PGP::Sign also needs to know what implementation of PGP you are
:       using.  Acceptable values are "PGP2" for PGP 2.6 and workalikes
:       (this may also work for ViaCrypt PGP 4.0), "PGP5" for PGP 5.0 and
:       workalikes, "PGP6" for PGP 6.0 and workalikes, or "GPG" for GnuPG.
:       Please enter one of those possible values or just press Enter if
:       the guess is correct.
:
EOM
    {
        if    ($PGPS =~ m%pgps[^/]*$%) { $PGPSTYLE = 'PGP5' }
        elsif ($PGPS =~ m%gpg[^/]*$%)  { $PGPSTYLE = 'GPG'  }
        else {
            my $version = `$PGPS 2>&1`;
            if ($version =~ /Pretty Good Privacy.* 6\./) {
                $PGPSTYLE = 'PGP6';
            } else {
                $PGPSTYLE = 'PGP2';
            }
        }
        print "PGP style [$PGPSTYLE]: ";
        my $input = <STDIN>;
        chomp $input;
        $PGPSTYLE = uc ($input || $PGPSTYLE);
        unless ({PGP5 => 1, PGP6 => 1, GPG => 1, PGP2 => 1}->{$PGPSTYLE}) {
            print "\nUnknown PGP style '$PGPSTYLE'\n\n";
            redo;
        }
    }
    print "\n";
}

# Paranoia.
for ($PGPS, $PGPV, $PGPSTYLE) { s/\\/\\\\/g; s/\'/\\\'/g }

# Now, open our input file and create our output file, and then do the
# necessary substitutions.
open (IN, 'Sign.in') or die "Cannot open Sign.in: $!\n";
open (OUT, '> Sign.pm') or die "Cannot open Sign.pm: $!\n";
while (<IN>) {
    if (/^\# @@ VERSION$/)     { print OUT $version }
    elsif (/^\# @@ PGPS$/)     { print OUT "\$PGPS = '$PGPS';\n" }
    elsif (/^\# @@ PGPV$/)     { print OUT "\$PGPV = '$PGPV';\n" }
    elsif (/^\# @@ PGPSTYLE$/) { print OUT "\$PGPSTYLE = '$PGPSTYLE';\n" }
    else                       { print OUT }
}
close OUT;
close IN;

# This -*- perl -*- script writes the Makefile for News-Scan

require 5.004;

$| = 1;

################################################################
# check for non-standard required libraries
################################################################
sub require_version {
    my $pkg  = shift;
    my $want = shift;
    my $vers = ${"${pkg}::VERSION"} || "(undef)";

    if ($vers < $want) {
        die "$pkg v$want required -- you have v$vers\n";
    }
}

my $missing = 0;

print "Checking for Date::Parse........";
eval {
    require Date::Parse;
    require_version('Date::Parse', 2.06);
};
if ($@) {
    print " failed\n";
    $missing++;
    print <<EOF;
$@
The NewsScan distribution uses Date::Parse to determine when a given
article was posted.  Date::Parse is part of Graham Barr's TimeDate
distribution.

EOF
    sleep 2;
}
else {
    print " ok\n";
}

print "Checking for Mail::Address......";
eval {
    require Mail::Address;
    require_version('Mail::Address', 1.09);
};
if ($@) {
    print " failed\n";
    $missing++;
    print <<EOF;
$@
The NewsScan distribution uses Mail::Address to parse email addresses
from various fields in the header of an article.  Mail::Address is
part of Graham Barr's MailTools distribution.

EOF
    sleep 2;
}
else {
    print " ok\n";
}

print "Checking for Net::NNTP..........";
eval {
    require Net::NNTP;
    require_version('Net::NNTP', 0.26);
};
if ($@) {
    print " failed\n";
    # not missing because this isn't totally necessary
    print <<EOF;
$@
The NewsScan distribution uses Net::NNTP as a way of gathering
news articles from your news server.  If you don't need to collect
articles for yourself (if you're using a news server and want to
scan the spool directory) or if you have some other means of collecting
articles, then you can safely ignore this message. :-)

EOF
    sleep 2;
}
else {
    print " ok\n";
}

if ($missing != 0) {
    print <<EOF;
The missing modules can be obtained from CPAN (Comprehensive Perl Archive
Network).  Visit <http://www.perl.com/CPAN/> to find a CPAN site
near you.
EOF
    exit;
}

################################################################
# begin Makefile generation stuff
################################################################
use ExtUtils::MakeMaker;

$VERSION = '0.53';

sub MY::libscan {
    my($self, $path) = @_;

    return '' if $path =~ m!/RCS/!;

    $path;
}

WriteMakefile(
    VERSION   => $VERSION,
    DISTNAME  => 'News-Scan',
    NAME      => 'News-Scan',
    PMLIBDIRS => [ qw( News ) ],
    'dist'    => {
                  COMPRESS     => 'gzip -9',
                  SUFFIX       => 'gz',
                  DIST_DEFAULT => 'all tardist',
                 },
);

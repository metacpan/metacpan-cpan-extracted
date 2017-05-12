package PPMServer;

# point this to your repository
my $repository = '/home/http/repository';

#
# You shouldn't need to change anything below this point.
#

use XML::Parser;
use PPM::XML::RepositorySummary;
use strict;

# $summaryfile is the output of utils/summary.pl 
my $summaryfile = "$repository/summary.ppm";

# $searchsummaryfile is the output of utils/searchsummary.pl 
my $searchsummaryfile = "$repository/searchsummary.ppm";
 
my ($summary, $searchsummary, $summaryastext, $searchsummaryastext,
    @ppd_data);

sub ppm_protocol {"PPM 200"}

sub search_ppds
{
    my ($self, $archname, $searchRE, $searchtag) = @_;
    $searchtag = 'TITLE' unless $searchtag;
    unless ($searchsummaryastext) {
        local $/;
        open(SUMMARY, "<$searchsummaryfile") 
            or die "Can't open $searchsummaryfile: $!";
        $searchsummaryastext = <SUMMARY>;
        close(SUMMARY);
        # trim everything up to the first <SOFTPKG>
        $searchsummaryastext =~ s/.*?<SOFTPKG/<SOFTPKG/s;
    }
    my $output = "<REPOSITORYSUMMARY>";

    my @ppd_data = split m@</SOFTPKG>@o, $searchsummaryastext
        unless @ppd_data;
    foreach my $pkg (@ppd_data) {
        if ($pkg =~ m@<${searchtag}>(.*)</${searchtag}>@s) {
            next unless $1 =~ /${searchRE}/;
            if ($pkg =~ m@<ARCHITECTURE.*${archname}.*?/>@s) {
                $output .= $pkg . "</SOFTPKG>";
            }
        }
    }

    $output .= "</REPOSITORYSUMMARY>";
    return $output;
}

sub fetch_summary
{
    unless ($summaryastext) {
        local $/;
        open(SUMMARY, "<$summaryfile") 
            or die "Can't open $summaryfile: $!";
        $summaryastext = <SUMMARY>;
        close(SUMMARY);
    }
    return $summaryastext;
}

sub packages
{
    my @results;
    $summary = _load_summary($summaryfile) unless $summary;

    foreach my $pkg (@{$summary->{'Kids'}}) {
        push @results, $pkg->{'NAME'} if (exists $pkg->{'NAME'});
    }
    return (undef, @results);
}

sub fetch_ppd
{
    my ($self, $package) = @_; 
    if (-f "$repository/$package.ppd") {
        local $/;
        open(PPD, "<$repository/$package.ppd") 
            or die "Can't open $repository/$package.ppd: $!";
        my $ppd = <PPD>;
        close(PPD);
        return $ppd;
    }
    $summary = _load_summary($summaryfile) unless $summary;
    foreach my $pkg (@{$summary->{'Kids'}}) {
        if (exists $pkg->{'NAME'}) {
            return $pkg->as_text() if ($pkg->{'NAME'} =~ /^$package$/i);
        }
    }
    return undef;
}

sub _load_summary 
{
    my $file = shift;
    my $parser = new XML::Parser( 'Style' => 'Objects',
        'Pkg'   => 'XML::RepositorySummary' );
    my $rc = $parser->parsefile( $file );
    return $rc->[0];
}

1;

#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use Parse::SAMGov;
use Getopt::Long;
$| = 1;

sub usage {
    my $app = shift;
    return <<EOF
Usage: $app --help | --file=<filename> | --smallbiz | --largebiz

--help                    This help message
--file=<filename>         The input filename from www.sam.gov
--smallbiz                Only dump the small businesses. Default dumps all.
--largebiz                Only dump the large businesses. Default dumps all.
EOF
}

my ($help, $filename, $smallbiz, $largebiz);
GetOptions("file=s" => \$filename, "help" => \$help,
    "smallbiz" => \$smallbiz, "largebiz" => \$largebiz,
) or die usage($0);
die usage($0) if $help or not $filename;

my $parser = Parse::SAMGov->new;

### we want to filter NAICS 541511, 541512, 541519, 541712
### which are NAICS codes for software development
my $entities = $parser->parse_file($filename, sub {
        # want smallbiz only but isn't smallbiz
        return undef if (!$largebiz && $smallbiz && !$_[0]->is_smallbiz);
        # want largebiz only but isn't largebiz
        return undef if (!$smallbiz && $largebiz && $_[0]->is_smallbiz);
        # want anything that matches criteria
        if ($_[0]->NAICS->{541511} ||
            $_[0]->NAICS->{541512} ||
            $_[0]->NAICS->{541519} ||
            $_[0]->NAICS->{541712}) {
            my $e = $_[0];
            my $company = $e->name;
            $company .= ' dba ' . $e->dba_name if length $e->dba_name;
            my %filtered = ();
            $filtered{$e->POC_elec->email} = { name => $e->POC_elec->name,
                company => $company} if $e->POC_elec->email;
            $filtered{$e->POC_elec_alt->email} = { name => $e->POC_elec_alt->name,
                company => $company} if $e->POC_elec_alt->email;
            $filtered{$e->POC_gov->email} = { name => $e->POC_gov->name,
                company => $company } if $e->POC_gov->email;
            $filtered{$e->POC_gov_alt->email} = { name => $e->POC_gov_alt->name,
                company => $company} if $e->POC_gov_alt->email;
            foreach my $em (keys %filtered) {
                say join(',', $em, $filtered{$em}->{name},
                    $filtered{$em}->{company});
            }
        }
        return undef;
    });

__END__
### COPYRIGHT: Selective Intellect LLC.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>

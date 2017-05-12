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
Usage: $app --help | --file=<filename>
EOF
}

my ($help, $filename);
GetOptions("file=s" => \$filename, "help" => \$help) or die usage($0);
die usage($0) if $help or not $filename;

my $parser = Parse::SAMGov->new;

### we want to filter NAICS 541511, 541512, 541519, 541712
### which are NAICS codes for software development
my $entities = $parser->parse_file($filename, sub {
        return 1 if $_[0]->NAICS->{541511};
        return 1 if $_[0]->NAICS->{541512};
        return 1 if $_[0]->NAICS->{541519};
        return 1 if $_[0]->NAICS->{541712};
        return undef;
    });

die "No entities found" unless scalar @$entities;

my %filtered = ();
foreach my $e (@$entities) {
    my $company = $e->name;
    $company .= ' dba ' . $e->dba_name if length $e->dba_name;
    my $naics = join('|', keys %{$e->NAICS});
    $filtered{$e->POC_elec->email} = { name => $e->POC_elec->name,
        company => $company, NAICS => $naics } if $e->POC_elec->email;
    $filtered{$e->POC_elec_alt->email} = { name => $e->POC_elec_alt->name,
        company => $company, NAICS => $naics } if $e->POC_elec_alt->email;
    $filtered{$e->POC_gov->email} = { name => $e->POC_gov->name,
        company => $company, NAICS => $naics } if $e->POC_gov->email;
    $filtered{$e->POC_gov_alt->email} = { name => $e->POC_gov_alt->name,
        company => $company, NAICS => $naics } if $e->POC_gov_alt->email;
}
foreach my $em (keys %filtered) {
    say join(',', $em, $filtered{$em}->{name}, $filtered{$em}->{company},
        $filtered{$em}->{NAICS});
}


__END__
### COPYRIGHT: Selective Intellect LLC.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>

#!/usr/bin/perl

use strict;
use warnings;
use CPANDB;
use YAML::LoadURI;
use Data::Dumper;

# set feature dists
my @feature_dists = qw/
    Padre-Plugin-Parrot
    Padre-Plugin-Perl6
    Padre-Plugin-PSI
    Padre-Plugin-SpellCheck
    Padre-Plugin-SVN
    Padre-Plugin-SVK
    Padre-Plugin-Git
    Padre-Plugin-Catalyst
    Padre-Plugin-Mojolicious
    Padre-Plugin-REPL
/; # REPL, FAIL on Win32
my @requires_dists;

my $padre_dist = CPANDB::Distribution->select(
    'where distribution=?',
    'Padre'
);

# get all used_by Padre, http://cpants.perl.org/dist/used_by/Padre
my $padre_prereq = CPANDB::Requires->select(
    'where module=?',
    'Padre'
);

my %seen;
foreach my $prereq ( @$padre_prereq ) {
    my $dist_name = $prereq->distribution;
    if ( $dist_name =~ /^Padre-Plugin-/ or $dist_name =~ /^Acme-Padre-/ ) {
        # no duplication
        next if $seen{$dist_name};
        $seen{$dist_name} = 1;

        unless ( grep { $_ eq $dist_name } @feature_dists ) {
            push @requires_dists, $dist_name;
        }
    }
}

my %meta_cache;

open(my $fh, '>', 'Makefile.txt');

print $fh "requires 'Padre' => '" . $padre_dist->[0]->version . "';\n";
foreach my $dist ( sort @requires_dists ) {
    print $dist . "\n";
    my $meta = LoadURI("http://cpansearch.perl.org/dist/$dist/META.yml");
    $meta_cache{ $dist } = $meta;
    my $module = $dist; $module =~ s/\-/\:\:/g;
    print $fh "requires '$module' => '$meta->{version}';\n";
}
print $fh "\n";
foreach my $dist ( sort @feature_dists ) {
    print $dist . "\n";
    my $meta; # Padre-Plugin-Git don't have a META, BAD
    if ( $dist eq 'Padre-Plugin-Git' ) {
        $meta = {
            abstract => 'Simple Git interface for Padre',
            version  => '0.01',
        };
    } else {
        $meta = LoadURI("http://cpansearch.perl.org/dist/$dist/META.yml");
    }
    $meta_cache{ $dist } = $meta;
    my $module = $dist; $module =~ s/\-/\:\:/g;
    print $fh "feature '$meta->{abstract}',\n\t-default => 0,\n\t'$module' => '$meta->{version}';\n";
    
}
close($fh);

open(my $fh2, '>', 'Plugins.txt');
foreach my $dist ( sort (@requires_dists, @feature_dists) ) {
    my $meta = $meta_cache{ $dist };
    my $module = $dist; $module =~ s/\-/\:\:/g;
    print $fh2 "=head2 L<$module>\n\n$meta->{abstract}\n\nSee L<$module>\n\n";
}
close($fh2);

1;
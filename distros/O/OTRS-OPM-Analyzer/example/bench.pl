#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use File::Find::Rule;
use Time::HiRes qw(time);

use lib qw(/home/opar/OTRS-OPM-Analyzer/lib/);
use OTRS::OPM::Analyzer;
use OTRS::OPM::Parser;

my $dir  = '/home/opar/community/analyzer_test/uploads';
my @opms = File::Find::Rule->file->name( '*.opm' )->in( $dir );

my %info = ( min_file => { length => 10_000, name => '' }, max_file => { length => 0, name => '' }, time => 0 );

my $analyzer = OTRS::OPM::Analyzer->new;
$analyzer->_load_roles;

warn scalar @opms;
my %roles = $analyzer->roles;

FILE:
for my $file ( @opms ) {
    warn $file,"\n";
    my $opm = OTRS::OPM::Parser->new( opm_file => $file );
    eval { $opm->parse; 1; } or next FILE;

    my @files_inc = $opm->files;
    my $nr        = scalar @files_inc;

    next if !@files_inc;

    my $start = time;

    my %analysis_data;
    for my $inc_file ( @files_inc ) {

        ROLE:
        for my $role ( @{ $roles{file} || [] } ) {
            my ($sub) = $analyzer->can( 'check_' . lc $role );
            next ROLE if !$sub;

            my $result   = $analyzer->$sub( $inc_file );
            my $filename = $inc_file->{filename};

            $analysis_data{$role}->{$filename} = $result;
        }
    }

    my $runtime  = ( time - $start );
    $info{time} += $runtime;

    if ( $nr > $info{max_file}->{length} ) {
        $info{max_file}->{length} = $nr;
        $info{max_file}->{name}   = $file;
        $info{max_file}->{time}   = $runtime;
    }

    if ( $nr < $info{min_file}->{length} ) {
        $info{min_file}->{length} = $nr;
        $info{min_file}->{name}   = $file;
        $info{min_file}->{time}   = $runtime;
    }
}

print Dumper \%info;

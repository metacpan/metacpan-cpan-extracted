#!/usr/bin/env perl

use FindBin qw/ $Bin /;
use File::Basename;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use lib (
    dirname( $Bin ) . '/lib',
);

use Schedule::Pluggable;
{
    my $p = Schedule::Pluggable->new(JobsPlugin => 'JobsFromData');
    my ($status, $details) = $p->run_in_series([ { name => 'Job1', command => "$Bin/succeed.pl 5" },
                                                 { name => 'Job2', command => "$Bin/succeed.pl 8" },
                                               ]);
    print $status ? Data::Dumper->Dump([$status, $details], [qw/$status $details/])
                  : "All OK\n";
}
{
    my $p = Schedule::Pluggable->new(JobsPlugin => 'JobsFromData');
    my ($status, $details) = $p->run_in_parallel([ { name => 'Job1', command => "$Bin/succeed.pl 7" },
                                                   { name => 'Job2', command => "$Bin/succeed.pl 10" },
                                                 ]);
    print $status ? Data::Dumper->Dump([$status, $details], [qw/$status $details/])
                  : "All OK\n";
}
{
    my $p = Schedule::Pluggable->new(JobsPlugin => 'JobsFromData');
    my ($status, $details) = $p->run_schedule({Jobs => { Job1 => { name => 'Job1', command => "$Bin/succeed.pl 2" },
                                                         Job2 => { name => 'Job2', command => "$Bin/succeed.pl 5" },
                                                        },
                                              },
                                            );
    print $status ? Data::Dumper->Dump([$status, $details], [qw/$status $details/])
                  : "All OK\n";
}
{
    my $p = Schedule::Pluggable->new(JobsPlugin => 'JobsFromData');
    my ($status, $details) = $p->run_schedule({Jobs => [ { name => 'Job1', command => "$Bin/succeed.pl" },
                                                         { name => 'Job2', command => "$Bin/succeed.pl" },
                                                        ]
                                              });
    print $status ? Data::Dumper->Dump([$status, $details], [qw/$status $details/])
                  : "All OK\n";
}
no Schedule::Pluggable;
use Schedule::Pluggable (JobsPlugin => 'JobsFromXML');
{ 
    my $p = Schedule::Pluggable->new(JobsPlugin => 'JobsFromXML');
    my ($status, $details) = $p->run_schedule({Jobs => "$Bin/test.xml"});
    print $status ? Data::Dumper->Dump([$status, $details], [qw/$status $details/])
                  : "All OK\n";
}
no Schedule::Pluggable;
use Schedule::Pluggable;

{ 
    my $p = Schedule::Pluggable->new(JobsPlugin => 'JobsFromXML');
    my ($status, $details) = $p->run_schedule({Jobs => "$Bin/test.xml"});
    print $status ? Data::Dumper->Dump([$status, $details], [qw/$status $details/])
                  : "All OK\n";
}


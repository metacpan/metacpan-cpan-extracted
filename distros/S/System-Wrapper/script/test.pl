#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Data::Dumper;
use System::Wrapper;
use System::Wrapper::Parallel;

my $pv = System::Wrapper->new(
    executable => 'pv',
    arguments  => [ '-c -N cat' ],
    input      => ['/home/psilva/.emacs'],
); 

my $tpb = System::Wrapper->new(
    interpreter => 'perl',
    executable  => 'tpb.pl',
    input       => ['/home/psilva/.emacs'],
);

my $cat = System::Wrapper->new(
    interpreter => 'perl',
    arguments   => [ -pe => q{''} ], 
    input       => ['/home/psilva/.emacs'], 
    description => 'Concatenate .emacs to STDOUT',
);

my $reverse = System::Wrapper->new(
    interpreter => 'perl',
    arguments   => [ -pe => q{'$_ = reverse $_'} ],
    description => 'Reverse input',
);

my $complement = System::Wrapper->new(
    interpreter => 'perl',
    arguments   => [ -pe => q{'tr/ACGT/TGCA/'} ],
    description => 'Complement input',
    output      => { '>' => 'complement' },
);

my $pipeline = System::Wrapper::Parallel->new( 
    commands => [$tpb, $cat, $reverse, $complement],
    pipeline => 1
);

die "failed to run at least one command"
    if grep {$_} $pipeline->run;

__END__

package Scalar::Perl;
use strict;
use warnings;
use utf8;
use 5.008_001;
use parent qw(Exporter);
use PLON ();

our @EXPORT = qw($_perl);

our $_perl = \&_perl;

sub _perl { PLON->new->encode(shift) }

1;


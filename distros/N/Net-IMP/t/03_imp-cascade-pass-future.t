#!/usr/bin/perl
# Test of Net::IMP::Cascade behavior of propagating pass into future

use strict;
use warnings;
use Net::IMP;
use Net::IMP::Cascade;
use Net::IMP::Debug;
use Data::Dumper;
use Test::More tests => 1;

$Data::Dumper::Sortkeys = 1;
$DEBUG=0; # enable for extensiv debugging

my $analyzer = Net::IMP::Cascade->new_factory( parts => [
    RemoveHead->new_factory( size => 10 ),
    RemoveHead->new_factory( size => 5 ),
])->new_analyzer;

my @rv;
$analyzer->set_callback( sub { debug(Dumper(\@_)); push @rv,@_; });
$analyzer->data(0,'123');
$analyzer->data(0,'456');
$analyzer->data(0,'789');
$analyzer->data(0,'0AB');
$analyzer->data(0,'CDE');
$analyzer->data(0,'FGH');
$analyzer->data(0,'');

my @expect = (
    [ 'replace', 0, 10, '' ],
    [ 'replace', 0, 15, '' ],
    [ 'pass', 0, IMP_MAXOFFSET ],
);

if ( Dumper(\@expect) ne Dumper(\@rv)) {
    fail("cascade: pass future");
    diag("expected ".Dumper(\@expect).
	"\ngot ".Dumper(\@rv));
} else {
    pass("cascade: pass future");
}


package RemoveHead;
use base 'Net::IMP::Base';
use fields qw(size pos);
use Net::IMP;

sub new_analyzer {
    my ($factory,%args) = @_;
    my $size = $factory->{factory_args}{size};
    my $self = $factory->SUPER::new_analyzer(%args);
    $self->{size} = $size;
    $self->{pos} = 0;
    return $self;
}

sub data {
    my ($self,$dir,$data,$offset) = @_;
    my $pos = $self->{pos};
    if ( $offset ) {
	die "overlapping $offset<$pos" if $offset<$pos;
	die "gaps not supported" if $offset>$pos and $pos<$self->{size};
	$self->{pos} = $offset;
	$self->run_callback([ IMP_PASS, $dir, IMP_MAXOFFSET ]);
    } elsif ( $pos >= $self->{size} ) {
	$self->{pos} += length($data);
	$self->run_callback([ IMP_PASS, $dir, IMP_MAXOFFSET ]);
    } else {
	$pos = ( $self->{pos} += length($data));
	my $over = $pos - $self->{size};
	if ( $over>=0 ) {
	    $self->run_callback(
		[ IMP_REPLACE, $dir, $self->{size},'' ],
		[ IMP_PASS, $dir, IMP_MAXOFFSET ],
	    );
	} elsif ( $data eq '' ) { # eof before reaching size
	    $self->run_callback(
		[ IMP_REPLACE, $dir, $pos,'' ],
	    );
	} else {
	    # keep until eof or size reached
	}
    }
}

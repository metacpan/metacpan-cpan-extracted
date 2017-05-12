#!/usr/bin/perl
# Test of Net::IMP::Cascade combined with Net::IMP::Pattern
# check behavior for bidirectional data

use strict;
use warnings;
use Net::IMP;
use Net::IMP::Cascade;
use Net::IMP::Pattern;
use Net::IMP::Debug;
use Data::Dumper;

use Test::More tests => 1;

$Data::Dumper::Sortkeys = 1;
$DEBUG=0; # enable for extensiv debugging

my $analyzer = Net::IMP::Cascade->new_factory( parts => [
    Net::IMP::Pattern->new_factory(
	rx => qr/abcd/,
	rxlen => 4,
	action => 'replace',
	actdata => 'ABCD'
    ),
    Net::IMP::Pattern->new_factory(
	rx => qr/CDEF/,
	rxlen => 4,
	action => 'replace',
	actdata => 'cdef'
    ),
    PrePass->new_factory( window => IMP_MAXOFFSET ),
])->new_analyzer;

my @rv;
$analyzer->set_callback( sub { debug(Dumper(\@_)); push @rv,@_; });
$analyzer->data(0,'abcdEF abCDEF');
$analyzer->data(1,'abcdEF abCDEF');
$analyzer->data(1,'');
$analyzer->data(0,'');

my @expect = (
    [ 'replace', 0, 4, 'A' ],
    [ 'replace', 0, 6, 'Bcdef' ],
    [ 'prepass', 0, 7 ],
    [ 'replace', 1, 4, 'ABCD' ],
    [ 'prepass', 1, 6 ],
    [ 'prepass', 1, 7 ],
    [ 'replace', 1, 9, 'ABCD' ],
    [ 'replace', 1, 13, '' ],
    [ 'replace', 1, 13, 'ef' ],
    [ 'pass',    1, -1 ],
    [ 'prepass', 0, 9 ],
    [ 'replace', 0, 10, 'cdef' ],
    [ 'replace', 0, 13, '' ],
    [ 'pass',    0, -1 ],
);

if ( Dumper(\@expect) ne Dumper(\@rv)) {
    fail("cascade-bidi");
    diag("expected ".Dumper(\@expect)."\ngot ".Dumper(\@rv));
} else {
    pass("cascade-bidi");
}


package PrePass;
use base 'Net::IMP::Base';
use fields qw(window pos);
use Net::IMP;

sub new_analyzer {
    my ($factory,%args) = @_;
    my $window = $factory->{factory_args}{window};
    my $self = $factory->SUPER::new_analyzer(%args);
    $self->{window} = $window;
    $self->{pos} = 0;
    return $self;
}

sub data {
    my ($self,$dir,$data,$offset) = @_;
    my $pos = $self->{pos};
    if ( $offset ) {
	die "overlapping $offset<$pos" if $offset<$pos;
	die "gaps not supported" if $offset>$pos;
    }

    $self->{pos} += length($data);
    my $off = ($self->{window} == IMP_MAXOFFSET)
	? IMP_MAXOFFSET
	: $self->{pos} + $self->{window};
    $self->run_callback([ IMP_PREPASS, $dir, $off ]);
}

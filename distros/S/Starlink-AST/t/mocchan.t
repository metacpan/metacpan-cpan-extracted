#!perl

use strict;
use Test::More tests => 7;

require_ok('Starlink::AST');

do {
    my $moc = new Starlink::AST::Moc('MaxOrder=5');
    $moc->AddCell(Starlink::AST::Region::AST__OR(), 5, 10);
    isa_ok($moc, 'Starlink::AST::Moc');

    my @data = ();

    my $ch = new Starlink::AST::MocChan(sink => sub {push @data, $_[0];});
    isa_ok($ch, 'Starlink::AST::MocChan');

    $ch->Write($moc);
    is_deeply(\@data, ['5/10']);

    my @sourcedata = ('5/11');

    my $ch = new Starlink::AST::MocChan(source => sub {return shift @sourcedata;});
    isa_ok($ch, 'Starlink::AST::MocChan');

    my $moc2 = $ch->Read();
    isa_ok($moc2, 'Starlink::AST::Moc');

    is($moc2->GetMocString(1), '{"5":[11]}');
};

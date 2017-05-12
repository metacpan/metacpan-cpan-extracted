use strict; use warnings;
use Data::Dumper;

use Test::More;
use Test::Perl::Tags;

use Perl::Tags;
use Perl::Tags::Naive::Moose;

use FindBin qw($Bin);
use lib "$FindBin::Bin";

my $naive_tagger = Perl::Tags::Naive::Moose->new( max_level=>2 );
ok (defined $naive_tagger, 'created Perl::Tags' );
isa_ok ($naive_tagger, 'Perl::Tags::Naive::Moose' );
isa_ok ($naive_tagger, 'Perl::Tags' );

my $result = 
    $naive_tagger->process(
        files => [ "$Bin/Moosy/Class.pm" ],
        refresh=> 1
    );
ok ($result, 'processed successfully' ) or diag "RESULT $result";

tag_ok $naive_tagger, 
    'Moosy::Class' => "$Bin/Moosy/Class.pm" => 'package Moosy::Class;', 
    'package line';
tag_ok $naive_tagger, 
    'Moosy::Parent' => "$Bin/Moosy/Parent.pm" => 'package Moosy::Parent;', 
    'extends line recursively finds parent';
tag_ok $naive_tagger, 
    'Moosy::Role1' => "$Bin/Moosy/Role1.pm" => 'package Moosy::Role1;', 
    'with line with single role finds role';
tag_ok $naive_tagger, 
    'Moosy::Role2' => "$Bin/Moosy/Role2.pm" => 'package Moosy::Role2;', 
    'with line with multiple roles finds role';
tag_ok $naive_tagger, 
    'Moosy::Role3' => "$Bin/Moosy/Role3.pm" => 'package Moosy::Role3;', 
    'with line with multiple roles finds role';

done_testing;

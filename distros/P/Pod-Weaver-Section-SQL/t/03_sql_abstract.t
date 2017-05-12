# \author: Armand Leclercq
# \file: 03_sql_abstract.t
# \date: Thu 22 Jan 2015 09:37:24 AM CET

use strict;
use warnings;

use Test::More;
use Test::Differences;

use PPI;

use Pod::Weaver;

my @tests = qw/select insert update delete/;

my $perl_doc = do { local $/; <DATA>; };

for my $test (@tests) {
    my $in_pod = do {
        local $/;
        open my $fh, '<:raw:bytes', "t/files/sql/abstract/$test.in.pod";
        <$fh>;
    };
    my $ex_pod = do {
        local $/;
        open my $fh, '<:encoding(UTF-8)', "t/files/sql/abstract/$test.ou.pod";
        <$fh>;
    };
    my $document  = Pod::Elemental->read_string($in_pod);    # Wants octets
    my $ppi_doc   = PPI::Document->new( \$perl_doc );
    my $assembler = Pod::Weaver::Config::Assembler->new;

    my $root = $assembler->section_class->new( { name => '_' } );
    $assembler->sequence->add_section($root);
    $assembler->change_section('@Default');
    $assembler->end_section;

    # Add [SQL] to my in-RAM configuration file
    $assembler->change_section('SQL');
    $assembler->end_section;

    my $weaver = Pod::Weaver->new_from_config_sequence( $assembler->sequence );
    require Software::License::Artistic_1_0;
    my $woven = $weaver->weave_document(
        {
            pod_document => $document,
            ppi_document => $ppi_doc,

            version => '0.01',
            authors => ['Armand Leclercq <armand.leclercq@gmail.com>'],
            license => Software::License::Artistic_1_0->new(
                {
                    holder => 'Armand Leclercq',
                    year   => 2014,
                }
            ),
        }
    );

    eq_or_diff $woven->as_pod_string, $ex_pod,
      "We got exactly the expected pod for "
      . "t/files/sql/abstract/$test.in.pod";
}

done_testing;

__DATA__

package Module::Name;
# ABSTRACT: abstract text

my $this = 'a test';

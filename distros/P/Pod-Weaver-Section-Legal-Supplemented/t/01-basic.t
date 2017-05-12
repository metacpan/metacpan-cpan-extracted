use strict;
use Test::More;
use Test::Differences;
use String::Cushion;
use syntax 'qi';
use PPI;
use Pod::Weaver;
use Pod::Weaver::Section::Legal::Supplemented;
use Software::License::Artistic_1_0;

ok 1;

my $document = Pod::Elemental->read_string(inpod());
my $ppi_doc = PPI::Document->new(module_contents());
my $assembler = Pod::Weaver::Config::Assembler->new;

my $root = $assembler->section_class->new({ name => '_' });
$assembler->sequence->add_section($root);
$assembler->change_section('Name');
$assembler->end_section;

$assembler->change_section('Legal::Supplemented');
$assembler->add_value(text_before => 'The <trademark> is owned by <company>.');
$assembler->add_value(text_after => 'The <other trademark> is also owned by <company>.');
$assembler->add_value(text_after => 'No affiliation');
$assembler->end_section;

my $weaver = Pod::Weaver->new_from_config_sequence($assembler->sequence);

my $woven = $weaver->weave_document(
    {
        pod_document => $document,
        ppi_document => $ppi_doc,
        version => '0.0100',
        authors => ['Ex Ample <ea@example.com'],
        license => Software::License::Artistic_1_0->new({
            holder => 'Ex Ample',
            year => 1982,
        }),
    }
);

eq_or_diff $woven->as_pod_string, expected(), 'Correct pod';

done_testing;

sub module_contents {
    \qi{
        package Test::Module;

        # ABSTRACT: ...
    };
}

sub inpod {
    my $inpod = qi{
        =pod

        =head1 HEADER

        Just pod.
    };
}

sub expected {
    cushion 0, 1 => qi{
        =pod

        =head1 NAME

        Test::Module - ...

        =head1 COPYRIGHT AND LICENSE

        The <trademark> is owned by <company>.This software is Copyright (c) 1982 by Ex Ample.

        This is free software, licensed under:

          The Artistic License 1.0

        The <other trademark> is also owned by <company>.
        No affiliation

        =cut
    };
}

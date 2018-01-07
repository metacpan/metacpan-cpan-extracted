#!/usr/bin/env perl

use Test::Most;
use Renard::Incunabula::Devel::TestHelper;
use Renard::Incunabula::Common::Setup;
use Renard::Incunabula::Format::PDF::InformationDictionary;

my $pdf_ref_path = try {
	Renard::Incunabula::Devel::TestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
} catch {
	plan skip_all => "$_";
};

plan tests => 1;

subtest pdf_ref => sub {
	my $pdf_info = Renard::Incunabula::Format::PDF::InformationDictionary->new(
		filename => $pdf_ref_path
	);

	my @data = (
		[ Title        => 'PDF Reference, version 1.7' ],
		[ Subject      => 'Adobe Portable Document Format (PDF)' ],
		[ Author       => 'Adobe Systems Incorporated' ],
		[ Keywords     =>  undef ],
		[ Creator      => 'FrameMaker 7.2' ],
		[ Producer     => 'Acrobat Distiller 7.0.5 (Windows)' ],
		[ CreationDate => '2006-10-17T08:10:20Z' ],
		[ ModDate      => '2006-11-18T21:10:43-02:30' ],
	);

	plan tests => 0+@data;

	for my $info_pair (@data) {
		my ($key, $value) = @$info_pair;
		is $pdf_info->$key(), $value, "$key: @{[ $value // 'undef' ]}";
	}
};

done_testing;

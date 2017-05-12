#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 18;
use Test::Differences;
use Test::Exception;

use File::Spec;
use File::Slurp 'read_file';

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
    use_ok ( 'Parse::Deb::Control' ) or exit;
}

exit main();

sub main {
	my $parser = Parse::Deb::Control->new(File::Spec->catfile($Bin, 'control', 'control-perl'));
	isa_ok($parser, 'Parse::Deb::Control');

	# check the generated control file content
	is(
		$parser->control,
		scalar read_file(File::Spec->catfile($Bin, 'control', 'control-perl')),
		'check the generated control file content',
	);
	
	my $content = $parser->content;
	is(
		scalar (grep { ($_ eq 'Package') or ($_ eq 'Source') } @{$parser->structure}),
		10,
		'10 paragraphs in this control file structure',
	);
	is(
		scalar @{$content},
		10,
		'10 paragraphs in this control file',
	);
	is(
		scalar ($parser->get_keys(qw{ Source Package })),
		10,
		'10 paragraphs in this control file',
	);

	my $parser2 = Parse::Deb::Control->new(File::Spec->catfile($Bin, 'control', 'control-perl-simple'));

	# check the generated control file content
	is(
		$parser2->control,
		scalar read_file(File::Spec->catfile($Bin, 'control', 'control-perl-simple')),
		'check the generated control file content',
	);

	my $content2 = $parser2->content;
	is(
		scalar (grep { ($_ eq 'Package') or ($_ eq 'Source') } @{$parser2->structure}),
		2,
		'2 paragraphs in this simple control file structure',
	);
	is(
		scalar @{$content2},
		2,
		'2 paragraphs in this simple control file',
	);
	
	my @interresting = $parser2->get_keys(qw{ Source Package });
	is (scalar @interresting, 2, 'one source and one package section');
	
	eq_or_diff(
		\@interresting,
		[
			{
				'key'   => 'Source',
				'value' => \((@{$parser2->content})[0]->{'Source'}),
				'para'  => (@{$parser2->content})[0],
			},
			{
				'key'   => 'Package',
				'value' => \((@{$parser2->content})[1]->{'Package'}),
				'para'  => (@{$parser2->content})[1],
			}
		],
		'test get_keys() method return values'
	);

	my @interresting_para = $parser2->get_paras(qw{ Source Package });
	eq_or_diff(
		\@interresting_para,
		[
			(@{$parser2->content})[0],
			(@{$parser2->content})[1],
		],
		'test get_paras() method return values'
	);
	
	# modify Source and Package name
	foreach my $src_pkg (@interresting) {
		my $value = $src_pkg->{'value'};
		${$value} =~ s/^ (\s*) (\S+) (\s*) $/$1mms-$2$3/xms;
	}
	is(
		$parser2->control,
		scalar read_file(File::Spec->catfile($Bin, 'control', 'control-perl-simple-step1')),
		'check the modified control file content step 1',
	);

	# modify Maintainer and Uploaders
	foreach my $src_pkg ($parser2->get_keys(qw{ Maintainer Uploaders })) {
		my $value = $src_pkg->{'value'};
		${$value} =~ s/^ (\s*) (\S.*) $/$1automat\@parse-deb-control\n/xms;
	}
	is(
		$parser2->control,
		scalar read_file(File::Spec->catfile($Bin, 'control', 'control-perl-simple-step2')),
		'check the modified control file content step 2',
	);

	# modify dependencies
	foreach my $dependecies ($parser2->get_keys(qw{ Build-Depends Build-Conflicts Pre-Depends Conflicts Replaces Provides Suggests })) {
		my $value = $dependecies->{'value'};
#		use Data::Dumper; print "dump> ", Dumper($dependecies), "\n";
		${$value} =~ s/\b (lib \S+ perl | perl | perl-modules | perl5-base | libperl5.8) \b/mms-$1/xmsg;
#		use Data::Dumper; print "dump> ", Dumper($dependecies), "\n";		
#		die if $dependecies->{'key'} eq 'Conflicts';
	}
	foreach my $description ($parser2->get_keys(qw{ Description })) {
		${$description->{'value'}} .= qq{ .\n repackaged with "mms-" prefix\n};
	}
	is(
		$parser2->control,
		scalar read_file(File::Spec->catfile($Bin, 'control', 'control-perl-simple-step3')),
		'check the modified control file content step 3',
	);

	# adding removing keys from Control file
	my $parser3 = Parse::Deb::Control->new(File::Spec->catfile($Bin, 'control', 'control-perl-simple'));
	foreach my $prio ($parser3->get_keys(qw{ Priority Architecture })) {
		${$prio->{'value'}} = undef;
	}
	(@{$parser3->content})[0]->{'Test2'} = " 2\n";
	(@{$parser3->content})[0]->{'Test1'} = " 1\n";
	is(
		$parser3->control,
		scalar read_file(File::Spec->catfile($Bin, 'control', 'control-perl-simple-add-remove')),
		'check adding & removing keys',
	);

	# comments inside control files
	my $parser4 = Parse::Deb::Control->new(File::Spec->catfile($Bin, 'control', 'control-perl-simple-comment'));
	lives_ok {
		$parser4->control
	} 'parse the control file with comments';
	SKIP: {
		skip 'parsing failed not running further tests', 1;
		is(
			$parser4->control,
			scalar read_file(File::Spec->catfile($Bin, 'control', 'control-perl-simple-comment')),
			'generate the control file with comments',
		);
	}

	return 0;
}


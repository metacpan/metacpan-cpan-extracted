#!/usr/bin/perl -w
#

use Perl::Tidy;
use File::Find;
use Getopt::Long qw(:config bundling);
use FindBin qw($Bin);
use autodie qw(rename unlink);
use Fatal qw(:void open);

my $test_only;
my $perltidyrc = "$Bin/.perltidyrc";
my @dirs;
my $files_regex = qr{\.(pm|t|PL|pl)$};

GetOptions(
	"test|t" => \$test_only,
	"rc=s" => \$perltidyrc,
	"include|I=s\@" => \@dirs,
	"files|f=s" => \$files_regex,
);

if ( !@dirs ) {
	@dirs = qw(lib t);
}

my @files;
if (@ARGV) {
	@files = @ARGV;
}
else {
	find(   sub {
			if ( $_ eq "examples" ) {
				$File::Find::prune = 1;
			}
			elsif (m{$files_regex}) {
				push @files, $File::Find::name;
			}
		},
		"lib",
		"t"
	);
}

my $seen_untidy = 0;

for my $file (@files) {
	local (@ARGV);
	my $tmp = $file;
	open(FILE, $file);
	my @lines = <FILE>;
	close FILE;
	my @tmps;
	my %saved_decl;
	# workaround for perltidy not supporting Modern Perl...
	if (grep /MooseX::Method::Signatures/, @lines) {
		$tmp =~ s{(\.p[ml])?$}{.nosigs$1};
		push @tmps, $tmp;
		open TMP, ">$tmp";
		for (@lines) {
			if (m{^method (\w+)}) {
				my $sub = $1;
				$saved_decl{$sub} = $_;
				my $close = (m{\}\s*$} ? "}" : "");
				$_ = "sub $sub {$close\n";
			}
			print TMP $_;
		}
		close TMP;
	}

	my $tidy = "$file.tidy";
	push @tmps, $tidy;
	Perl::Tidy::perltidy(
		source => $tmp,
		destination => "$file.tidy",
		perltidyrc => $perltidyrc,
	);

	my $rc = system( "diff -q $tmp $tidy > /dev/null 2>&1" );
	if ( !$rc ) {
		unlink(@tmps);
	}
	elsif ($test_only) {
		print "$file is UNTIDY\n";
		unlink(@tmps);
		$seen_untidy++;
	}
	else {
		print "$file was changed\n";
		if ($tmp eq $file) {
			rename( $tidy, $file );
		}
		else {
			open(TIDY, $tidy);
			my $mxms = "$tmp.mxms";
			open(TMP, ">$mxms");
			push @tmps, $mxms;
			my $cull_sub_decl;
			while(<TIDY>) {
				if (m{^sub (\w+)} and $saved_decl{$1}) {
					$_ = delete $saved_decl{$1};
				}
				print TMP $_;
			}
			close TMP;
			close TIDY;
			rename( $mxms, $file );
			unlink(@tmps);
		}
	}
}

exit $seen_untidy;

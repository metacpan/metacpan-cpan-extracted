#!/usr/bin/perl

# Compile-testing for Perl::PowerToys modules

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 40;
use PPI;
use PPI::App::ppi_version ();

sub version_ok {
        my $string   = shift;
        my $version  = shift;
        my $message  = shift || "Found version $version";
	my $document = PPI::Document->new( \$string );
	my $elements = $document->find( \&PPI::App::ppi_version::_wanted );
	is_deeply(
		[
			map { PPI::App::ppi_version::_get_version($_) }
			@$elements,
		],
		[ $version ],
		$message,
	);
	is(
		PPI::App::ppi_version::_get_version($elements->[0]),
		'0.01',
		'_get_version ok',
	);
	ok(
		PPI::App::ppi_version::_change_document( $document, '0.01', '0.02' ),
		'PPI::App::ppi_version::_change_document ok',
	);
	my $changed = $document->serialize;
	$string =~ s/0.01/0.02/g;
	is( $changed, $string, 'Changed document is correct' );
}

# Single-Quote vars
version_ok( <<'END_PERL', '0.01', q{$VERSION = '0.01'} );
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}
END_PERL

# q vars
version_ok( <<'END_PERL', '0.01', q{$VERSION = q~0.01~} );
use vars qw{$VERSION};
BEGIN {
	$VERSION = q~0.01~;
}
END_PERL

# Double-Quote vars
version_ok( <<'END_PERL', '0.01', q{$VERSION = "0.01"} );
use vars qw{$VERSION};
BEGIN {
	$VERSION = "0.01";
}
END_PERL

# qq vars
version_ok( <<'END_PERL', '0.01', q{$VERSION = qq~0.01~} );
use vars qw{$VERSION};
BEGIN {
	$VERSION = qq~0.01~;
}
END_PERL

# Numeric vars
version_ok( <<'END_PERL', '0.01', q{$VERSION = 0.01} );
use vars qw{$VERSION};
BEGIN {
	$VERSION = 0.01;
}
END_PERL

# Single-Quote our
version_ok( <<'END_PERL', '0.01', q{our $VERSION = '0.01'} );
our $VERSION = '0.01';
END_PERL

# q our
version_ok( <<'END_PERL', '0.01', q{our $VERSION = q~0.01~} );
our $VERSION = q~0.01~;
END_PERL

# Double-Quote our
version_ok( <<'END_PERL', '0.01', q{our $VERSION = "0.01"} );
our $VERSION = "0.01";
END_PERL

# qq our
version_ok( <<'END_PERL', '0.01', q{our $VERSION = qq~0.01~} );
our $VERSION = qq~0.01~;
END_PERL

# Numeric our
version_ok( <<'END_PERL', '0.01', q{our $VERSION = 0.01} );
our $VERSION = 0.01;
END_PERL

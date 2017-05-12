# $Id: 01_tex_hyphen.t 119 2009-08-17 05:49:22Z roland $
# $Revision: 119 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/rhonda/trunk/TeX-Hyphen-Pattern/t/01_tex_hyphen.t $
# $Date: 2009-08-17 07:49:22 +0200 (Mon, 17 Aug 2009) $

use strict;
use warnings;
use utf8;

use open ':std', ':locale';
use Test::More;
if (!eval { require TeX::Hyphen; 1 } ) {
	plan skip_all => q{TeX::Hyphen required for testing compatibility};
}

$ENV{TEST_AUTHOR} && eval { require Test::NoWarnings };

use TeX::Hyphen::Pattern;
my $thp    = TeX::Hyphen::Pattern->new();
my @labels = map { m/.*::(.*)/; $1 } $thp->available;
my $words   = q{Supercalifragilisticexpialidocious minuskloj Rechtschreibung देवनागरी Upplýsingatæknifyrirtæki уламжлалаа азбука ὀφειλήματα οφειλήματα};

plan tests => ( 0 + @labels ) + 1;
for my $label (@labels) {
    $thp->label($label);
    my $hyph = TeX::Hyphen->new( $thp->filename );
	my $broken = join ' ', map { $hyph->visualize($_) } split / /, $words;
    ( $broken ne $words ) && diag( sprintf '%10s: %s', ( $label, $broken ) );
    isnt( $words, $broken, qq{using '$label' in TeX::Hyphen} );
}

my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{TEST_AUTHOR};
}
$ENV{TEST_AUTHOR} && Test::NoWarnings::had_no_warnings();

use strict;
use warnings;

use Test::More 0.98;
use FindBin;

use lib "$FindBin::Bin/lib";

use winfail;

# FILENAME: 01_basic.t
# CREATED: 23/03/12 23:54:55 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Basic tests for the class ( USE / Construct )

use_ok('Path::ScanINC');

will_win 'Basic Construction';
t { my $x = Path::ScanINC->new() };

will_win 'Basic Construction with empty hash';
t { my $x = Path::ScanINC->new( {} ) };

will_win 'Basic Construction 1 item hash';
t { my $x = Path::ScanINC->new( { inc => [] } ) };

will_win 'Basic Construction 1 item hash as an array';
t { my $x = Path::ScanINC->new( inc => [] ) };

will_fail 'Basic Construction 1 item non-hash';
t { my $x = Path::ScanINC->new('x') };

will_fail 'Basic Construction 3 item non-hash';
t { my $x = Path::ScanINC->new( 'x', 'y', 'z' ) };

will_win 'Set immutable = 1 during construction';
t { my $x = Path::ScanINC->new( immutable => 1 ) };

will_win 'Set immutable = undef during construction';
t { my $x = Path::ScanINC->new( immutable => undef ) };

will_fail 'Set immutable = [] during construction';
t { my $x = Path::ScanINC->new( immutable => [] ) };

will_win "Set inc = \\\@INC during construction";
t { my $x = Path::ScanINC->new( inc => \@INC ) };

will_win "Set inc = [  ] during construction";
t { my $x = Path::ScanINC->new( inc => [ 'x', 'y', 'z' ] ) };

will_fail "Set inc = 'x' during construction";
t { my $x = Path::ScanINC->new( inc => 'x' ) };

done_testing;


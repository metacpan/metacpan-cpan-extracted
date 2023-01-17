use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.2';
use Test::Without::Module qw( re::engine::RE2 );

use Path::Tiny;

use String::License;

plan 1;

my $string  = path('t/grant/Apache/one_helper.rb')->slurp_utf8;
my $license = String::License->new( string => $string )->as_text;

is $license, 'Apache-2.0', 'matches expected license';

done_testing;

use strict;
use warnings;
use Test::More;

use Types::Standard qw( Str StrMatch );

use MooX::Press (
	prefix         => 'Local::MyApp',
	'class:Person' => {
		has            => [ 'name!' ],
		factory        => undef,
		subclass       => [
			'Man'    => {
				multifactory   => [
					'new_person'   => {
						signature     => [ Str, StrMatch[qr/^m/i] ],
						code          => sub { my($f,$c,$n,$g)=@_; $c->new(name=>$n) },
					},
				],
			},
			'Woman'    => {
				multifactory   => [
					'new_person'   => {
						signature     => [ Str, StrMatch[qr/^f/i] ],
						code          => sub { my($f,$c,$n,$g)=@_; $c->new(name=>$n) },
					},
				],
			},
		],
	},
);

# diag explain [ 'Sub::MultiMethod'->get_multimethod_candidates('Local::MyApp', 'new_person') ];

my $alice = 'Local::MyApp'->new_person( 'Alice',  'female' );
my $bob   = 'Local::MyApp'->new_person( 'Robert', 'male'   );

isa_ok( $alice, 'Local::MyApp::Types'->get_type('Woman')->class );
isa_ok( $bob,   'Local::MyApp::Types'->get_type('Man')->class );

done_testing;


#! /usr/bin/env perl
use Test2::V0;
use Mock::Data::Util 'inflate_template';

my @tests= (
	[ 'a',                   'a' ],
	[ '{a}',                 'a()' ],
	[ '{a 2}',               'a(x=2)' ],
	[ '{a }',                'a()' ],
	[ '{b}',                 'b()' ],
	[ '{b x=5}',             'b(x=5)' ],
	[ '{b x==5}',            'b(x==5)' ],
	[ '{a x=6}{b c z=4 d}',  'a(x=6)b(x=c y=d z=4)' ],
	[ '{a::b}',              'a_b' ],
	# Invalid {} notation just results in no substitution performed
	[ '{',                   '{' ],
	[ 'x}',                  'x}' ],
	[ '{x',                  '{x' ],
	# Special template names that are just string escapes
	[ '{}',                  '' ],
	[ '{#20}',               ' ' ],
	[ '{#7B}',               '{' ],
	# nested templates
	[ '{a {#7B}}',           'a(x={)' ],
	[ '{a x{#20}y}',         'a(x=x y)' ],
	[ '{b x{#3D}=4}',        'b(x=x==4)' ],
	[ '{b x={#3D}4}',        'b(x==4)' ],
	[ '{a {b x={#3D}}}',     'a(x=b(x==))' ],
);
my $mockdata= MockRelData->new;
for (@tests) {
	my ($in, $out)= @$_;
	my $tname= !ref $in? $in : ref $in eq 'ARRAY'? join(' ', '[', @$in, ']') : '\\'.$$in;
	my $gen= inflate_template($in);
	my $val= ref $gen? $gen->generate($mockdata) : $gen;
	is( $val, $out, $tname );
}

{
	package MockRelData;
	sub new { bless {}, shift }
	my %generators;
	BEGIN {
		%generators= (
			# first positional param of a is 'x'.
			a => sub {
				my $mock= shift;
				my %named= ref $_[0] eq 'HASH'? %{ (shift) } : ();
				$named{x}= shift if @_;
				'a('.join(' ', map "$_=$named{$_}", sort keys %named).')';
			},
			'a::b' => sub { "a_b" },
			# first positional param of b is 'x', then 'y'
			b => sub {
				my $mock= shift;
				my %named= ref $_[0] eq 'HASH'? %{ (shift) } : ();
				$named{x}= shift if @_;
				$named{y}= shift if @_;
				'b('.join(' ', map "$_=$named{$_}", sort keys %named).')';
			}
		);
	}
	sub generators { \%generators }
	sub call {
		my $self= shift;
		my $name= shift;
		$generators{$name}->($self, @_);
	}
}

done_testing;

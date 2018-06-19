#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use File::Spec::Functions 'catdir';
use Time::HiRes 'sleep';
use Test::More;
use Try::Tiny;
use Log::Any::Adapter 'TAP';
use OpenGL::Sandbox qw/ make_context get_gl_errors /;
use OpenGL::Sandbox::Texture;

my $ctx= make_context();

subtest render => \&test_render;
sub test_render {
	my $tx1= OpenGL::Sandbox::Texture->new(filename => catdir($FindBin::Bin, 'data', 'tex', '8x8.png'))->load;
	my $tx2= OpenGL::Sandbox::Texture->new(filename => catdir($FindBin::Bin, 'data', 'tex', '14x7-rgba.png'))->load;
	my @tests= (
		[ ],
		[ center => 1 ],
		[ x => 1.5 ],
		[ y => 1.5 ],
		[ z => 1.5 ],
		[ w => 1, h => 1 ],
		[ w => 1 ],
		[ h => 1 ],
		[ scale => 4 ],
		[ s => .1 ],
		[ t => .1 ],
		[ s_rep => 5 ],
		[ t_rep => 5 ],
	);
	sub tname { my $x= join '', explain(shift); $x =~ s/[ \t\n\r]//g; $x };
	# Can't actually check result, but just check for exceptions
	for my $t (@tests) {
		is( (try{ $tx1->render(@$t); '' } catch {$_}), '', 'render sq   '.tname($t) );
		is( (try{ $tx2->render(@$t); '' } catch {$_}), '', 'render rect '.tname($t) );
	}
};

done_testing;

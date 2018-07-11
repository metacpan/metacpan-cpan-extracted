#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use File::Spec::Functions 'catdir';
use Time::HiRes 'sleep';
use Test::More;
use Try::Tiny;
use Log::Any::Adapter 'TAP';
use OpenGL::Sandbox qw/ make_context get_gl_errors glFlush GL_TRIANGLES GL_MODELVIEW_MATRIX /;
use OpenGL::Sandbox::V1 qw/ local_matrix load_identity rotate scale trans trans_scale get_matrix /;

my $c= try { make_context; }
	or plan skip_all => "Can't test without context";

# No way to verify... just call methods and verify no GL errors.
sub assert_noerror {
	my ($code, $name)= @_;
	local $@;
	if (eval { $code->(); 1; }) {
		glFlush();
		is_deeply( [get_gl_errors], [], $name);
	} else {
		fail($name);
		diag $@;
	}
}

sub matrix_ok {
	my ($expected, $name)= @_;
	my @actual= get_matrix(GL_MODELVIEW_MATRIX);
	$_= (sprintf('%.04f', $_) =~ s/^-0.0000$/0.0000/r)  # tests were failing due to negative zero
		for (@$expected, @actual);
	is_deeply(\@actual, $expected, $name);
}

load_identity;
matrix_ok([
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1
	], 'identity' );

subtest translate_and_scale => \&translate_and_scale;
sub translate_and_scale {
	assert_noerror sub {
			load_identity;
			trans 1,2;
			matrix_ok([
				1, 0, 0, 0,
				0, 1, 0, 0,
				0, 0, 1, 0,
				1, 2, 0, 1
			], 'trans 1,2');
		}, 'translate xy';

	assert_noerror sub {
			load_identity;
			scale 2;
			matrix_ok([
				2, 0, 0, 0,
				0, 2, 0, 0,
				0, 0, 2, 0,
				0, 0, 0, 1
			], 'scale xyz by 2');
		}, 'scale xyz';

	assert_noerror sub {
			load_identity;
			scale 2,3;
			matrix_ok([
				2, 0, 0, 0,
				0, 3, 0, 0,
				0, 0, 1, 0,
				0, 0, 0, 1
			], 'scale xy by 2,3');
		}, 'scale xy';

	assert_noerror sub {
			load_identity;
			trans_scale 1,2,3, 5;
			matrix_ok([
				5, 0, 0, 0,
				0, 5, 0, 0,
				0, 0, 5, 0,
				1, 2, 3, 1
			], 'trans xyz then scale xyz');
		}, 'trans_scale xyz';

	assert_noerror sub {
			load_identity;
			trans_scale 1,2,3, 5,4,3;
			matrix_ok([
				5, 0, 0, 0,
				0, 4, 0, 0,
				0, 0, 3, 0,
				1, 2, 3, 1
			], 'trans xyz then scale xyz');
		}, 'trans_scale x,y,z';
};

subtest rotate => \&test_rotate;
sub test_rotate {
	assert_noerror sub {
			load_identity;
			rotate 90, 0,0,1;
			matrix_ok([
				0, 1, 0, 0,
				-1, 0, 0, 0,
				0, 0, 1, 0,
				0, 0, 0, 1
			], 'rotate around z');
		}, 'rotate 0,0,1';

	assert_noerror sub {
			load_identity;
			rotate z => 90;
			matrix_ok([
				0, 1, 0, 0,
				-1, 0, 0, 0,
				0, 0, 1, 0,
				0, 0, 0, 1
			], 'rotate around z');
		}, 'rotate z';

	assert_noerror sub {
			load_identity;
			rotate x => 90;
			matrix_ok([
				1, 0, 0, 0,
				0, 0, 1, 0,
				0, -1, 0, 0,
				0, 0, 0, 1
			], 'rotate around x');
		}, 'rotate x';

	assert_noerror sub {
			load_identity;
			rotate y => 90;
			matrix_ok([
				0, 0, -1, 0,
				0, 1, 0, 0,
				1, 0, 0, 0,
				0, 0, 0, 1
			], 'rotate around y');
		}, 'rotate y';
};

subtest local_matrix => \&test_local_matrix;
sub test_local_matrix {
	load_identity;
	local_matrix {
		assert_noerror sub {
				rotate x => 90;
				matrix_ok([
					1, 0, 0, 0,
					0, 0, 1, 0,
					0, -1, 0, 0,
					0, 0, 0, 1
				], 'rotate around x');
			}, 'rotate x';
	};
	assert_noerror sub {
			matrix_ok([
				1, 0, 0, 0,
				0, 1, 0, 0,
				0, 0, 1, 0,
				0, 0, 0, 1
			], 'identity restored');
		}, 'no errors';
	# Now try nesting deeper and dying
	eval {
		load_identity;
		rotate z => 90;
		local_matrix {
			rotate x => 45;
			local_matrix {
				rotate y => -60;
				local_matrix {
					rotate 50, 1, 2, 3;
					die "Runtime exception\n";
				};
			};
		};
	};
	matrix_ok([
		0, 1, 0, 0,
		-1, 0, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1
	], 'only Z is rotated');
	is( $@, "Runtime exception\n", 'caught correct error' );
	
	# Now try multiple nesting and returning various lists
	load_identity;
	rotate x => 90;
	local_matrix {
		local_matrix {
			rotate z => 45;
			(1,2,3);
		};
		local_matrix {
			rotate y => 30;
			()
		};
	};
	matrix_ok([
		1, 0, 0, 0,
		0, 0, 1, 0,
		0, -1, 0, 0,
		0, 0, 0, 1
	], 'only X is rotated');
}

done_testing;

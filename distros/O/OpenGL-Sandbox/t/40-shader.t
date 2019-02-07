#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Try::Tiny;
use Test::More;
use lib "$FindBin::Bin/lib";
use Log::Any::Adapter 'TAP';
use OpenGL::Sandbox qw/ make_context get_gl_errors GL_FLOAT /;

plan skip_all => "Can't create an OpenGL context: $@"
	unless eval { make_context(); 1 };

plan skip_all => "No support for modern shaders in this OpenGL context: $@"
	unless eval {
		require OpenGL::Sandbox::Shader;
		require OpenGL::Sandbox::Program;
	};

OpenGL::Sandbox->import('GL_FLOAT_MAT4');

my $simple_vertex_shader= <<END;
attribute vec4 pos;
uniform   mat4 mat;
void main() {
    gl_Position = mat * pos;
}
END

my $simple_fragment_shader= <<END;
void main() {
	gl_FragColor = vec4(0,1,0,0);
}
END

subtest vertex_shader => \&test_vertex_shader;
sub test_vertex_shader {
	my $vs= new_ok( 'OpenGL::Sandbox::Shader', [ filename => 'demo.vert', source => $simple_vertex_shader ] );
	ok( eval { $vs->prepare; 1 }, 'compiled vertex shader' )
		or diag $@;
	done_testing;
}

subtest shader_program => \&test_shader_program;
sub test_shader_program {
	my $prog= new_ok( 'OpenGL::Sandbox::Program', [ name => 'Test' ], shaders => {} );
	$prog->{shaders}{vertex}= OpenGL::Sandbox::Shader->new(filename => 'demo.vert', source => $simple_vertex_shader);
	$prog->{shaders}{fragment}= OpenGL::Sandbox::Shader->new(filename => 'demo.frag', source => $simple_fragment_shader);
	ok( eval { $prog->prepare; 1 }, 'compiled GL shader pipeline' )
		or diag $@;
	
	is_deeply( $prog->uniforms, { mat => ['mat',0,GL_FLOAT_MAT4(),1] }, 'found uniforms in program' );
	is( OpenGL::Sandbox::get_glsl_type_name($prog->uniforms->{mat}[2]), 'mat4', 'uniform glsl type name' );
	
	my @mat= ( 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15);
	$prog->bind;
	ok( eval{ $prog->set_uniform('mat', @mat); }, 'set_uniform values' ) or diag $@;
	ok( eval{ $prog->set_uniform('mat', \@mat); }, 'set_uniform arrayref' ) or diag $@;
	ok( eval{ $prog->set_uniform('mat', [ [0,1,2,3], [4,5,6,7], [8,9,10,11], [12,13,14,15] ]); }, 'set_uniform array-of-array' ) or diag $@;
	SKIP: {
		skip "OpenGL::Array not available", 3 unless eval { require OpenGL::Array; 1; };
		
		my $a= new_ok( 'OpenGL::Array', [ 16, GL_FLOAT ] );
		$a->assign(0, @mat) if $a;
		ok( eval{ $prog->set_uniform('mat', $a); }, 'set_uniform OpenGL::Array' ) or diag $@;
		ok( eval{ $prog->set_uniform('mat', \($a->retrieve_data(0, 16*4))); }, 'set_uniform packed buffer' ) or diag $@;
	}
	done_testing;
}

done_testing;

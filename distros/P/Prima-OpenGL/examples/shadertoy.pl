BEGIN {
	eval "use OpenGL::Modern;";
	if ( $@) {
		warn <<DIE;
***
This example needs optional OpenGL::Modern module installed. 
Please run 'cpan OpenGL::Modern'. If the example still doesn't
work, please file a bug report!
***
DIE
		exit(1);
	}
};

use strict;
use FindBin qw($Bin);
use Time::HiRes 'time';
use OpenGL::Modern ':all';
use OpenGL::Modern::Helpers qw(
	pack_GLint 
	pack_GLfloat 
	xs_buffer
	iv_ptr 
	glGetShaderInfoLog_p 
	glGetProgramInfoLog_p
	glGetShaderiv_p
	glGetProgramiv_p
	croak_on_gl_error
);
use Prima qw(Application GLWidget OpenGL::Modern);

my (%uniforms, %shaders, $shader_text, $program);
my ($gl_initialized, $fullscreen, $xres, $yres, $time, $state, $frames);
my ( $window, $gl_widget);
my $started      = time;
my $frame_second = int time;

=head1 NAME

shadertoy - demonstration of an opengl shader

=head1 DESCRIPTION

This is a cut-down version of app/shadertoy by Corion, to focus on shader demo only.

=cut

my $fragment_header = <<HEADER;
#version 120
uniform vec4      iMouse;
uniform vec3      iResolution;
uniform float     iGlobalTime;
#line 1 // make the error numbers line up nicely
HEADER

my $fragment_footer = <<'FRAGMENT_FOOTER';
void main() {
	vec4 color = vec4(0.0,0.0,0.0,1.0);
	mainImage( color, gl_FragCoord.xy );
	gl_FragColor = color;
}
FRAGMENT_FOOTER

sub create_shader
{
	my ( $type, $text ) = @_;
        
        my $id = glCreateShader( $type );
        die "Couldn't create shader" unless $id;
        croak_on_gl_error;
        glShaderSource_p( $id, $text );
        croak_on_gl_error;
        glCompileShader($id);
        croak_on_gl_error;

        if( glGetShaderiv_p( $id, GL_COMPILE_STATUS, 2 ) == GL_FALSE ) {
            my $log = glGetShaderInfoLog_p($id) // 'Compile error';
            die "Bad shader: $log\n";
        }

	return $shaders{$type} = $id;
}

sub init_shader
{
	create_shader( GL_FRAGMENT_SHADER, $fragment_header .  $shader_text .  $fragment_footer );

	$program = glCreateProgram;
	die "Couldn't create shader program: " . glGetError . "\n" unless $program;
	my $log = glGetProgramInfoLog_p($program);
	die $log if $log;
	for my $shader ( sort keys %shaders ) {
		glAttachShader( $program, $shaders{$shader} );
		my $err = glGetError;
		warn glGetProgramInfoLog_p($program) if $err;
	}
	glLinkProgram($program);
	my $err = glGetError;
	if( glGetProgramiv_p( $program, GL_LINK_STATUS, 2) != GL_TRUE ) {
		my $log = glGetProgramInfoLog_p($program) // 'Link error';
		die "Link shader to program: $log\n";
	}

	my $count = glGetProgramiv_p( $program, GL_ACTIVE_UNIFORMS, 2);
	for my $index ( 0 .. $count-1 ) {
		xs_buffer( my $length, 8 );
		xs_buffer( my $size,   8 );
		xs_buffer( my $type,   8 );
		xs_buffer( my $name, 16); # Names are maximum 16 chars:
	        glGetActiveUniform_c( $program, $index, 16, iv_ptr($length), iv_ptr($size), iv_ptr($type), $name);
		$length = unpack 'I', $length;
		$name = substr $name, 0, $length;
		$uniforms{ $name } = glGetUniformLocation_c( $program, $name);
	}
}

sub set_uniform
{
	my ( $func, $name, @var ) = @_;
	return unless defined $uniforms{$name};
	my $method = 'glProgramUniform' . $func;
	no strict 'refs';
	$method->($program, $uniforms{$name}, @var);
}

sub gl_paint
{
	my $self = shift;
	
	init_shader unless $program;

	glUseProgram( $program );

	$time = time - $started;
	set_uniform( '1f', iGlobalTime => $time);
	set_uniform( '3f', iResolution => $xres, $yres, 1.0);
	set_uniform( '4fv_c', iMouse => 1, iv_ptr(my $iMouse = pack_GLfloat($gl_widget->pointerPos,0,0))) if $state->{grab};

	glBegin(GL_POLYGON);
		glVertex2f(-1,-1);
		glVertex2f(-1, 1);
		glVertex2f( 1, 1);
		glVertex2f( 1,-1);
	glEnd();

	glUseProgram( 0 );
	glFlush;
}

sub create_gl_widget
{
	my %param;
	if ( $fullscreen ) {
		my $primary = $::application->get_monitor_rects->[0];
		%param = (
			clipOwner  => 0,
			origin     => [@{$primary}[0,1]],
			size       => [@{$primary}[2,3]],
			onLeave    => sub {
				$fullscreen = 0;
				$window->menu->uncheck('fullscreen');
				$gl_widget->destroy;
				create_gl_widget();
			},
		);
	} else {
		%param = (
			growMode   => gm::Client,
			rect       => [0, 0, $window->size],
		);
	}

	$gl_widget = $window->insert( GLWidget =>
		%param,
		onPaint      => \&gl_paint,
	        onMouseDown  => sub { $state->{grab} = 1 },
	        onMouseUp    => sub { $state->{grab} = 0 },
	        onSize       => sub { ( $xres, $yres ) = shift->size },
	        onClose      => sub {
			glUseProgram(0);
			glDetachShader( $program, $_ ) for values %shaders;
			glDeleteProgram( $program );
			glDeleteShader( $_ ) for values %shaders;
	        },
    );

    undef $program;
    undef %uniforms;
    undef %shaders;

    $gl_widget->focus if $fullscreen;
}

local $/;
if ( $ARGV[0] && open(F, '<', $ARGV[0])) {
	$shader_text = <F>;
	close F;
} else {
	$shader_text = <DATA>;
	close(DATA);
}

$window = Prima::MainWindow->create(
	text => 'Shader toy',
	size => [ 640, 480 ],
	menuItems => [['~Options' => [
		[ ( $fullscreen ? '*' : '') . 'fullscreen', '~Fullscreen', 'Alt+Enter', km::Alt|kb::Enter, sub {
			my ( $window, $menu ) = @_;
			$fullscreen = $window->menu->toggle($menu);
			$gl_widget->destroy;
			create_gl_widget();
		} ],
		[ 'pause' => '~Play/Pause' => 'Space' => kb::Space => sub {
			my ( $window, $menu ) = @_;
			$window->menu->toggle($menu) ? $window->Timer->stop : $window->Timer->start;
		} ],
		[ '~Screenshot' => 'F5' => kb::F5 => sub {
			$gl_widget-> gl_read_pixels-> save('screenshot.png');
			print "Saved!\n";
		} ],
		[],
		[ 'E~xit' => 'Alt+X' => '@X' => sub { shift-> close }],
	]]],
);

create_gl_widget();

$window->insert( Timer =>
	timeout => 10,
	name    => 'Timer',
	onTick  => sub { $gl_widget->repaint }
)->start;

run Prima;

__DATA__

/*
"Seascape" by Alexander Alekseev aka TDM - 2014
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Contact: tdmaav@gmail.com
*/

const int NUM_STEPS = 8;
const float PI	 	= 3.1415;
const float EPSILON	= 1e-3;
float EPSILON_NRM	= 0.1 / iResolution.x;

// sea
const int ITER_GEOMETRY = 3;
const int ITER_FRAGMENT = 5;
const float SEA_HEIGHT = 0.6;
const float SEA_CHOPPY = 4.0;
const float SEA_SPEED = 0.8;
const float SEA_FREQ = 0.16;
const vec3 SEA_BASE = vec3(0.1,0.19,0.22);
const vec3 SEA_WATER_COLOR = vec3(0.8,0.9,0.6);
float SEA_TIME = 1.0 + iGlobalTime * SEA_SPEED;
mat2 octave_m = mat2(1.6,1.2,-1.2,1.6);

// math
mat3 fromEuler(vec3 ang) {
	vec2 a1 = vec2(sin(ang.x),cos(ang.x));
    vec2 a2 = vec2(sin(ang.y),cos(ang.y));
    vec2 a3 = vec2(sin(ang.z),cos(ang.z));
    mat3 m;
    m[0] = vec3(a1.y*a3.y+a1.x*a2.x*a3.x,a1.y*a2.x*a3.x+a3.y*a1.x,-a2.y*a3.x);
	m[1] = vec3(-a2.y*a1.x,a1.y*a2.y,a2.x);
	m[2] = vec3(a3.y*a1.x*a2.x+a1.y*a3.x,a1.x*a3.x-a1.y*a3.y*a2.x,a2.y*a3.y);
	return m;
}
float hash( vec2 p ) {
float h = dot(p,vec2(127.1,311.7));	
    return fract(sin(h)*43758.5453123);
}
float noise( in vec2 p ) {
    vec2 i = floor( p );
    vec2 f = fract( p );	
	vec2 u = f*f*(3.0-2.0*f);
    return -1.0+2.0*mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

// lighting
float diffuse(vec3 n,vec3 l,float p) {
    return pow(dot(n,l) * 0.4 + 0.6,p);
}
float specular(vec3 n,vec3 l,vec3 e,float s) {    
    float nrm = (s + 8.0) / (3.1415 * 8.0);
    return pow(max(dot(reflect(e,n),l),0.0),s) * nrm;
}

// sky
vec3 getSkyColor(vec3 e) {
    e.y = max(e.y,0.0);
    vec3 ret;
    ret.x = pow(1.0-e.y,2.0);
    ret.y = 1.0-e.y;
    ret.z = 0.6+(1.0-e.y)*0.4;
    return ret;
}

// sea
float sea_octave(vec2 uv, float choppy) {
    uv += noise(uv);        
    vec2 wv = 1.0-abs(sin(uv));
    vec2 swv = abs(cos(uv));    
    wv = mix(wv,swv,wv);
    return pow(1.0-pow(wv.x * wv.y,0.65),choppy);
}

float map(vec3 p) {
    float freq = SEA_FREQ;
    float amp = SEA_HEIGHT;
    float choppy = SEA_CHOPPY;
    vec2 uv = p.xz; uv.x *= 0.75;
    
    float d, h = 0.0;    
    for(int i = 0; i < ITER_GEOMETRY; i++) {        
    	d = sea_octave((uv+SEA_TIME)*freq,choppy);
    	d += sea_octave((uv-SEA_TIME)*freq,choppy);
        h += d * amp;        
    	uv *= octave_m; freq *= 1.9; amp *= 0.22;
        choppy = mix(choppy,1.0,0.2);
    }
    return p.y - h;
}

float map_detailed(vec3 p) {
    float freq = SEA_FREQ;
    float amp = SEA_HEIGHT;
    float choppy = SEA_CHOPPY;
    vec2 uv = p.xz; uv.x *= 0.75;
    
    float d, h = 0.0;    
    for(int i = 0; i < ITER_FRAGMENT; i++) {        
    	d = sea_octave((uv+SEA_TIME)*freq,choppy);
    	d += sea_octave((uv-SEA_TIME)*freq,choppy);
        h += d * amp;        
    	uv *= octave_m; freq *= 1.9; amp *= 0.22;
        choppy = mix(choppy,1.0,0.2);
    }
    return p.y - h;
}

vec3 getSeaColor(vec3 p, vec3 n, vec3 l, vec3 eye, vec3 dist) {  
    float fresnel = clamp(1.0 - dot(n,-eye), 0.0, 1.0);
    fresnel = pow(fresnel,3.0) * 0.65;

    vec3 reflected = getSkyColor(reflect(eye,n));    
    vec3 refracted = SEA_BASE + diffuse(n,l,80.0) * SEA_WATER_COLOR * 0.12; 
    
    vec3 color = mix(refracted,reflected,fresnel);
    
    float atten = max(1.0 - dot(dist,dist) * 0.001, 0.0);
    color += SEA_WATER_COLOR * (p.y - SEA_HEIGHT) * 0.18 * atten;
    
    color += vec3(specular(n,l,eye,60.0));
    
    return color;
}

// tracing
vec3 getNormal(vec3 p, float eps) {
    vec3 n;
    n.y = map_detailed(p);    
    n.x = map_detailed(vec3(p.x+eps,p.y,p.z)) - n.y;
    n.z = map_detailed(vec3(p.x,p.y,p.z+eps)) - n.y;
    n.y = eps;
    return normalize(n);
}

float heightMapTracing(vec3 ori, vec3 dir, out vec3 p) {  
    float tm = 0.0;
    float tx = 1000.0;    
    float hx = map(ori + dir * tx);
    if(hx > 0.0) return tx;   
    float hm = map(ori + dir * tm);    
    float tmid = 0.0;
    for(int i = 0; i < NUM_STEPS; i++) {
        tmid = mix(tm,tx, hm/(hm-hx));                   
        p = ori + dir * tmid;                   
    	float hmid = map(p);
		if(hmid < 0.0) {
        	tx = tmid;
            hx = hmid;
        } else {
            tm = tmid;
            hm = hmid;
        }
    }
    return tmid;
}

// main
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 uv = fragCoord.xy / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;    
    float time = iGlobalTime * 0.3 + iMouse.x*0.01;
        
    // ray
    vec3 ang = vec3(sin(time*3.0)*0.1,sin(time)*0.2+0.3,time);    
    vec3 ori = vec3(0.0,3.5,time*5.0);
    vec3 dir = normalize(vec3(uv.xy,-2.0)); dir.z += length(uv) * 0.15;
    dir = normalize(dir) * fromEuler(ang);
    
    // tracing
    vec3 p;
    heightMapTracing(ori,dir,p);
    vec3 dist = p - ori;
    vec3 n = getNormal(p, dot(dist,dist) * EPSILON_NRM);
    vec3 light = normalize(vec3(0.0,1.0,0.8)); 
             
    // color
    vec3 color = mix(
        getSkyColor(dir),
        getSeaColor(p,n,light,dir,dist),
    	pow(smoothstep(0.0,-0.05,dir.y),0.3));
        
    // post
    fragColor = vec4(pow(color,vec3(0.75)), 1.0);
}

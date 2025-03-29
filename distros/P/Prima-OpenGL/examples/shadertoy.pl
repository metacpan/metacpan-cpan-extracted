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
use Prima qw(Application GLWidget OpenGL);

my (%uniforms, %shaders, $program);
my ($gl_initialized, $fullscreen, $xres, $yres, $time, $state, $frames);
my ( $window, $gl_widget);
my $started      = time;
my $frame_second = int time;
my ($cam, @cams) = (0);

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
	my $cam = shift;
	create_shader( GL_FRAGMENT_SHADER, $fragment_header .  $cams[$cam]->[1] .  $fragment_footer );

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

	init_shader($cam) unless $program;

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

sub change_view
{
	my $newcam = shift;
	return if $cam == $newcam;
	$window->menu->uncheck("cam$cam");
	$window->menu->check("cam$newcam");
	$gl_widget->destroy;
	$cam = $newcam;
	create_gl_widget();

}

if ( $ARGV[0] && open(F, '<', $ARGV[0])) {
	local $/;
	push @cams, [file => <F>];
	close F;
} elsif ( open my $f, $0 ) {
	my ($text, $id, $collect);
	while ($_ = <$f>) {
		if ( m/^=for shadertoy (.+)$/) {
			$collect = 1;
			$id = $1;
			$text = '';
		} elsif ( $collect && m/^=end/) {
			$collect = 0;
			push @cams, [ $id, $text ];
		} elsif ( $collect ) {
			$text .= $_;
		}
	}
} else {
	die 'no toys';
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
	]],
		(@cams > 1) ? ['~Views' => [
			map {
				my $k = $_;
				[ "cam$k" => $cams[$k]->[0] => sub { change_view($k) } ]
			} (0..$#cams),
		]] : (),
	],
);

$window->menu->check("cam0") if @cams > 1;

create_gl_widget();

$window->insert( Timer =>
	timeout => 10,
	name    => 'Timer',
	onTick  => sub { $gl_widget->repaint }
)->start;

run Prima;

=cut

=for shadertoy Cam 1
// https://www.shadertoy.com/view/MdXyzX
// afl_ext 2017-2024
// MIT License

// Use your mouse to move the camera around! Press the Left Mouse Button on the image to look around!

#define DRAG_MULT 0.38 // changes how much waves pull on the water
#define WATER_DEPTH 1.0 // how deep is the water
#define CAMERA_HEIGHT 1.5 // how high the camera should be
#define ITERATIONS_RAYMARCH 12 // waves iterations of raymarching
#define ITERATIONS_NORMAL 37 // waves iterations when calculating normals

#define NormalizedMouse (iMouse.xy / iResolution.xy) // normalize mouse coords

// Calculates wave value and its derivative,
// for the wave direction, position in space, wave frequency and time
vec2 wavedx(vec2 position, vec2 direction, float frequency, float timeshift) {
  float x = dot(direction, position) * frequency + timeshift;
  float wave = exp(sin(x) - 1.0);
  float dx = wave * cos(x);
  return vec2(wave, -dx);
}

// Calculates waves by summing octaves of various waves with various parameters
float getwaves(vec2 position, int iterations) {
  float wavePhaseShift = length(position) * 0.1; // this is to avoid every octave having exactly the same phase everywhere
  float iter = 0.0; // this will help generating well distributed wave directions
  float frequency = 1.0; // frequency of the wave, this will change every iteration
  float timeMultiplier = 2.0; // time multiplier for the wave, this will change every iteration
  float weight = 1.0;// weight in final sum for the wave, this will change every iteration
  float sumOfValues = 0.0; // will store final sum of values
  float sumOfWeights = 0.0; // will store final sum of weights
  for(int i=0; i < iterations; i++) {
    // generate some wave direction that looks kind of random
    vec2 p = vec2(sin(iter), cos(iter));

    // calculate wave data
    vec2 res = wavedx(position, p, frequency, iGlobalTime * timeMultiplier + wavePhaseShift);

    // shift position around according to wave drag and derivative of the wave
    position += p * res.y * weight * DRAG_MULT;

    // add the results to sums
    sumOfValues += res.x * weight;
    sumOfWeights += weight;

    // modify next octave ;
    weight = mix(weight, 0.0, 0.2);
    frequency *= 1.18;
    timeMultiplier *= 1.07;

    // add some kind of random value to make next wave look random too
    iter += 1232.399963;
  }
  // calculate and return
  return sumOfValues / sumOfWeights;
}

// Raymarches the ray from top water layer boundary to low water layer boundary
float raymarchwater(vec3 camera, vec3 start, vec3 end, float depth) {
  vec3 pos = start;
  vec3 dir = normalize(end - start);
  for(int i=0; i < 64; i++) {
    // the height is from 0 to -depth
    float height = getwaves(pos.xz, ITERATIONS_RAYMARCH) * depth - depth;
    // if the waves height almost nearly matches the ray height, assume its a hit and return the hit distance
    if(height + 0.01 > pos.y) {
      return distance(pos, camera);
    }
    // iterate forwards according to the height mismatch
    pos += dir * (pos.y - height);
  }
  // if hit was not registered, just assume hit the top layer,
  // this makes the raymarching faster and looks better at higher distances
  return distance(start, camera);
}

// Calculate normal at point by calculating the height at the pos and 2 additional points very close to pos
vec3 normal(vec2 pos, float e, float depth) {
  vec2 ex = vec2(e, 0);
  float H = getwaves(pos.xy, ITERATIONS_NORMAL) * depth;
  vec3 a = vec3(pos.x, H, pos.y);
  return normalize(
    cross(
      a - vec3(pos.x - e, getwaves(pos.xy - ex.xy, ITERATIONS_NORMAL) * depth, pos.y),
      a - vec3(pos.x, getwaves(pos.xy + ex.yx, ITERATIONS_NORMAL) * depth, pos.y + e)
    )
  );
}

// Helper function generating a rotation matrix around the axis by the angle
mat3 createRotationMatrixAxisAngle(vec3 axis, float angle) {
  float s = sin(angle);
  float c = cos(angle);
  float oc = 1.0 - c;
  return mat3(
    oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s,
    oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s,
    oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c
  );
}

// Helper function that generates camera ray based on UV and mouse
vec3 getRay(vec2 fragCoord) {
  vec2 uv = ((fragCoord.xy / iResolution.xy) * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);
  // for fisheye, uncomment following line and comment the next one
  //vec3 proj = normalize(vec3(uv.x, uv.y, 1.0) + vec3(uv.x, uv.y, -1.0) * pow(length(uv), 2.0) * 0.05);
  vec3 proj = normalize(vec3(uv.x, uv.y, 1.5));
  if(iResolution.x < 600.0) {
    return proj;
  }
  return createRotationMatrixAxisAngle(vec3(0.0, -1.0, 0.0), 3.0 * ((NormalizedMouse.x + 0.5) * 2.0 - 1.0))
    * createRotationMatrixAxisAngle(vec3(1.0, 0.0, 0.0), 0.5 + 1.5 * (((NormalizedMouse.y == 0.0 ? 0.27 : NormalizedMouse.y) * 1.0) * 2.0 - 1.0))
    * proj;
}

// Ray-Plane intersection checker
float intersectPlane(vec3 origin, vec3 direction, vec3 point, vec3 normal) {
  return clamp(dot(point - origin, normal) / dot(direction, normal), -1.0, 9991999.0);
}

// Some very barebones but fast atmosphere approximation
vec3 extra_cheap_atmosphere(vec3 raydir, vec3 sundir) {
  sundir.y = max(sundir.y, -0.07);
  float special_trick = 1.0 / (raydir.y * 1.0 + 0.1);
  float special_trick2 = 1.0 / (sundir.y * 11.0 + 1.0);
  float raysundt = pow(abs(dot(sundir, raydir)), 2.0);
  float sundt = pow(max(0.0, dot(sundir, raydir)), 8.0);
  float mymie = sundt * special_trick * 0.2;
  vec3 suncolor = mix(vec3(1.0), max(vec3(0.0), vec3(1.0) - vec3(5.5, 13.0, 22.4) / 22.4), special_trick2);
  vec3 bluesky= vec3(5.5, 13.0, 22.4) / 22.4 * suncolor;
  vec3 bluesky2 = max(vec3(0.0), bluesky - vec3(5.5, 13.0, 22.4) * 0.002 * (special_trick + -6.0 * sundir.y * sundir.y));
  bluesky2 *= special_trick * (0.24 + raysundt * 0.24);
  return bluesky2 * (1.0 + 1.0 * pow(1.0 - raydir.y, 3.0));
}

// Calculate where the sun should be, it will be moving around the sky
vec3 getSunDirection() {
  return normalize(vec3(sin(iGlobalTime * 0.1), 1.0, cos(iGlobalTime * 0.1)));
}

// Get atmosphere color for given direction
vec3 getAtmosphere(vec3 dir) {
   return extra_cheap_atmosphere(dir, getSunDirection()) * 0.5;
}

// Get sun color for given direction
float getSun(vec3 dir) {
  return pow(max(0.0, dot(dir, getSunDirection())), 720.0) * 210.0;
}

// Great tonemapping function from my other shader: https://www.shadertoy.com/view/XsGfWV
vec3 aces_tonemap(vec3 color) {
  mat3 m1 = mat3(
    0.59719, 0.07600, 0.02840,
    0.35458, 0.90834, 0.13383,
    0.04823, 0.01566, 0.83777
  );
  mat3 m2 = mat3(
    1.60475, -0.10208, -0.00327,
    -0.53108,  1.10813, -0.07276,
    -0.07367, -0.00605,  1.07602
  );
  vec3 v = m1 * color;
  vec3 a = v * (v + 0.0245786) - 0.000090537;
  vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
  return pow(clamp(m2 * (a / b), 0.0, 1.0), vec3(1.0 / 2.2));
}

// Main
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // get the ray
  vec3 ray = getRay(fragCoord);
  if(ray.y >= 0.0) {
    // if ray.y is positive, render the sky
    vec3 C = getAtmosphere(ray) + getSun(ray);
    fragColor = vec4(aces_tonemap(C * 2.0),1.0);
    return;
  }

  // now ray.y must be negative, water must be hit
  // define water planes
  vec3 waterPlaneHigh = vec3(0.0, 0.0, 0.0);
  vec3 waterPlaneLow = vec3(0.0, -WATER_DEPTH, 0.0);

  // define ray origin, moving around
  vec3 origin = vec3(iGlobalTime * 0.2, CAMERA_HEIGHT, 1);

  // calculate intersections and reconstruct positions
  float highPlaneHit = intersectPlane(origin, ray, waterPlaneHigh, vec3(0.0, 1.0, 0.0));
  float lowPlaneHit = intersectPlane(origin, ray, waterPlaneLow, vec3(0.0, 1.0, 0.0));
  vec3 highHitPos = origin + ray * highPlaneHit;
  vec3 lowHitPos = origin + ray * lowPlaneHit;

  // raymatch water and reconstruct the hit pos
  float dist = raymarchwater(origin, highHitPos, lowHitPos, WATER_DEPTH);
  vec3 waterHitPos = origin + ray * dist;

  // calculate normal at the hit position
  vec3 N = normal(waterHitPos.xz, 0.01, WATER_DEPTH);

  // smooth the normal with distance to avoid disturbing high frequency noise
  N = mix(N, vec3(0.0, 1.0, 0.0), 0.8 * min(1.0, sqrt(dist*0.01) * 1.1));

  // calculate fresnel coefficient
  float fresnel = (0.04 + (1.0-0.04)*(pow(1.0 - max(0.0, dot(-N, ray)), 5.0)));

  // reflect the ray and make sure it bounces up
  vec3 R = normalize(reflect(ray, N));
  R.y = abs(R.y);

  // calculate the reflection and approximate subsurface scattering
  vec3 reflection = getAtmosphere(R) + getSun(R);
  vec3 scattering = vec3(0.0293, 0.0698, 0.1717) * 0.1 * (0.2 + (waterHitPos.y + WATER_DEPTH) / WATER_DEPTH);

  // return the combined result
  vec3 C = fresnel * reflection + scattering;
  fragColor = vec4(aces_tonemap(C * 2.0), 1.0);
}

=end

=for shadertoy Cam 2

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

=end

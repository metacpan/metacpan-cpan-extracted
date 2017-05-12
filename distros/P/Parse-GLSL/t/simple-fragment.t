use strict;
use warnings;

use Test::More tests => 2;
use Test::Deep;

use Parse::GLSL;
my $parser = new_ok('Parse::GLSL');
my $txt = '';
while(my $line = <DATA>) {
	if($line =~ /^\s*#\s*(?:(.*))$/) {
		my $cmd = $1;
		note "Had directive [$cmd]\n";
	} else {
		$txt .= $line;
	}
}
ok($parser->from_string($txt), 'looks like we parsed that without throwing errors');

__DATA__

#version 140

uniform float fqc;
uniform vec3 color0;
uniform vec3 color1;

in float Vs;
in vec3 eye_dir;
in vec2 tex_coord;

out vec4 FragColor;

void main(void)
{
	vec3 lit_colour;
	vec2 c = bump_density * tex_coord.st;
	vec2 p = fract(c) - vec2(0.5);
	float d,f;
	d = dot(p,p);
	f = inversesqrt(d + 1.0);
	if(d >= bump_size) {
		p = vec2(0.0);
		f = 1.0;
	}
	vec3 norm_delta = vec3(p.x,p.y,1.0) * f;
	lit_colour = surface_colour.rgb * max(dot(norm_delta, light_dir), 0.0);
	vec3 reflect_dir = reflect(light_dir, norm_delta);
	float spec = max(dot(eye_dir, reflect_dir), 0.0);
	spec = pow(spec, 6.0);
	spec *= specular_factor;
	lit_colour = min(lit_colour + spec, vec3(1.0));
	FragColor = vec4(lit_colour, surface_colour.a);
}



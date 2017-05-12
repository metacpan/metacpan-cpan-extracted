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

varying vec3 Normal;
varying vec3 Position;

void main(void) {
    gl_Position = ftransform();
    Position    = vec3(gl_ModelViewMatrix * gl_Vertex);
    Normal      = gl_NormalMatrix * gl_Normal;
}


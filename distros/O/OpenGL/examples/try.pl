# simple example that opens up a window then goes into interpreter mode

use OpenGL;

glpOpenWindow;
glClearColor(0,0,1,1);
glClear(GL_COLOR_BUFFER_BIT);
glpFlush();

print "OpenGL window open, perl interpreter ready!\n";
print "Try entering some GL commands to draw stuff:\n";
while(<STDIN>){
	$e=eval;
	print "EVAL:  $e\n";
	print "ERROR: $@" if $@;
}

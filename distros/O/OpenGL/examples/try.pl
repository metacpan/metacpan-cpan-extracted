#!/usr/local/bin/perl
#
# simple example that opens up a window then goes into interpretor mode
#

BEGIN{ unshift(@INC,"../blib"); }  # in case OpenGL is built but not installed
BEGIN{ unshift(@INC,"../blib/arch"); } # 5.002 gamma needs this
BEGIN{ unshift(@INC,"../blib/lib"); } # 5.002 gamma needs this
use OpenGL;

glpOpenWindow;
glClearColor(0,0,1,1);
glClear(GL_COLOR_BUFFER_BIT);
glpFlush();

print "OpenGL window open, perl interpretor ready!\n";
print "Try entering some GL commands to draw stuff:\n";
while(<STDIN>){
	$e=eval;
	print "EVAL:  $e\n";
	print "ERROR: $@" if $@;
}

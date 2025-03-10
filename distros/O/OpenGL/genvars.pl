#!/usr/bin/perl


# This is a simple one-off script to generate the various
# coordinate function definitions.

%shorttype = ("double" => "d", "float" => "f",
"int" => "i", "short" => "s", "byte" => "b",
"uint" => "ui", "ushort" => "us", "ubyte" => "ub");


sub doit {
	foreach $dim ($mindim..$maxdim) {
		@nn = @n[0..$dim-1];
		foreach $type (@types) {
			$t = $shorttype{$type};
			print "void\n$name$dim$t(", join(', ', @nn), ")\n";
			print map("\tGL$type\t$_\n", @nn);
			print "\n";
	
			print "void\n$name$dim${t}v_p(", join(', ', @nn), ")\n";
			print map("\tGL$type\t$_\n", @nn);
			print "\tCODE:\n\t{\n";
			print "\t\tGL$type param[$dim];\n";
			print map("\t\tparam[$_] = $n[$_];\n", 0..$dim-1);
			print "\t\t$name$dim${t}v(param);\n\t}\n";
			print "\n";
	
			print "void\n$name$dim${t}v_s(v)\n\tSV *\tv\n\tCODE:\n\t{\n";
			print "\t\tGL$type * v_s = EL(v, sizeof(GL$type)*$dim);\n\t\t$name$dim${t}v(v_s);\n\t}\n";
			print "\n";
	
			print "void\n$name$dim${t}v_c(v)\n\tvoid *\tv\n\tCODE:\n\t$name$dim${t}v(v);\n";
			print "\n";
		}
	}
}

@n = qw(x y z w);
$name = "glVertex";
$mindim = 2;
$maxdim = 4;
@types = qw(double float int short);
doit;

@n = qw(nx ny nz);
$name = "glNormal";
$mindim = 3;
$maxdim = 3;
@types = qw(byte double float int short);
doit;


@n = qw(red green blue alpha);
$name = "glColor";
$mindim = 3;
$maxdim = 4;
@types = qw(byte double float int short ubyte uint ushort);
doit;

@n = qw(s t r q);
$name = "glTexCoord";
$mindim = 1;
$maxdim = 4;
@types = qw(double float int short);
doit;

@n = qw(x y z w);
$name = "glRasterPos";
$mindim = 2;
$maxdim = 4;
@types = qw(double float int short);
doit;

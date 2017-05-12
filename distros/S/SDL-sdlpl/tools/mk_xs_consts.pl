#/!usr/binm/perl

#pass in a list of C constant names, will generate XS code

while (<>)
  {
   chomp;
   s/\s//g;
print"
Uint32
".lc($_)." ()
	CODE:
		RETVAL = ".uc($_).";
	OUTPUT:
		RETVAL

";   
  }


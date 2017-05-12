#/!usr/binm/perl

#pass in a list of C constant names, will generate PM code

while (<>)
  {
   chomp;
   s/\s//g;
   push @c, $_;
  }

my $consts= join '' , map {"\t$_\n"} @c;
print '

my @constants=qw(
'.$consts.'
);

@EXPORT = map { "&$_" }  @constants;

#this only deals with constants defined as functions;
foreach my $constant (@constants)
  {
   my $func = $constant;
   
   #create the constant function
   my $sdl_func_call ="SDL::sdlpl::".lc($func);
   eval "sub $constant { $sdl_func_call; }";
   
   #this allows reverse engineering the values from ints to
   #symbolic names, it should only be used internally for any
   #human friendly debug dumps.
  
   $constant_lookup{eval "&$sdl_func_call"}=$constant;
  }
';

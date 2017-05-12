#/!usr/binm/perl -w
use strict;
use Data::Dumper;
#pass in a list of !SIMPLE! C protoypes, will generate XS code

while (<>)
  {
   my $line=$_;
   chomp $line;
   my (
       $ret_fname,
       $params) = $line =~ #
	 /	   
	   ^
	     (
	     [^(]+  #extract ret type and fname as one
	     )
	   \(
	    (
	   [^)]+    #extract params
	    )
	   \);
	 /xg;
   my ($fname) = $ret_fname =~ /([a-zA-Z0-9_]+)$/g;
   my $ret = $ret_fname;
   $ret =~ s/$fname//;
   if (0)
     {
      print "LIN: $line\n\n";
      print "RET: $ret\n";
      print "NAM: $fname\n";
      print "PAR: $params\n\n";
     }
   my @xs_params   =();
   if ($params ne "void")
     {
      my @param_list= split /,/, $params;
      #print Dumper \@param_list;
      foreach  my $p  (@param_list)
	{
	 my ($vname) = $p =~ /([a-zA-Z0-9_]+)$/g;
	 my $vtype = $p;
	 $vtype =~ s/$vname//;
	 $vtype =~ s/^\s*//;        
	 $vname =~ s/\s//g;
	 #print "\t'$vname' = '$vtype'\n";
	 push @xs_params, { NAME=> $vname, TYPE=>$vtype} ;
	}
     }
   my $perl_name=$fname;
   $perl_name  =~ s/^SDL_/sdl/;
   $perl_name =~ s/([A-Z])/_\1/g;
   $perl_name = lc $perl_name;
 
   #print xs_template($ret, $fname, $perl_name, \@xs_params);
   print pm_template($ret, $fname, $perl_name, "SDL::sdlpl", \@xs_params);
  
   print "\n\n";
  }


#int SDL_JoystickGetBall(SDL_Joystick *joystick, int ball, int *dx, int *dy);

sub pm_template
  {
   my ($ret_type, $fname, $perl_func_name, $package, $params) = @_;
   my $text="";
   my $xs_name=$package."::".$perl_func_name;
   my $call_params="";

   #sort of methodify the name:  (quite assuming really)
   $perl_func_name =~ s/^[^_]+_[^_]+_//;
   $text.= "sub $perl_func_name\n{\n\t";
   $text.= 'my $self = shift;'."\n";

   ##build param list
   foreach my $p (@$params)
     {      
      $text.= "\tmy \$".$p->{NAME} . "=shift;\n";

     }
   $call_params = join "," , map { "\$".$_->{NAME}} @$params;

   $text.= "\n\t$xs_name( ";
   $text.= $call_params;
   $text.=" );\n";
   $text.="}\n";
   return $text;

  }



sub xs_template
  {
   my ($ret_type, $fname, $perl_name, $params) = @_;
   my $text="";

   $text.= "$ret_type\n$perl_name ";
   $text.= " ( ";
   

   my $proto="";
   foreach my $p (@$params)
     {
      $proto.= $p->{NAME} . ", ";
     }
   $proto =~ s/,\s+$/ /;
   $text.=$proto;
   
   $text.= ")\n";
      #char *text
      foreach my $p (@$params)
	{
	 $text.= "\t";
	 $text.= $p->{TYPE} . "   ";
	 $text.= $p->{NAME} . ";\n";
	}

   #build the 'real' C call

   my $func_call=$fname."( ";

   my $param_list="";
   foreach my $p (@$params)
     {
      $param_list.= "\t";
      $param_list.= $p->{NAME} . ", ";
     }
   $param_list =~ s/,\s+$/ /;
   $func_call.=$proto;

   $func_call.= ");\n";

   
   if ($ret_type !~ /void/)
     { 
      $text.= "\tCODE:\n\t\tRETVAL = $func_call\n\tOUTPUT:\n\t\tRETVAL";
     }
   else       #void return
     {
      $text.= "\tCODE:\n\t\t$func_call\n\n";
     }
   return $text;  }

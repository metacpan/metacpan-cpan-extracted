package RPM::Info;
$VERSION = '1.05';

=pod

=head1 NAME

RPM::Info 

=head1 SYNOPSIS

	#!/usr/bin/perl -w

	use RPM::Info;

	my $rpm = new RPM::Info();
	my @rpms = ();
	my %filelist;
	my %info;
	my $dir = "";
	my $info = "";
	my @rpmreq = ();
	my $seek = "gimp-1.2.3-360";

	print "\nVer : ".$rpm->getRpmVer();

	if ($rpm->getRpms(\@rpms, "gnome") == 0)
	{
   		foreach (@rpms)
   		{
      			print "\nRPM:-> $_";
   		}
	}

	if ($rpm->getRpmFiles(\%filelist, $seek) == 0)
	{
   		foreach $dir (keys(%filelist))
   		{
      			print "\n\n\nDir : $dir";
      			foreach (@{$filelist{$dir}{'files'}})
      			{
          			print "\nFile : $_";
      			}
   		}
	}

	if ($rpm->getRpmInfo(\%info, $seek) == 0)
	{
   		print "\n\nINFOS:";
   		foreach $info (keys(%info))
   		{
      			print "\n$info : $info{$info}";
   		}
	}

	if ($rpm->getRpmRequirements(\@rpmreq, $seek) == 0)
	{
   		print "\n\nREQUIREMENTS:";
   		foreach (@rpmreq)
   		{
      			print "\n$_";
   		}
	}
	
 	if ($rpm->getRpmInfoRaw(\@rpms, "perl") == 0)
        {
                foreach (@rpms)
                {
                        print "\nRPM:-> $_";
                }
        }
        
	if ($rpm->getRpmDependents(\@rpms, "perl") == 0)
        {
                foreach (@rpms)
                {
                        print "\nRPM:-> $_";
                }
        }


=cut

=head1 DESCRIPTION

The RPM::Info module allows to get informations about installed RPM's:
it fetches:
	name,
	version, 
	requirements, 
	all files / directories containing to a RPM,
	information like vendor, distributor etc.

=head1 AUTHOR

Andreas Mahnke

=cut


use strict;                         

=head1 Methods:

=head2 new

	creates a new object of the class

=cut

sub new 
{                          
   my $class = shift;  
   my $self  = {
               }; 

   bless ($self, $class);                     
   return $self;                    
}

=head2 getRpms(result(Array Reference), search pattern(scalar))

	searches for all installed rpm's containing the search pattern
	and saves them in an Array

	if no search pattern is refered, all installed rpm's are saved

	returns 0 on succes - 1 on failure 

=cut

sub getRpms()
{
   my $self    = shift;
   my $ref     = shift;
   my $rpmseek = shift;

   if (! defined $rpmseek)
   {
      @$ref = `rpm -qa`;
   }
   else
   {
      @$ref = `rpm -qa | grep $rpmseek`;
   }
   foreach (@$ref)
   {
       chomp $_;
   }
   if ($#$ref < 0)
   {
       return 1;
   }

   return 0;
}

=head2 getRpmFiles((result(Hash Reference), rpmname(scalar))

	searches for all files and directories which belong to the refered rpm - name
	and saves them in a Hash of Hashes  

	returns 0 on succes - 1 on failure 

=cut

sub getRpmFiles()
{
   my $self    = shift;
   my $ref     = shift;
   my $rpmseek = shift;
   my $i       = 0;
   my @dirs    = ();
   my $line    = "";
   my $dir     = "";
   my @output  = `rpm -qvl $rpmseek`;
   my @line    = ();
   my @files   = ();

   undef %$ref;

   if ($#output < 0)
   {
       return 1;
   }
   foreach (@output)
   {
       chomp $_;
       @line = split(/ /,$_);
       if ($line[0] =~ m/^d/)
       {
          $dirs[$i] = $line[$#line];
          $i++;
       }
   }

   @output  = `rpm -ql $rpmseek`;
   foreach $dir (@dirs)
   {
       @files = ();
       foreach $line (@output)
       {
           chomp $line;
           @line = split(/\//,$line);
           if (($line =~ m/^$dir/) && (length($line) != length($dir))) 
           {    
               push(@files,$line[$#line]);
           }
       }
       $$ref{$dir}{'files'} = [@files];
   }
   return 0;
}

=head2 getRpmVer()

	gets the version of rpm and returns it

=cut

sub getRpmVer()
{
   my $self = shift;
   my $ver  = (`rpm --version`);
   chomp $ver;
   return $ver;
}

=head2 getRpmInfo((result(Hash Reference), rpmname(scalar))

	gets Infos about the specified rpm and saves them into 
	a Hash of Hashes

	returns 0 on succes - 1 on failure 

=cut

sub getRpmInfo()
{  
   my $self    = shift;
   my $ref     = shift;
   my $rpmseek = shift;
   my @output  = `rpm -qi $rpmseek`;
   my $line    = "";
   my $i = 0;

   undef %$ref;

   if ($#output < 0)
   {
       return 1;
   }
   
   LINE:foreach $line (@output)
   {
       if ($line =~ /(Name+).*: ([(\/\w].*.[\w\/)]) .*. (Relocations+).*: ([(\/\w].*.[\w\/)])/)
       {
	  $$ref{'name'} = $2;
          $$ref{'relocations'} =$4; 
          next LINE;
       }
       if ($line =~ /(Version+).*: ([(\/\w].*.[\w\/)]) .*. (Vendor+).*: ([(\/\w].*.[\w\/)])/)
       {
          $$ref{'version'} = $2;
          $$ref{'vendor'} =$4; 
          next LINE;
       }
       if ($line =~ /(Release+).*: ([(\/\w].*.[\w\/)]) .*. (Build Date+).*: ([(\/\w].*.[\w\/)])/)
       {
          $$ref{'release'} = $2;
          $$ref{'build_date'} =$4;     
          next LINE;
       }
       if ($line =~ /(Install date+).*: ([(\/\w].*.[\w\/)]) .*. (Build Host+).*: ([(\/\w].*.[\w\/)])/)
       {
          $$ref{'install_date'} = $2;
          $$ref{'build_host'} =$4;     
          next LINE;
       }
       if ($line =~ /(Group+).*: ([(\/\w].*.[\w\/)]) .*. (Source RPM+).*: ([(\/\w].*.[\w\/)])/)
       {
          $$ref{'group'} = $2;
          $$ref{'source_rpm'} =$4;
  	  next LINE;
       }
       if ($line =~ /(Size+).*: ([(\/\w].*.[\w\/)]) .*. (License+).*: ([(\/\w].*.[\w\/)])/)
       {
          $$ref{'size'} = $2;
          $$ref{'license'} =$4;
	  next LINE;
       }
       if ($line =~ m/(Summary+).*: ([(\/\w].*.[\w\/)])/)
       {
          $$ref{'summary'} = $2;
          next LINE;
       }
       if ($line =~ m/(URL+).*: ([(\/\w].*.[\w\/)])/)
       {
          $$ref{'url'} = $2;
          next LINE;
       }
       if ($line =~ m/(Packager+).*: ([(\/\w].*.[\w\/)])/)
       {
          $$ref{'packager'} = $2;
          next LINE;
       }
       if ($line =~ m/(Distribution+).*: ([(\/\w].*.[\w\/)])/)
       {
          $$ref{'distribution'} = $2;
          next LINE;
       }
   }
   return 0;
}

=head2 getRpmRequirements((result(Array Reference), rpmname(scalar))

	gets all the requirements of the specified rpm and saves them into an array

	returns 0 on succes - 1 on failure 

=cut

sub getRpmRequirements()
{
   my $self    = shift;
   my $ref     = shift;
   my $rpmseek = shift;
   
   @$ref  = `rpm -qR $rpmseek`;

   foreach (@$ref)
   {
       chomp $_;
   }
   if ($#$ref < 0)
   {
       return 1;
   }

   return 0;
}

=head2 getRpmInfoRaw((result(Array Reference), rpmname(scalar))

	gets Infos about the specified rpm and saves the output
	line-by-line in an array 

        returns 0 on succes - 1 on failure 

=cut

sub getRpmInfoRaw()
{
   my $self = shift;
   my $ref = shift;
   my $rpmseek = shift;
   @$ref = `rpm -qi $rpmseek`;
   foreach (@$ref)
   {
      chomp $_;
   }

   if ($#$ref < 0)
   {
      return 1;
   }
   return 0;
}

=head2 getRpmRequirements((result(Array Reference), rpmname(scalar))

        gets all the rpm names that depend on the specified rpm 
	and saves them into an array

        returns 0 on succes - 1 on failure 

=cut

sub getRpmDependents()
{
   my $self = shift;
   my $ref = shift;
   my $rpmseek = shift;

   @$ref = `rpm -q --whatrequires $rpmseek`;

   foreach (@$ref)
   {
      chomp $_;
   }
   if ($#$ref < 0)
   {
      return 1;
   } 
   return 0;
}

1;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
print "###############################################################\n";
print "# This update is NOT compatible with version 0.9 or earlier!! #\n";
print "###############################################################\n";
if ($^O =~ /linux/) {
        print "OS: $^O, copying XS file: ";
        system("cp FreeDB.xs.linux FreeDB.xs") && die "Copying failed\n";
        print "1 file copied\n";
} elsif ($^O =~ /freebsd/) {
        print "OS: $^O, copying XS file: ";
        system("cp FreeDB.xs.linux FreeDB.xs") && die "Copying failed\n";
        print "1 file copied\n";
} elsif ($^O =~ /MSWin32/) {
        print "OS: $^O, copying XS file:";
        system("copy FreeDB.xs.win32 FreeDB.xs") && die "Copying failed\n";
} else {
        print "Unable to determine OS, Exiting\n";
        exit(0);
}

#--- MY package

sub MY::libscan
{
 my($self,$path) = @_;

 return '' 
        if($path =~ m:/(RCS|CVS|SCCS)/: ||
           $path =~ m:[~%]$: ||
           $path =~ m:\.(orig|rej|nfs|h)$:
          );
 $path;
}

#--- Installation check

sub chk_version
{
 my($pkg,$wanted,$msg) = @_;

 local($|) = 1;
 print "Checking for $pkg...";

 eval { my $p; ($p = $pkg . ".pm") =~ s#::#/#g; require $p; };

 my $vstr = ${"${pkg}::VERSION"} ? "found v" . ${"${pkg}::VERSION"}
                                 : "not found";
 my $vnum = ${"${pkg}::VERSION"} || 0;

 print $vnum >= $wanted ? "ok\n" : " " . $vstr . "\n";

 $vnum >= $wanted;
}

sub MY::post_initialize
{
 my ($self) = @_;
}

#--- Check for Socket

chk_version(Net::Cmd => '2.12') or
  warn  "\n"
  . "*** For Net::FreeDB to work you require version 2.12, or later,\n"
  . "    of Net::Cmd available on CPAN\n\n"; 

chk_version(CDDB::File => '1.01') or
  warn "\n"
  . "*** For Net::FreeDB to work you require version 1.01, or later,\n"
  . "    of CDDB::File available on CPAN\n\n";
#--- Write the Makefile

WriteMakefile(
    'NAME'              => 'Net::FreeDB',
    'VERSION_FROM'      => 'FreeDB.pm', # finds $VERSION
    'PREREQ_PM'         => {
			    Moo              => 0,
			    CDDB::File       => 1.01,
			    File::Temp       => 0.05,
                IO::Socket::INET => 0,
                Net::Cmd         => 2.12,
			   }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'David Shultz <dshultz@cpan.org>, Peter Pentchev <roam@ringlet.net>',
       ABSTRACT   => 'OOP Interface to FreeDB Server(s)'
      ) : ()),
    'LIBS'              => [''], # e.g., '-lm'
    'DEFINE'            => '', # e.g., '-DHAVE_SOMETHING'
        # Insert -I. if you add *.h files later:
    'INC'               => '-Ilib', # e.g., '-I/usr/include/other'
        # Un-comment this if you add C files to link with later:
    # 'OBJECT'          => '$(O_FILES)', # link all the C files too
    'clean'		=> { 'FILES' => 'FreeDB.xs' },
);

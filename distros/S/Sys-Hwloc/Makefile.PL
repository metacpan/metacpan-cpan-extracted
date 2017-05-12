################################################################################
#
#  Copyright 2011 Zuse Institute Berlin
#
#  This package and its accompanying libraries is free software; you can
#  redistribute it and/or modify it under the terms of the GPL version 2.0,
#  or the Artistic License 2.0. Refer to LICENSE for the full license text.
#
#  Please send comments to kallies@zib.de
#
################################################################################
#
# Makefile for Sys::Hwloc
#
# $Id: Makefile.PL,v 1.24 2011/01/11 10:49:39 bzbkalli Exp $
#
################################################################################

BEGIN { require 5.006; }

use ExtUtils::MakeMaker;
use Config;
use Cwd;

%INFOS   = (
	    NAME               => 'Sys::Hwloc',
	    VERSION_FROM       => 'lib/Sys/Hwloc.pm',
	    AUTHOR             => 'Bernd Kallies <kallies@zib.de>',
	    LICENSE            => 'perl',
	    ABSTRACT           => 'Perl wrapper around the hwloc API',
	    PREREQ_PM          => {
				   'Test::More' => '0.89',
				  },
	    CONFIGURE_REQUIRES => {
				   'ExtUtils::Constant' => 0,
				  },
	   );

# ------------------------------------------------------------------------------
# Configure using pkg-config
# ------------------------------------------------------------------------------

%CONFIGS = (
	    config            => {
				  'prefix'      => '',
				  'exec_prefix' => '',
				  'libdir'      => '',
				  'includedir'  => '',
				  'iflags'      => '',
				  'libs'        => '',
				  'define'      => '',
				 },
	    HWLOC_API_VERSION => undef,
	    HWLOC_HAS_XML     => 0,
	   );

configure();

# ------------------------------------------------------------------------------
# Write makefile
# ------------------------------------------------------------------------------

delete $INFOS{CONFIGURE_REQUIRES} unless eval { ExtUtils::MakeMaker->VERSION(6.52) };
delete $INFOS{LICENSE}            unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(
 	      %INFOS,
 	      INC       => "$CONFIGS{config}->{iflags}",
	      DEFINE    => "$CONFIGS{config}->{define}",
              OPTIMIZE  => "$Config{optimize}",
	      LIBS      => "$CONFIGS{config}->{libs}",
	      PM_FILTER => "sed -e s/\@HWLOC_API_VERSION\@/$CONFIGS{HWLOC_API_VERSION}/",
	      depend    => {
			    "Hwloc.c" => "Hwloc.xs hwloc_cpuset.xsh hwloc_bitmap.xsh",
			   },
 	     );

if(eval { require ExtUtils::Constant; 1 }) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (
	       { name => 'HWLOC_OBJ_SYSTEM',                  macro => 1 },
	       { name => 'HWLOC_OBJ_MACHINE',                 macro => 1 },
	       { name => 'HWLOC_OBJ_NODE',                    macro => 1 },
	       { name => 'HWLOC_OBJ_SOCKET',                  macro => 1 },
	       { name => 'HWLOC_OBJ_CACHE',                   macro => 1 },
	       { name => 'HWLOC_OBJ_CORE',                    macro => 1 },
	       { name => 'HWLOC_OBJ_MISC',                    macro => 1 },
	       { name => 'HWLOC_TOPOLOGY_FLAG_IS_THISSYSTEM', macro => 1 },
	       { name => 'HWLOC_TOPOLOGY_FLAG_WHOLE_SYSTEM',  macro => 1 },
	       { name => 'HWLOC_TYPE_DEPTH_MULTIPLE',         macro => 1 },
	       { name => 'HWLOC_TYPE_DEPTH_UNKNOWN',          macro => 1 },
	       { name => 'HWLOC_TYPE_UNORDERED',              macro => 1 },
	       { name => 'HWLOC_HAS_XML',                     macro => 1 },
	       { name => 'HWLOC_CPUBIND_PROCESS',             macro => 1 },
	       { name => 'HWLOC_CPUBIND_THREAD',              macro => 1 },
	       { name => 'HWLOC_CPUBIND_STRICT',              macro => 1 },
	      );

  if(! $CONFIGS{HWLOC_API_VERSION}) {
    push @names, { name => 'HWLOC_OBJ_PROC',           macro => 1 };
  } else {
    push @names, { name => 'HWLOC_OBJ_GROUP',          macro => 1 };
    push @names, { name => 'HWLOC_OBJ_PU',             macro => 1 };
    if($CONFIGS{HWLOC_API_VERSION} ge '0x00010100') {
      push @names, { name => 'HWLOC_CPUBIND_NOMEMBIND',   macro => 1 };
      push @names, { name => 'HWLOC_MEMBIND_PROCESS',     macro => 1 };
      push @names, { name => 'HWLOC_MEMBIND_THREAD',      macro => 1 };
      push @names, { name => 'HWLOC_MEMBIND_STRICT',      macro => 1 };
      push @names, { name => 'HWLOC_MEMBIND_MIGRATE',     macro => 1 };
      push @names, { name => 'HWLOC_MEMBIND_NOCPUBIND',   macro => 1 };
      push @names, { name => 'HWLOC_MEMBIND_DEFAULT',     macro => 1 };
      push @names, { name => 'HWLOC_MEMBIND_FIRSTTOUCH',  macro => 1 };
      push @names, { name => 'HWLOC_MEMBIND_BIND',        macro => 1 };
      push @names, { name => 'HWLOC_MEMBIND_INTERLEAVE',  macro => 1 };
      push @names, { name => 'HWLOC_MEMBIND_REPLICATE',   macro => 1 };
      push @names, { name => 'HWLOC_MEMBIND_NEXTTOUCH',   macro => 1 };
    }
  }

  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Sys::Hwloc',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

} else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

# ------------------------------------------------------------------------------
# Assemble %CONFIGS
# ------------------------------------------------------------------------------

sub configure {

  print "checking for hwloc... ";
  my $output = `pkg-config --exists --print-errors hwloc 2>&1`;
  if($?) {
    die "no\n$output";
  } else {
    print "yes\n";
  }

  print "checking for hwloc prefix... ";
  $CONFIGS{config}->{prefix} = pkg_config_get("variable=prefix");
  print "$CONFIGS{config}->{prefix}\n";

  print "checking for hwloc eprefix... ";
  $CONFIGS{config}->{eprefix} = pkg_config_get("variable=exec_prefix");
  print "$CONFIGS{config}->{eprefix}\n";

  print "checking for hwloc includedir... ";
  $CONFIGS{config}->{includedir} = pkg_config_get("variable=includedir");
  $CONFIGS{config}->{includedir} = "$CONFIGS{config}->{eprefix}/include" if(! $CONFIGS{config}->{includedir} && $CONFIGS{config}->{eprefix});
  $CONFIGS{config}->{includedir} = "$CONFIGS{config}->{prefix}/include"  if(! $CONFIGS{config}->{includedir} && $CONFIGS{config}->{prefix});
  print "$CONFIGS{config}->{includedir}\n";

  print "checking for hwloc libdir... ";
  $CONFIGS{config}->{libdir}  = pkg_config_get("variable=libdir");
  $CONFIGS{config}->{libdir}  = "$CONFIGS{config}->{eprefix}/lib" if(! $CONFIGS{config}->{libdir} && $CONFIGS{config}->{eprefix});
  $CONFIGS{config}->{libdir}  = "$CONFIGS{config}->{prefix}/lib"  if(! $CONFIGS{config}->{libdir} && $CONFIGS{config}->{prefix});
  print "$CONFIGS{config}->{libdir}\n";

  print "checking for hwloc -I flags... ";
  $CONFIGS{config}->{iflags} = pkg_config_get("cflags-only-I");
  print "$CONFIGS{config}->{iflags}\n";

  print "checking for hwloc libs... ";
  $CONFIGS{config}->{libs} = pkg_config_get("libs");
  print "$CONFIGS{config}->{libs}\n";

  print "checking if hwloc supports hwloc_get_api_version... ";
  if(hwloc_has_func("hwloc_get_api_version")) {
    print "yes\n";
    $CONFIGS{config}->{define} .= " -DHAVE_HWLOC_GET_API_VERSION";
  } else {
    print "no\n";
  }

  print "checking if hwloc supports XML... ";
  if(hwloc_has_func("hwloc_topology_export_xml")) {
    print "yes\n";
    $CONFIGS{HWLOC_HAS_XML} = 1;
  } else {
    print "no\n";
  }
  $CONFIGS{config}->{define} .= " -DHWLOC_HAS_XML=$CONFIGS{HWLOC_HAS_XML}";

  print "checking HWLOC_API_VERSION... ";
  my $cmd  = "$Config{cpprun} -include hwloc.h";
  $cmd    .= " -I$CONFIGS{config}->{includedir}" if $CONFIGS{config}->{includedir};
  $output  = `echo HWLOC_API_VERSION | $cmd $Config{cpplast}`;
  if($?) {
    die "Failed to determine HWLOC_API_VERSION\n";
  } else {
    (my $lastword) = ($output =~ /(\S+)$/);
    die "\nFailed to determine HWLOC_API_VERSION\n" unless defined $lastword;
    if($lastword ne "HWLOC_API_VERSION") {
      $CONFIGS{HWLOC_API_VERSION} = $lastword;
      print "$CONFIGS{HWLOC_API_VERSION}\n";
    } else {
      print "(undef)\n";
    }
  }

}

# ------------------------------------------------------------------------------
# Run pkg-config for hwloc package, retrieve some info
# ------------------------------------------------------------------------------

sub pkg_config_get {
  my $what = shift;
  my $cmd  = "pkg-config --$what hwloc";
  my $data = `$cmd`;
  die "$cmd failed.\n" if $?;
  $data =~ s/[\015\012]+$//;
  return $data;
}

# ------------------------------------------------------------------------------
# See if a function is present in libhwloc.
# Needs $Config{cc} to work.
# Needs $CONFIGS{config} to be set.
# Return 1 on success, 0 on error.
# ------------------------------------------------------------------------------

sub hwloc_has_func {
  my $func = shift;
  return 0 unless $func;

  my $startDir = cwd();
  my $testDir  = '.testlink';
  my $testFile = 't.c';

  rm_fr($testDir);
  mkdir($testDir, 0777) or die "Failed to create dir $testDir: $!";
  chdir($testDir);

  open(FILE, ">$testFile") or die "Failed to write to file $testFile: $!";
  print FILE <<EOT;
char $func ();
int main () { $func (); return 0; }
EOT
  close(FILE);
  `$Config{cc} $CONFIGS{config}->{libs} $testFile >/dev/null 2>&1`;
  my $rc = $?;

  chdir($startDir);
  rm_fr($testDir);

  return $rc ? 0 : 1;
}

# ------------------------------------------------------------------------------
# rm -fr
# ------------------------------------------------------------------------------

sub rm_fr {
  my @files     = @_;
  my @realFiles = ();
  foreach(@files) {
    push @realFiles, glob($_);
  }
  foreach(@realFiles) {
    if(-d $_) {
      rm_fr("$_/*");
      rmdir($_) or die "Failed to remove $_: $!";
    } else {
      chmod(0777, $_);
      unlink($_);
    }
  }
}



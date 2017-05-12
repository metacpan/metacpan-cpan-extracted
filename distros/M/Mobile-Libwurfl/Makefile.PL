use 5.010000;
use ExtUtils::MakeMaker;

my $INC = "-I. ";
my $LIBS = "-lwurfl ";

# libwurfl is required for this module to build
my $WURFL_INCDIR = $ENV{WURFL_INCDIR};
my $WURFL_LIBDIR = $ENV{WURFL_LIBDIR};

if (!$WURFL_INCDIR) {
    my @SEARCH_INCDIRS = qw(/usr/include
                            /usr/local/include
                            /opt/include
                            /opt/local/include);
    foreach my $DIR (@SEARCH_INCDIRS) {
        if (-d "$DIR/wurfl") {
            $WURFL_INCDIR = $DIR;
            last;
        }
    }
}

if (!$WURFL_LIBDIR) {
    my @SEARCH_LIBDIRS = qw(/usr/lib
                            /usr/local/lib
                            /usr/lib64
                            /usr/local/lib64
                            /opt/lib
                            /opt/local/lib
                            /opt/lib64
                            /opt/local/lib64);
    foreach my $DIR (@SEARCH_LIBDIRS) {
        if (-f "$DIR/libwurfl.so" || -f "$DIR/libwurfl.dylib") {
            $WURFL_LIBDIR = $DIR;
            last;
        }
    }
}

if (!$WURFL_INCDIR || !$WURFL_LIBDIR) {
    die "No libwurfl installed. If installed in a custom directory ".
        "try setting the environment variables WURFL_INCDIR and WURFL_LIBDIR"
}
$INC .= "-I$WURFL_INCDIR"
    if ($WURFL_INCDIR);
$LIBS .= "-L$WURFL_LIBDIR"
    if ($WURFL_LIBDIR);


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mobile::Libwurfl',
    VERSION_FROM      => 'lib/Mobile/Libwurfl.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mobile/Libwurfl.pm', # retrieve abstract from module
       AUTHOR         => 'Andrea Guzzo <xant@xant.net>') : ()),
    LIBS              => [$LIBS],
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => $INC,
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = ({name=>"WURFL_CACHE_PROVIDER_DOUBLE_LRU", macro=>"1"},
              {name=>"WURFL_CACHE_PROVIDER_LRU", macro=>"1"},
              {name=>"WURFL_CACHE_PROVIDER_NONE", macro=>"1"},
              {name=>"WURFL_ENGINE_TARGET_HIGH_ACCURACY", macro=>"1"},
              {name=>"WURFL_ENGINE_TARGET_HIGH_PERFORMANCE", macro=>"1"},
              {name=>"WURFL_ERROR_ALREADY_LOAD", macro=>"1"},
              {name=>"WURFL_ERROR_CANT_LOAD_CAPABILITY_NOT_FOUND", macro=>"1"},
              {name=>"WURFL_ERROR_CANT_LOAD_VIRTUAL_CAPABILITY_NOT_FOUND", macro=>"1"},
              {name=>"WURFL_ERROR_CAPABILITY_GROUP_MISMATCH", macro=>"1"},
              {name=>"WURFL_ERROR_CAPABILITY_GROUP_NOT_FOUND", macro=>"1"},
              {name=>"WURFL_ERROR_CAPABILITY_NOT_FOUND", macro=>"1"},
              {name=>"WURFL_ERROR_DEVICE_ALREADY_DEFINED", macro=>"1"},
              {name=>"WURFL_ERROR_DEVICE_HIERARCHY_CIRCULAR_REFERENCE", macro=>"1"},
              {name=>"WURFL_ERROR_DEVICE_NOT_FOUND", macro=>"1"},
              {name=>"WURFL_ERROR_EMPTY_ID", macro=>"1"},
              {name=>"WURFL_ERROR_FILE_NOT_FOUND", macro=>"1"},
              {name=>"WURFL_ERROR_INPUT_OUTPUT_FAILURE", macro=>"1"},
              {name=>"WURFL_ERROR_INVALID_CAPABILITY_VALUE", macro=>"1"},
              {name=>"WURFL_ERROR_INVALID_HANDLE", macro=>"1"},
              {name=>"WURFL_ERROR_INVALID_PARAMETER", macro=>"1"},
              {name=>"WURFL_ERROR_UNEXPECTED_END_OF_FILE", macro=>"1"},
              {name=>"WURFL_ERROR_UNKNOWN", macro=>"1"},
              {name=>"WURFL_ERROR_USERAGENT_ALREADY_DEFINED", macro=>"1"},
              {name=>"WURFL_ERROR_VIRTUAL_CAPABILITY_NOT_FOUND", macro=>"1"},
              {name=>"WURFL_MATCH_TYPE_CACHED", macro=>"1"},
              {name=>"WURFL_MATCH_TYPE_CATCHALL", macro=>"1"},
              {name=>"WURFL_MATCH_TYPE_CONCLUSIVE", macro=>"1"},
              {name=>"WURFL_MATCH_TYPE_EXACT", macro=>"1"},
              {name=>"WURFL_MATCH_TYPE_HIGHPERFORMANCE", macro=>"1"},
              {name=>"WURFL_MATCH_TYPE_NONE", macro=>"1"},
              {name=>"WURFL_MATCH_TYPE_RECOVERY", macro=>"1"},
              {name=>"WURFL_OK", macro=>"1"});
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Mobile::Libwurfl',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                    );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}


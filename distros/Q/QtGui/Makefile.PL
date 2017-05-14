use 5.008;
use ExtUtils::MakeMaker;
use File::Copy;

our $prefix;
our $pkgs = 'QtGui';
my $QtCore_path;
my $vv = '4.004';

my %args = @ARGV;
$prefix = $args{-i} if defined $args{-i};

if ( $prefix and open FF, $prefix."/QtCore/qglobal.h" ) {
    # ok
}
elsif ( open FF, "/usr/local/include/QtCore/qglobal.h" ) {
    $prefix = '/usr/local/include';
}
elsif ( open FF, "/usr/include/QtCore/qglobal.h" ) {
    $prefix = '/usr/include';
}
else {
    die "Error: can not found Qt4 headers\n".
    "please read README file and point Qt4 headers location\n";
}
close FF;

if ( defined $args{-qc} ) {
    print $args{-qc};
    $QtCore_path = $args{-qc};
}



my @tpms = ('perlobject.map');
my $lb = ('-lQtCore -lpthread');
if ( $pkgs eq 'QtGui' ) {
    if ( $QtCore_path and open FF, $QtCore_path.'/classes.core' ) {
	# ok
    }
    elsif ( open FF, '../QtCore/classes.core' ) {
	$QtCore_path = '../QtCore';
    }
    elsif ( open FF, '../QtCore-'.$vv.'/classes.core' ) {
	$QtCore_path = '../QtCore-'.$vv;
    }
    else {
	die "Error: can not find *.core files from QtCore-".$vv."\n".
	"please read README file and point QtCore directory with *.core files\n";
    }

    push @tpms, 'typemap.core';
    $lb = '-lQtGui '.$lb;
    copy($QtCore_path.'/classes.core', 'classes.core') or die "Copy failed: $!";
    copy($QtCore_path.'/classes_enum.core', 'classes_enum.core') or die "Copy failed: $!";
    copy($QtCore_path.'/classes_fn_ptr.core', 'classes_fn_ptr.core') or die "Copy failed: $!";
    copy($QtCore_path.'/classes_sin_enum.core', 'classes_sin_emun.core') or die "Copy failed: $!";
    copy($QtCore_path.'/complex_type.core', 'complex_type.core') or die "Copy failed: $!";
    copy($QtCore_path.'/defined.core', 'defined.core') or die "Copy failed: $!";
    copy($QtCore_path.'/redefine.core', 'redefine.core') or die "Copy failed: $!";
    copy($QtCore_path.'/replaces.core', 'replaces.core') or die "Copy failed: $!";
    copy($QtCore_path.'/std_type.core', 'std_type.core') or die "Copy failed: $!";
    copy($QtCore_path.'/subclasses.core', 'subclasses.core') or die "Copy failed: $!";
    copy($QtCore_path.'/typemap', 'typemap.core') or die "Copy failed: $!";
}


$retval = do 'create_xs';
die "Can not parce create_xs:\n $@" if $@;
die "Can not do create_xs:\n $!" unless defined $retval;
die "Can not run create_xs" unless $retval;

$CC = 'g++';



# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => $pkgs,
    VERSION_FROM      => 'lib/'.$pkgs.'.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/'.$pkgs.'.pm', # retrieve abstract from module
       AUTHOR         => 'Vadim Likhota <vadim-lvv@yandex.ru>') : ()),
    LIBS              => [ "$lb" ], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    CC                => $CC,
    LD                => '$(CC)',
	# Insert -I. if you add *.h files later:
    INC               => '-I'.$prefix, # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES)', # link all the C files too
    XSOPT             => '-C++',
    TYPEMAPS          => \@tpms,
);

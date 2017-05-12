#!/usr/bin/perl -w
use strict;
use Config;
use ExtUtils::Embed;

eval {
    require PLSTAF;
};
if ($@ and $ENV{AUTOMATED_TESTING}) {
    print "This module won't pass automated tests unless you have STAF 3 installed";
    exit 0;
}
if ($@) {
    print "Error: can not load STAF's Perl support.\n";
    print "Please make sure that STAF 3 is installed\n";
    print "and its bin directory is in the Perl5Lib path\n";
    exit(1);
}

my $stafDir = GetStafDirFromCmdLine() || GetStafRootDir();

print_makefile($stafDir);


sub print_makefile {
    my ($stafDir) = @_;
    open my $mf, ">", "Makefile"
        or die "Can not write the Makefile!\n";
    print $mf "PERLSRV.$Config{'so'}: src/perlglue.cpp src/STAFPerlService.cpp src/synchelper.cpp\n";
    my $ccflags = ccflags();
    my $perl_include = perl_inc();
    my $src_include = create_include("./src");
    my $dyna_loader = find_dynaloader_lib();
    # create the perlxsi.c file that contain the xs_init function
    print $mf qq{\t$Config{'perlpath'} -MExtUtils::Embed -e xsinit\n};
    # compile all
    print $mf qq{\t$Config{'cc'} $ccflags $perl_include $src_include -c src/STAFPerlService.cpp src/perlglue.cpp src/synchelper.cpp perlxsi.c\n};
    # build all
    if ($Config{'lddlflags'} =~ /-dll/) {
        print "Will Link MSVC style\n";
        print $mf qq{\t$Config{'ld'} $Config{'lddlflags'} STAFPerlService$Config{'_o'} perlglue$Config{'_o'} synchelper$Config{'_o'} perlxsi$Config{'_o'} $dyna_loader STAF$Config{'_a'} $Config{'libperl'} $Config{'libs'} -def:"src/STAFPerlService.def" -out:"PERLSRV.$Config{'so'}" -libpath:"$stafDir/lib"\n};
    } elsif ($Config{'lddlflags'} =~ /-shared/) {
        print "Will Link GCC style\n";
        print $mf qq{\t$Config{'ld'} $Config{'lddlflags'} STAFPerlService$Config{'_o'} perlglue$Config{'_o'} synchelper$Config{'_o'} perlxsi$Config{'_o'} $dyna_loader -lSTAF -lperl -oPERLSRV.$Config{'so'} -L$stafDir/lib\n};
    } else {
        print "Can not identify your linking program.\n";
        print "Please edit the Makefile or write the module editor (owner\@semuel.co.il)\n";
        print $mf qq{\t$Config{'ld'} $Config{'lddlflags'} STAFPerlService$Config{'_o'} perlglue$Config{'_o'} synchelper$Config{'_o'} perlxsi$Config{'_o'} $dyna_loader -lSTAF -lperl -oPERLSRV.$Config{'so'} -L$stafDir/lib\n};
    }
    print $mf "\n";
    print $mf "install:\n";
    my $lib_prefix = $Config{libperl} =~ /^lib/ ? "lib" : "";
    print $mf "\t$Config{cp} PERLSRV.$Config{'so'} $stafDir/bin/${lib_prefix}PERLSRV.$Config{'so'}\n";
    print $mf "\n";
    print $mf "clean:\n";
    print $mf "\t$Config{'rm'} *$Config{'_o'} *$Config{'_a'} *.$Config{'so'} *.pdb *.exp perlxsi.c\n";
    print $mf "\n";
    print $mf "test:\n";
    # test normal operation. loading a service, request, unloading
    print $mf "\t$Config{'perlpath'} t/01.pl\n";
    # test a service that return an error in the request operation
    print $mf "\t$Config{'perlpath'} t/02.pl\n";
    # test a service that dies in the request operation
    print $mf "\t$Config{'perlpath'} t/03.pl\n";
    # test a service that fails to compile
    print $mf "\t$Config{'perlpath'} t/04.pl\n";
    # test a sevice that is under a directory. dir::Service
    print $mf "\t$Config{'perlpath'} t/05.pl\n";
    # test a service that inherate from other service
    print $mf "\t$Config{'perlpath'} t/06.pl\n";
    # test a service that dies in the new function
    print $mf "\t$Config{'perlpath'} t/07.pl\n";
    # test threaded response
    print $mf "\t$Config{'perlpath'} t/08.pl\n";
    # test fire-and-forget many requests
    print $mf "\t$Config{'perlpath'} t/09.pl\n";
    print $mf "\n";
    print "Makefile was written\n";
}

sub find_dynaloader_lib {
    # Code taken from XSLoader.pm
    require DynaLoader;
    my $module = 'DynaLoader';
    my $lib_ext = $Config{'_a'};
    print "Searching for DynaLoader$lib_ext... ";

    my $modlibname = $INC{$module.".pm"};
    $modlibname =~ s,[\\/][^\\/]+$,,;	# Q&D basename
    my $file = "$modlibname/auto/$module/$module$lib_ext";
    if (not -f $file) {
        print "not found. (normal for ActiveState dist.)\n";
        return '';
    } else {
        print "found.\n";
        return $file;
    }
}

sub create_include {
    my $dir = shift;
    $dir = qq["$dir"] if $^O eq 'MSWin32';
    return(" -I$dir ");
}

sub GetStafDirFromCmdLine {
    my ($dirparam) = grep /^-stafdir=/, @ARGV;
    return unless defined $dirparam;

    my ($dir) = $dirparam =~ /=(.*)/;
    return unless -d $dir && -d $dir."/bin";
    return $dir if -e $dir."/bin/staf.cfg";
    return;
}

sub GetStafRootDir {
    my $handle = STAF::STAFHandle->new("My program"); 
    if ($handle->{rc} != $STAF::kOk) { 
        print "Error registering with STAF, RC: $handle->{rc}\n";
        print "Please make sure that STAF is currently running on your machine\n";
        exit(1); 
    } 
    
    my $result = $handle->submit("local", "VAR", "resolve string {STAF/Config/STAFRoot}"); 
    if ($result->{rc} != $STAF::kOk) { 
        print "Error getting STAF home, RC: $result->{rc}\n"; 
        if (length($result->{result}) != 0) { 
            print "Additional info: $result->{result}\n"; 
        } 
        exit(1); 
    } 
    
    my $StafRoot = $result->{result}; 
    
    $handle->unRegister();
    
    return $StafRoot;
}

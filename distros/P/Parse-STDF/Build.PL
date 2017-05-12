#!/usr/bin/env perl
#  Copyright (C) 2014 Erick Jordan <ejordan@cpan.org>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Module::Build;
use Config;

my $LIBSTDF_CONFIG = "libstdf-config";
my $MIN_SWIG_VERSION = version->parse("2.0.4");
my $MIN_LIBSTDF_VERSION = version->parse("0.4");

check_libstdf();

my $class = Module::Build->subclass( class => 'MyModuleBuild',
    code => q!
        use File::Basename;
        use Data::Dumper;
        sub process_swig_files {
            my $self = shift;
            my $verb = $self->runtime_params('verbose');
            $verb = 0 if $self->runtime_params('quiet');
            #my @p = @_;
            print "process swig files\n" if $verb;
            my $swigdeps = $self->config('swig_source');
            my @swig_flags = $self->split_like_shell($self->config('swig_flags'));
            my @swigsource = keys %$swigdeps;
            my $lib = 'lib';
            #my $blib_lib = File::Spec->catfile('blib', 'lib');
            foreach my $file (@swigsource) {
                #FIXME add dir $self->config('swig_files')
                my $basename = basename($file, '.swg');
                my $cfile = $basename."_wrap.c";
                my $pmfile = File::Spec->catfile($lib,"$basename.pm");
                if ($self->up_to_date($swigdeps->{$file}, $cfile) &&
                    $self->up_to_date($swigdeps->{$file}, $pmfile)) {
                    next if $self->up_to_date($file, $cfile) && 
                        $self->up_to_date($cfile, $pmfile);
                }
                print "swig: $file -> $cfile\n" if $verb;
                $self->do_system('swig', '-o', $cfile, '-perl', '-outdir',
                    $lib, @swig_flags, $file);
                $self->copy_if_modified(from => $pmfile, to_dir => 'blib');
            }
            return 1;
        }
        sub process_c_files {
            my $self = shift;
            my $verb = $self->runtime_params('verbose');
            $verb = 0 if $self->runtime_params('quiet');
            #my @p = @_;
            print "process c files\n" if $verb;
            my $cfiles = $self->rscan_dir('./',qr/\.c$/);
            # if none return
            #set $self->quiet() for CBuilder->new
            $self->quiet($verb?0:1);
            my $cb = $self->cbuilder(); # get a ExtUtils::CBuilder object
            print "  CBuilder: ",$cb->VERSION,"\n" if $verb;
            #setenv TMPDIR for cc ??
            foreach my $file (@$cfiles) {
                my $basename = basename($file, '_wrap.c');
                $basename = basename($file, '.c') if not defined $basename;
                my $libname = $basename.".".$self->config('dlext');
                $libname = File::Spec->catfile('blib', 'arch',$libname);
                next if $self->up_to_date($file,$libname); 
                print "(CC) $file -> $basename.so\n" if $verb;
                my $obj = $cb->compile(source => $file, 
                    ## include_dirs => $self->config('include_dirs'),
                    extra_compiler_flags => $self->config('extra_compiler_flags'));
                print "CB compiled: $obj\n" if $verb;
                my $lib = $cb->link(objects => $obj,
                    extra_linker_flags => $self->config('extra_linker_flags'));
                print "CB generated: $lib\n" if $verb;
                $self->copy_if_modified(from => $lib, to => $libname);
            }
            return 1;
        }
    !);
#



my $build = $class->new( 
    module_name         => 'Parse::STDF',
    configure_requires  => { 'Module::Build' => 0.38 },
    create_makefile_pl  => 'small',
    dist_abstract       => 
    'Parse files in Standard Test Data Format into Perl objects',
    dist_author         => 'Erick Jordan  <ejordan@cpan.org>',
    dist_version_from   => 'lib/Parse/STDF.pm',
    license             => 'gpl',
    needs_compiler      => 1,
    release_status      => 'stable',
	requires => {
	  'Test::More'          => 0,
	  'version'             => 0,
	  'ExtUtils::CBuilder'  => '0.28'
	},
    get_options => {
	                 extra_ldflags => { type => '=s' },
					 extra_ccflags => { type => '=s' },
	               }
);

$build->config(swig_files          => './');
$build->config(swig_source => {   # with dependencies as hash value
    'swig/libstdf.swg' => ['swig/funcs.swg', 'swig/typemaps.swg']
	} );

if($build->have_c_compiler()) {
    $build->notes('c_compiler' => 1);
    print "C compiler found - check swig\n" if $build->config('verbose');
    if(!$build->config('obj_ext')) {
        $build->config('obj_ext','.o');
    }
    if(!$build->config('dlext')) {
        $build->config('dlext','so');
    }
    my $swig_installed = check_swig(
        verbose => $build->config('verbose'));
    $build->notes(swig_installed => $swig_installed);
    my ($ccflags, $ldflags,$swig_flags) = check_c_compiler(
        $build->config('cc'), $build->config('ccflags'));

    # Add command line options here:

    $ldflags .= ' '.$build->args('extra_ldflags') if ( defined( $build->args('extra_ldflags') ) );
    $ccflags .= ' '.$build->args('extra_ccflags') if ( defined( $build->args('extra_ccflags') ) );

    $build->config(extra_linker_flags  => $ldflags);
    $build->config(extra_compiler_flags => $ccflags);
    if($swig_installed) {
        $build->config(swig_flags => $swig_flags);
        $build->add_build_element('swig');
#        $build->add_to_cleanup('lib/libstdf.pm','*.c');
    }
    $build->add_build_element('c');
    $build->add_to_cleanup('*.o','*.so','tmp*',);
    my @el = @{$build->build_elements};
    my $i = grep {$el[$_] eq 'c'} 0..$#el;
    unshift @el, splice @el, $i, 1;
    @el = @{$build->build_elements};
    $i = grep {$el[$_] eq 'swig'} 0..$#el;
    unshift @el, splice @el, $i, 1;
}

$build->create_build_script();

exit;

sub check_c_compiler 
{
    my $cc= shift;
    my $swig_flags=  ' '.get_libstdf_cflags();
    my $ccflags = ' '.get_libstdf_cflags();
	my $ldflags = ' '.get_libstdf_libs();
	my $rpath = ( $ldflags =~ /-L(.+?)\s+/ ) ? $1 : "";
	$ccflags .= " -std=c99";
	$ldflags .= " -Xlinker -rpath $rpath";
	return ($ccflags, $ldflags, $swig_flags);
}


sub try_compile {
    my ($c, %args) = @_;

    my $ok = 0;
    my $tmp = "tmp$$";
    local(*TMPC);

    my $obj_ext = $build->config('obj_ext') || ".o";
    unlink("$tmp.c", "$tmp$obj_ext");

    if (open(TMPC, ">", "$tmp.c")) {
	print TMPC $c;
	close(TMPC);

	my $cccmd = $build->config('cc');
	my $errornull;
	my $ccflags = $build->config('ccflags');
        $ccflags .= " $args{ccflags}" if $args{ccflags};

        if ($args{silent} ) {
	    $errornull = "2>/dev/null" unless defined $errornull;
	} else {
	    $errornull = '';
	}

    $cccmd = "$cccmd -o $tmp $ccflags $tmp.c $errornull";

	printf "cccmd = $cccmd\n" if $args{verbose};
	my $res = system($cccmd);
	$ok = defined($res) && $res == 0;

	if ( !$ok ) {
	    my $errno = $? >> 8;
	    local $! = $errno;
	    print "
		
*** The test compile of '$tmp.c' failed: status $?
*** (the status means: errno = $errno or '$!')
*** DO NOT PANIC: this just means that *some* you may get some innocuous
*** compiler warnings.
";
	}
	unlink("$tmp.c");

    }
    return $ok;
}

sub try_cflags ($) {
    my ($ccflags) = @_;
    my $c_prog = "int main () { return 0; }\n";
    print "Checking if ",$build->config('cc')," supports \"$ccflags\"...";
    my $result = try_compile($c_prog, ccflags=>$ccflags);
    if ($result) {
	print "yes\n";
	return " $ccflags";
    }
    print "no\n";
    return '';
	
}


sub check_swig
{
  print "Checking for SWIG...";
  my $swig_cmd = `swig -version`;
  if ($?)
  {
    my $errno = $? >> 8;
	printf ("\n");
    printf (" *** I don't see SWIG installed. I'll use the SWIG-generated file\n");
    printf (" *** that comes with the distribution. If you want SWIG, get it\n");
    printf (" *** from http://www.swig.org\n");
    return(0);
  }
  my $swig_version;
  if ( $swig_cmd =~ m{(\d+)\.(\d+)\.(\d+)} )
  {
    $swig_version = version->parse("$1\.$2\.$3");
  }
  else
  {
    die "\nERROR: could not find swig version\n";
  }
  if ( $swig_version < $MIN_SWIG_VERSION ) 
  {
	printf ("\n");
    printf (" *** You need to have swig %s or greater installed. (You have %s).\n", $MIN_SWIG_VERSION,$swig_version);
    printf (" *** I'll use the SWIG-generated file that comes with the distribution.\n");
	printf (" *** If you want SWIG, get it from http://www.swig.org\n");
	return(0);
  }

  print " good, version $swig_version installed\n";
  return(1);
}


sub check_libstdf 
{
  print "Checking for libstdf ... ";
  my $libstdf_version = `$LIBSTDF_CONFIG --version 2>&1`;
  if ($?) 
  {
    my $errno = $? >> 8;
	die "\nERROR: I don't see libstdf installed.  \n".
	    "Please ensure libstdf is installed and $LIBSTDF_CONFIG is in your search path.  \n".
		"Get libstdf from http://freestdf.sourceforge.net/\n";
  }
  $libstdf_version =~ s/^\s+//g;
  $libstdf_version =~ s/\s+$//g;
  if ( $libstdf_version < $MIN_LIBSTDF_VERSION ) 
  {
    die "\nERROR: libstdf version $MIN_LIBSTDF_VERSION or greater must be installed.  You have $libstdf_version.\n".
        "Get libstdf $MIN_LIBSTDF_VERSION from http://freestdf.sourceforge.net/\n";
  }
  printf "good, version $libstdf_version installed\n";
}


sub get_libstdf_prefix # ()
{
  my $prefix = `$LIBSTDF_CONFIG --prefix`;
  $prefix =~ s/^\s+//g;
  $prefix =~ s/\s+$//g;
  return ( $prefix );
}

sub get_libstdf_cflags # ()
{
  my $cflags = `$LIBSTDF_CONFIG --cflags`;
  $cflags =~ s/^\s+//g;
  $cflags =~ s/\s+$//g;
  return ( $cflags );
}

sub get_libstdf_libs # ()
{
  my $libs = `$LIBSTDF_CONFIG --libs`;
  $libs =~ s/^\s+//g;
  $libs =~ s/\s+$//g;
  return ( $libs );
}

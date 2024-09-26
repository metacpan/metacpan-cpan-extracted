use strict;
use warnings;
use Module::Build;
use Config;

my $VERSION = '3.04';

# On OSX we need to restrict the exported symbols in the bundle
# to prevent NDF linking against libast clashing with NDF loading
# Starlink::AST
my $linkflags = "";
if ($^O eq 'darwin') {
  $linkflags = "-exported_symbols_list exported_symbols.lis";
}

# On MSWin32 we are getting test failures indicating that sscanf
# is not working. Experiment with using the internal sscanf implementation.
my @defines;
if ($^O eq 'MSWin32') {
  push(@defines, "-DHAVE_NONANSI_SSCANF=1",
                 "-Dcminpack_EXPORTS");
}

my $class = Module::Build->subclass(code => <<'EOF');
    sub ACTION_prepare {
        my $self = shift;
        return if -e 'ast';
        my $orig = Cwd::getcwd();
        chdir('extsrc');
        $self->do_system('./bootstrap');
        $self->do_system('./configure');
        $self->do_system('make', $_) foreach qw/
            AST_ERR ast_err.h ast.h fac_1521_err/;
        chdir($orig);
        my %exclude = map {$_ => 1} (qw/
            ast_test.c config.h err_drama.c err_ems.c err_null.c
            grf_2.0.c grf_3.2.c grf3d_pgplot.c grf_5.6.c grf_null.c grf_pgplot.c
            huge.c stcschan-demo1.c stcschan-demo2.c stcschan-demo3.c
            stcschan-demo4.c stcschan-demo5.c templateclass.c templateclass.h
        /);
        my %include = map {$_ => 1} (qw/
            aclocal.m4 ast_cpp.in AST_ERR ast_err.h ast.h
            ast_link_adam ast_link_adam.in ast_link.in ast.news ast_par.source
            component.xml.in config.h.in configure configure.ac COPYING
            COPYING.LESSER COPYING.LIB f77.h.in fac_1521_err fitschan.c
            fitstable.c fluxframe.c frame.c frameset.c GRF_PAR
            Makefile.am Makefile.in makeh object.h.in
        /);
        foreach my $path (@{$self->rscan_dir('extsrc', sub {-f})}) {
            my (undef, $dir, $file) = File::Spec->splitpath($path);
            my (undef, @dir) = File::Spec->splitdir($dir);
            my $dirname = join('/', grep {$_ ne ''} @dir);
            if (($dirname eq 'cminpack')
                or ((grep {$_ eq $dirname} ('', qw/src wcslib/)) and (not $exclude{$file}) and (
                    $include{$file}
                    or $file =~ '^[^f].*\.c$'
                    or $file =~ '^.*\.h$'
            ))) {
                $self->copy_if_modified(from => $path, to => File::Spec->catfile('ast', @dir, $file));
            }
        }
    }
    sub ACTION_realclean {
        my $self = shift;
        $self->delete_filetree('ast');
        $self->SUPER::ACTION_realclean(@_);
    }
    sub ACTION_code {
        my $self = shift;
        $self->depends_on('prepare');
        $self->SUPER::ACTION_code(@_);
    }
    sub ACTION_dist {
        my $self = shift;
        $self->depends_on('prepare');
        $self->SUPER::ACTION_dist(@_);
    }
    sub ACTION_manifest {
        my $self = shift;
        $self->depends_on('prepare');
        $self->SUPER::ACTION_manifest(@_);
    }
EOF

my $build = $class->new
  (
   module_name => "Starlink::AST",
   dist_version => $VERSION,
   license => "gpl2",
   author => [
              'Tim Jenness <tjenness@cpan.org>',
             ],
   meta_merge => {
               resources =>  {
                              repository => 'https://github.com/Starlink/perl-Starlink-AST.git',
                             },
                },
   recommends => {
                  "Tk" => 0,
                  "Tk::Zinc" => 0,
                  "Astro::FITS::CFITSIO" => 0,
                  "Astro::FITS::Header" => 0,
                 },
   build_requires => {
                      "perl" => 5.008,
                      "Test::More" => 0,
                      "Test::Deep" => 0,
                      "Test::Number::Delta" => 0,
                     },
   configure_requires => {
                          "Module::Build" => 0.3604,
                         },
   c_source => [ "src", "ast" ],
   extra_compiler_flags => [ "-Iextsrc", # we do not build these directly
                             "-DHAVE_DECL_ISNAN=1", # Assume we have NaN
                             "-DSIZEOF_LONG=". $Config{longsize},
                             "-DSIZEOF_LONG_LONG=". $Config{longlongsize},
                             '-DHAVE_INT64_T=1',
                             '-DHAVE_UINT64_T=1',
                             "-DPACKAGE_STRING=\"Starlink::AST $VERSION\"",
                             @defines,
                           ],
   extra_linker_flags => $linkflags,
  );

$build->create_build_script;


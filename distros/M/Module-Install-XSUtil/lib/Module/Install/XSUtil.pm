package Module::Install::XSUtil;

use 5.005_03;

$VERSION = '0.45';

use Module::Install::Base;
@ISA     = qw(Module::Install::Base);

use strict;

use Config;

use File::Spec;
use File::Find;

use constant _VERBOSE => $ENV{MI_VERBOSE} ? 1 : 0;

my %ConfigureRequires = (
    'ExtUtils::ParseXS' => 3.18, # shipped with Perl 5.18.0
);

my %BuildRequires = (
);

my %Requires = (
    'XSLoader' => 0.02,
);

my %ToInstall;

my $UseC99       = 0;
my $UseCplusplus = 0;

sub _verbose{
    print STDERR q{# }, @_, "\n";
}

sub _xs_debugging{
    return $ENV{XS_DEBUG} || scalar( grep{ $_ eq '-g' } @ARGV );
}

sub _xs_initialize{
    my($self) = @_;

    unless($self->{xsu_initialized}){
        $self->{xsu_initialized} = 1;

        if(!$self->cc_available()){
            warn "This distribution requires a C compiler, but it's not available, stopped.\n";
            exit;
        }

        $self->configure_requires(%ConfigureRequires);
        $self->build_requires(%BuildRequires);
        $self->requires(%Requires);

        $self->makemaker_args->{OBJECT} = '$(O_FILES)';
        $self->clean_files('$(O_FILES)');
        $self->clean_files('*.stackdump') if $^O eq 'cygwin';

        if($self->_xs_debugging()){
            # override $Config{optimize}
            if(_is_msvc()){
                $self->makemaker_args->{OPTIMIZE} = '-Zi';
            }
            else{
                $self->makemaker_args->{OPTIMIZE} = '-g -ggdb -g3';
            }
            $self->cc_define('-DXS_ASSERT');
        }
    }
    return;
}

# GNU C Compiler
sub _is_gcc{
    return $Config{gccversion};
}

# Microsoft Visual C++ Compiler (cl.exe)
sub _is_msvc{
    return $Config{cc} =~ /\A cl \b /xmsi;
}

{
    my $cc_available;

    sub cc_available {
        return defined $cc_available ?
            $cc_available :
            ($cc_available = shift->can_cc())
        ;
    }

    # cf. https://github.com/sjn/toolchain-site/blob/219db464af9b2f19b04fec05547ac10180a469f3/lancaster-consensus.md
    my $want_xs;
    sub want_xs {
        my($self, $default) = @_;
        return $want_xs if defined $want_xs;

        # you're using this module, you must want XS by default
        # unless PERL_ONLY is true.
        $default = !$ENV{PERL_ONLY} if not defined $default;

        foreach my $arg(@ARGV){

            my ($k, $v) = split '=', $arg; # MM-style named args
            if ($k eq 'PUREPERL_ONLY' && defined $v) {
                return $want_xs = !$v;
            }
            elsif($arg eq '--pp'){ # old-style
                return $want_xs = 0;
            }
            elsif($arg eq '--xs'){
                return $want_xs = 1;
            }
        }

        if ($ENV{PERL_MM_OPT}) {
            my($v) = $ENV{PERL_MM_OPT} =~ /\b PUREPERL_ONLY = (\S+) /xms;
            if (defined $v) {
                return $want_xs = !$v;
            }
        }

        return $want_xs = $default;
    }
}

sub use_ppport{
    my($self, $dppp_version) = @_;
    return if $self->{_ppport_ok}++;

    $self->_xs_initialize();

    my $filename = 'ppport.h';

    $dppp_version ||= 3.19; # the more, the better
    $self->configure_requires('Devel::PPPort' => $dppp_version);
    $self->build_requires('Devel::PPPort' => $dppp_version);

    print "Writing $filename\n";

    my $e = do{
        local $@;
        eval qq{
            use Devel::PPPort;
            Devel::PPPort::WriteFile(q{$filename});
        };
        $@;
    };
    if($e){
         print "Cannot create $filename because: $@\n";
    }

    if(-e $filename){
        $self->clean_files($filename);
        $self->cc_define('-DUSE_PPPORT');
        $self->cc_append_to_inc('.');
    }
    return;
}

sub use_xshelper {
    my($self, $opt) = @_;
    $self->_xs_initialize();
    $self->use_ppport();

    my $file = 'xshelper.h';
    open my $fh, '>', $file or die "Cannot open $file for writing: $!";
    print $fh $self->_xshelper_h();
    close $fh or die "Cannot close $file: $!";
    if(defined $opt) {
        if($opt eq '-clean') {
            $self->clean_files($file);
        }
        else {
            $self->realclean_files($file);
        }
    }
    return;
}

sub _gccversion {
    my $res = `$Config{cc} --version`;
    my ($version) = $res =~ /\(GCC\) ([0-9.]+)/;
    no warnings 'numeric', 'uninitialized';
    return sprintf '%g', $version;
}

sub cc_warnings{
    my($self) = @_;

    $self->_xs_initialize();

    if(_is_gcc()){
        $self->cc_append_to_ccflags(qw(-Wall));

        my $gccversion = _gccversion();
        if($gccversion >= 4.0){
            $self->cc_append_to_ccflags(qw(-Wextra));
            if(!($UseC99 or $UseCplusplus)) {
                # Note: MSVC++ doesn't support C99,
                # so -Wdeclaration-after-statement helps
                # ensure C89 specs.
                $self->cc_append_to_ccflags(qw(-Wdeclaration-after-statement));
            }
            if($gccversion >= 4.1 && !$UseCplusplus) {
                $self->cc_append_to_ccflags(qw(-Wc++-compat));
            }
        }
        else{
            $self->cc_append_to_ccflags(qw(-W -Wno-comment));
        }
    }
    elsif(_is_msvc()){
        $self->cc_append_to_ccflags(qw(-W3));
    }
    else{
        # TODO: support other compilers
    }

    return;
}

sub c99_available {
    my($self) = @_;

    return 0 if not $self->cc_available();

    require File::Temp;
    require File::Basename;

    my $tmpfile = File::Temp->new(SUFFIX => '.c');

    $tmpfile->print(<<'C99');
// include a C99 header
#include <stdbool.h>
inline // a C99 keyword with C99 style comments
int test_c99() {
    int i = 0;
    i++;
    int j = i - 1; // another C99 feature: declaration after statement
    return j;
}
C99

    $tmpfile->close();

    system "$Config{cc} -c " . $tmpfile->filename;

    (my $objname = File::Basename::basename($tmpfile->filename)) =~ s/\Q.c\E$/$Config{_o}/;
    unlink $objname or warn "Cannot unlink $objname (ignored): $!";

    return $? == 0;
}

sub requires_c99 {
    my($self) = @_;
    if(!$self->c99_available) {
        warn "This distribution requires a C99 compiler, but $Config{cc} seems not to support C99, stopped.\n";
        exit;
    }
    $self->_xs_initialize();
    $UseC99 = 1;
    return;
}

sub requires_cplusplus {
    my($self) = @_;
    if(!$self->cc_available) {
        warn "This distribution requires a C++ compiler, but $Config{cc} seems not to support C++, stopped.\n";
        exit;
    }
    $self->_xs_initialize();
    $UseCplusplus = 1;
    return;
}

sub cc_append_to_inc{
    my($self, @dirs) = @_;

    $self->_xs_initialize();

    for my $dir(@dirs){
        unless(-d $dir){
            warn("'$dir' not found: $!\n");
        }

        _verbose "inc: -I$dir" if _VERBOSE;
    }

    my $mm    = $self->makemaker_args;
    my $paths = join q{ }, map{ s{\\}{\\\\}g; qq{"-I$_"} } @dirs;

    if($mm->{INC}){
        $mm->{INC} .=  q{ } . $paths;
    }
    else{
        $mm->{INC}  = $paths;
    }
    return;
}

sub cc_libs {
    my ($self, @libs) = @_;

    @libs = map{
        my($name, $dir) = ref($_) eq 'ARRAY' ? @{$_} : ($_, undef);
        my $lib;
        if(defined $dir) {
            $lib = ($dir =~ /^-/ ? qq{$dir } : qq{-L$dir });
        }
        else {
            $lib = '';
        }
        $lib .= ($name =~ /^-/ ? qq{$name} : qq{-l$name});
        _verbose "libs: $lib" if _VERBOSE;
        $lib;
    } @libs;

    $self->cc_append_to_libs( @libs );
}

sub cc_append_to_libs{
    my($self, @libs) = @_;

    $self->_xs_initialize();

    return unless @libs;

    my $libs = join q{ }, @libs;

    my $mm = $self->makemaker_args;

    if ($mm->{LIBS}){
        $mm->{LIBS} .= q{ } . $libs;
    }
    else{
        $mm->{LIBS} = $libs;
    }
    return $libs;
}

sub cc_assert_lib {
    my ($self, @dcl_args) = @_;

    if ( ! $self->{xsu_loaded_checklib} ) {
        my $loaded_lib = 0;
        foreach my $checklib (qw(inc::Devel::CheckLib Devel::CheckLib)) {
            eval "use $checklib 0.4";
            if (!$@) {
                $loaded_lib = 1;
                last;
            }
        }

        if (! $loaded_lib) {
            warn "Devel::CheckLib not found in inc/ nor \@INC";
            exit 0;
        }

        $self->{xsu_loaded_checklib}++;
        $self->configure_requires( "Devel::CheckLib" => "0.4" );
        $self->build_requires( "Devel::CheckLib" => "0.4" );
    }

    Devel::CheckLib::check_lib_or_exit(@dcl_args);
}

sub cc_append_to_ccflags{
    my($self, @ccflags) = @_;

    $self->_xs_initialize();

    my $mm    = $self->makemaker_args;

    $mm->{CCFLAGS} ||= $Config{ccflags};
    $mm->{CCFLAGS}  .= q{ } . join q{ }, @ccflags;
    return;
}

sub cc_define{
    my($self, @defines) = @_;

    $self->_xs_initialize();

    my $mm = $self->makemaker_args;
    if(exists $mm->{DEFINE}){
        $mm->{DEFINE} .= q{ } . join q{ }, @defines;
    }
    else{
        $mm->{DEFINE}  = join q{ }, @defines;
    }
    return;
}

sub requires_xs_module {
    my $self  = shift;

    return $self->requires() unless @_;

    $self->_xs_initialize();

    my %added = $self->requires(@_);
    my(@inc, @libs);

    my $rx_lib    = qr{ \. (?: lib | a) \z}xmsi;
    my $rx_dll    = qr{ \. dll          \z}xmsi; # for Cygwin

    while(my $module = each %added){
        my $mod_basedir = File::Spec->join(split /::/, $module);
        my $rx_header = qr{\A ( .+ \Q$mod_basedir\E ) .+ \. h(?:pp)?     \z}xmsi;

        SCAN_INC: foreach my $inc_dir(@INC){
            my @dirs = grep{ -e } File::Spec->join($inc_dir, 'auto', $mod_basedir), File::Spec->join($inc_dir, $mod_basedir);

            next SCAN_INC unless @dirs;

            my $n_inc = scalar @inc;
            find(sub{
                if(my($incdir) = $File::Find::name =~ $rx_header){
                    push @inc, $incdir;
                }
                elsif($File::Find::name =~ $rx_lib){
                    my($libname) = $_ =~ /\A (?:lib)? (\w+) /xmsi;
                    push @libs, [$libname, $File::Find::dir];
                }
                elsif($File::Find::name =~ $rx_dll){
                    # XXX: hack for Cygwin
                    my $mm = $self->makemaker_args;
                    $mm->{macro}->{PERL_ARCHIVE_AFTER} ||= '';
                    $mm->{macro}->{PERL_ARCHIVE_AFTER}  .= ' ' . $File::Find::name;
                }
            }, @dirs);

            if($n_inc != scalar @inc){
                last SCAN_INC;
            }
        }
    }

    my %uniq = ();
    $self->cc_append_to_inc (grep{ !$uniq{ $_ }++ } @inc);

    %uniq = ();
    $self->cc_libs(grep{ !$uniq{ $_->[0] }++ } @libs);

    return %added;
}

sub cc_src_paths{
    my($self, @dirs) = @_;

    $self->_xs_initialize();

    return unless @dirs;

    my $mm     = $self->makemaker_args;

    my $XS_ref = $mm->{XS} ||= {};
    my $C_ref  = $mm->{C}  ||= [];

    my $_obj   = $Config{_o};

    my @src_files;
    find(sub{
        if(/ \. (?: xs | c (?: c | pp | xx )? ) \z/xmsi){ # *.{xs, c, cc, cpp, cxx}
            push @src_files, $File::Find::name;
        }
    }, @dirs);

    my $xs_to = $UseCplusplus ? '.cpp' : '.c';
    foreach my $src_file(@src_files){
        my $c = $src_file;
        if($c =~ s/ \.xs \z/$xs_to/xms){
            $XS_ref->{$src_file} = $c;

            _verbose "xs: $src_file" if _VERBOSE;
        }
        else{
            _verbose "c: $c" if _VERBOSE;
        }

        push @{$C_ref}, $c unless grep{ $_ eq $c } @{$C_ref};
    }

    $self->clean_files(map{
        File::Spec->catfile($_, '*.gcov'),
        File::Spec->catfile($_, '*.gcda'),
        File::Spec->catfile($_, '*.gcno'),
    } @dirs);
    $self->cc_append_to_inc('.');

    return;
}

sub cc_include_paths{
    my($self, @dirs) = @_;

    $self->_xs_initialize();

    push @{ $self->{xsu_include_paths} ||= []}, @dirs;

    my $h_map = $self->{xsu_header_map} ||= {};

    foreach my $dir(@dirs){
        my $prefix = quotemeta( File::Spec->catfile($dir, '') );
        find(sub{
            return unless / \.h(?:pp)? \z/xms;

            (my $h_file = $File::Find::name) =~ s/ \A $prefix //xms;
            $h_map->{$h_file} = $File::Find::name;
        }, $dir);
    }

    $self->cc_append_to_inc(@dirs);

    return;
}

sub install_headers{
    my $self    = shift;
    my $h_files;
    if(@_ == 0){
        $h_files = $self->{xsu_header_map} or die "install_headers: cc_include_paths not specified.\n";
    }
    elsif(@_ == 1 && ref($_[0]) eq 'HASH'){
        $h_files = $_[0];
    }
    else{
        $h_files = +{ map{ $_ => undef } @_ };
    }

    $self->_xs_initialize();

    my @not_found;
    my $h_map = $self->{xsu_header_map} || {};

    while(my($ident, $path) = each %{$h_files}){
        $path ||= $h_map->{$ident} || File::Spec->join('.', $ident);
        $path   = File::Spec->canonpath($path);

        unless($path && -e $path){
            push @not_found, $ident;
            next;
        }

        $ToInstall{$path} = File::Spec->join('$(INST_ARCHAUTODIR)', $ident);

        _verbose "install: $path as $ident" if _VERBOSE;
        my @funcs = $self->_extract_functions_from_header_file($path);
        if(@funcs){
            $self->cc_append_to_funclist(@funcs);
        }
    }

    if(@not_found){
        die "Header file(s) not found: @not_found\n";
    }

    return;
}

my $home_directory;

sub _extract_functions_from_header_file{
    my($self, $h_file) = @_;

    my @functions;

    ($home_directory) = <~> unless defined $home_directory;

    # get header file contents through cpp(1)
    my $contents = do {
        my $mm = $self->makemaker_args;

        my $cppflags = q{"-I}. File::Spec->join($Config{archlib}, 'CORE') . q{"};
        $cppflags    =~ s/~/$home_directory/g;

        $cppflags   .= ' ' . $mm->{INC} if $mm->{INC};

        $cppflags   .= ' ' . ($mm->{CCFLAGS} || $Config{ccflags});
        $cppflags   .= ' ' . $mm->{DEFINE} if $mm->{DEFINE};

        my $add_include = _is_msvc() ? '-FI' : '-include';
        $cppflags   .= ' ' . join ' ',
            map{ qq{$add_include "$_"} } qw(EXTERN.h perl.h XSUB.h);

        my $cppcmd = qq{$Config{cpprun} $cppflags $h_file};
        # remove all the -arch options to workaround gcc errors:
        #       "-E, -S, -save-temps and -M options are not allowed
        #        with multiple -arch flags"
        $cppcmd =~ s/ -arch \s* \S+ //xmsg;
        _verbose("extract functions from: $cppcmd") if _VERBOSE;
        `$cppcmd`;
    };

    unless(defined $contents){
        die "Cannot call C pre-processor ($Config{cpprun}): $! ($?)";
    }

    # remove other include file contents
    my $chfile = q/\# (?:line)? \s+ \d+ /;
    $contents =~ s{
        ^$chfile  \s+ (?!"\Q$h_file\E")
        .*?
        ^(?= $chfile)
    }{}xmsig;

    if(_VERBOSE){
        local *H;
        open H, "> $h_file.out"
            and print H $contents
            and close H;
    }

    while($contents =~ m{
            ([^\\;\s]+                # type
            \s+
            ([a-zA-Z_][a-zA-Z0-9_]*)  # function name
            \s*
            \( [^;#]* \)              # argument list
            [\w\s\(\)]*               # attributes or something
            ;)                        # end of declaration
        }xmsg){
            my $decl = $1;
            my $name = $2;

            next if $decl =~ /\b typedef \b/xms;
            next if $name =~ /^_/xms; # skip something private

            push @functions, $name;

            if(_VERBOSE){
                $decl =~ tr/\n\r\t / /s;
                $decl =~ s/ (\Q$name\E) /<$name>/xms;
                _verbose("decl: $decl");
            }
    }

    return @functions;
}


sub cc_append_to_funclist{
    my($self, @functions) = @_;

    $self->_xs_initialize();

    my $mm = $self->makemaker_args;

    push @{$mm->{FUNCLIST} ||= []}, @functions;
    $mm->{DL_FUNCS} ||= { '$(NAME)' => [] };

    return;
}

sub _xshelper_h {
    my $h = <<'XSHELPER_H';
:/* THIS FILE IS AUTOMATICALLY GENERATED BY Module::Install::XSUtil $VERSION. */
:/*
:=head1 NAME
:
:xshelper.h - Helper C header file for XS modules
:
:=head1 DESCRIPTION
:
:    // This includes all the perl header files and ppport.h
:    #include "xshelper.h"
:
:=head1 SEE ALSO
:
:L<Module::Install::XSUtil>, where this file is distributed as a part of
:
:=head1 AUTHOR
:
:Fuji, Goro (gfx) E<lt>gfuji at cpan.orgE<gt>
:
:=head1 LISENCE
:
:Copyright (c) 2010, Fuji, Goro (gfx). All rights reserved.
:
:This library is free software; you can redistribute it and/or modify
:it under the same terms as Perl itself.
:
:=cut
:*/
:
:#ifdef __cplusplus
:extern "C" {
:#endif
:
:#define PERL_NO_GET_CONTEXT /* we want efficiency */
:#include <EXTERN.h>
:#include <perl.h>
:#define NO_XSLOCKS /* for exceptions */
:#include <XSUB.h>
:
:#ifdef __cplusplus
:} /* extern "C" */
:#endif
:
:#include "ppport.h"
:
:/* portability stuff not supported by ppport.h yet */
:
:#ifndef STATIC_INLINE /* from 5.13.4 */
:# if defined(__GNUC__) || defined(__cplusplus) || (defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L))
:#   define STATIC_INLINE static inline
:# else
:#   define STATIC_INLINE static
:# endif
:#endif /* STATIC_INLINE */
:
:#ifndef __attribute__format__
:#define __attribute__format__(a,b,c) /* nothing */
:#endif
:
:#ifndef LIKELY /* they are just a compiler's hint */
:#define LIKELY(x)   (!!(x))
:#define UNLIKELY(x) (!!(x))
:#endif
:
:#ifndef newSVpvs_share
:#define newSVpvs_share(s) Perl_newSVpvn_share(aTHX_ STR_WITH_LEN(s), 0U)
:#endif
:
:#ifndef get_cvs
:#define get_cvs(name, flags) get_cv(name, flags)
:#endif
:
:#ifndef GvNAME_get
:#define GvNAME_get GvNAME
:#endif
:#ifndef GvNAMELEN_get
:#define GvNAMELEN_get GvNAMELEN
:#endif
:
:#ifndef CvGV_set
:#define CvGV_set(cv, gv) (CvGV(cv) = (gv))
:#endif
:
:/* general utility */
:
:#if PERL_BCDVERSION >= 0x5008005
:#define LooksLikeNumber(x) looks_like_number(x)
:#else
:#define LooksLikeNumber(x) (SvPOKp(x) ? looks_like_number(x) : (I32)SvNIOKp(x))
:#endif
:
:#define newAV_mortal()         (AV*)sv_2mortal((SV*)newAV())
:#define newHV_mortal()         (HV*)sv_2mortal((SV*)newHV())
:#define newRV_inc_mortal(sv)   sv_2mortal(newRV_inc(sv))
:#define newRV_noinc_mortal(sv) sv_2mortal(newRV_noinc(sv))
:
:#define DECL_BOOT(name) EXTERN_C XS(CAT2(boot_, name))
:#define CALL_BOOT(name) STMT_START {            \
:        PUSHMARK(SP);                           \
:        CALL_FPTR(CAT2(boot_, name))(aTHX_ cv); \
:    } STMT_END
XSHELPER_H
    $h =~ s/^://xmsg;
    $h =~ s/\$VERSION\b/$Module::Install::XSUtil::VERSION/xms;
    return $h;
}

package
    MY;

# XXX: We must append to PM inside ExtUtils::MakeMaker->new().
sub init_PM {
    my $self = shift;

    $self->SUPER::init_PM(@_);

    while(my($k, $v) = each %ToInstall){
        $self->{PM}{$k} = $v;
    }
    return;
}

# append object file names to CCCMD
sub const_cccmd {
    my $self = shift;

    my $cccmd  = $self->SUPER::const_cccmd(@_);
    return q{} unless $cccmd;

    if (Module::Install::XSUtil::_is_msvc()){
        $cccmd .= ' -Fo$@';
    }
    else {
        $cccmd .= ' -o $@';
    }

    return $cccmd
}

sub xs_c {
    my($self) = @_;
    my $mm = $self->SUPER::xs_c();
    $mm =~ s/ \.c /.cpp/xmsg if $UseCplusplus;
    return $mm;
}

sub xs_o {
    my($self) = @_;
    my $mm = $self->SUPER::xs_o();
    $mm =~ s/ \.c /.cpp/xmsg if $UseCplusplus;
    return $mm;
}

1;
__END__

=for stopwords gfx API

=head1 NAME

Module::Install::XSUtil - Utility functions for XS modules

=head1 VERSION

This document describes Module::Install::XSUtil version 0.45.

=head1 SYNOPSIS

    # in Makefile.PL
    use inc::Module::Install;

    # Enables C compiler warnings
    cc_warnings;

    # Uses ppport.h
    # No need to include it. It's created here.
    use_ppport 3.19;


    # Sets C pre-processor macros.
    cc_define q{-DUSE_SOME_FEATURE=42};

    # Sets paths for header files
    cc_include_paths 'include'; # all the header files are in include/

    # Sets paths for source files
    cc_src_paths 'src'; # all the XS and C source files are in src/

    # Installs header files
    install_headers; # all the header files in @cc_include_paths


=head1 DESCRIPTION

Module::Install::XSUtil provides a set of utilities to setup distributions
which include or depend on XS module.

See L<XS::MRO::Compat> and L<Method::Cumulative> for example.

=head1 FUNCTIONS

=head2 cc_available

Returns true if a C compiler is available. YOU DO NOT NEED TO CALL
THIS FUNCTION YOURSELF: it will be called for you when this module is
initialized, and your Makefile.PL process will exit with 0 status.
Only explicitly call if you need to do some esoteric handling when
no compiler is available (for example, when you have a pure perl alternative)

=head2 c99_available

Returns true if a C compiler is available and it supports C99 features.

=head2 want_xs ?$default

Returns true if the user asked for the XS version or pure perl version of the
module.

Will return true if C<--xs> is explicitly specified as the argument to
F<Makefile.PL>, and false if C<--pp> is specified. If neither is explicitly
specified, will return the value specified by C<$default>. If you do not
specify the value of C<$default>, then it will be true.


=head2 use_ppport ?$version

Creates F<ppport.h> using C<Devel::PPPort::WriteFile()>.

This command calls C<< configure_requires 'Devel::PPPort' => $version >>
and adds C<-DUSE_PPPORT> to C<MakeMaker>'s C<DEFINE>.

=head2 use_xshelper ?-clean|-realclean

Create sF<xshelper.h>, which is a helper header file to include
F<EXTERN.h>, F<perl.h>, F<XSUB.h> and F<ppport.h>, and defines
some portability stuff which are not supported by F<ppport.h>.

Optional argument C<-clean> and C<-realclean> set C<clean_files>
or C<realclean_files> to the generated file F<xshelper.h> respectably.

This command includes C<use_ppport>.

=head2 cc_warnings

Enables C compiler warnings.

=head2 cc_define @macros

Sets C<cpp> macros as compiler options.

=head2 cc_src_paths @source_paths

Sets source file directories which include F<*.xs> or F<*.c>.

=head2 cc_include_paths @include_paths

Sets include paths for a C compiler.

=head2 cc_inc_paths @include_paths;

This B<was> an alias to C<cc_include_paths>, but from 0.42,
this is C<Module::Install::Compiler::cc_inc_paths>, which
replaces the EUMM's C<INC> parameter.

Don't use this function. Use C<cc_include_paths> instead.

=head2 cc_libs @libs

Sets C<MakeMaker>'s C<LIBS>. If a name starts C<->, it will be interpreted as is.
Otherwise prefixed C<-l>.

e.g.:

    cc_libs -lfoo;
    cc_libs  'foo'; # ditto.
    cc_libs qw(-L/path/to/libs foo bar); # with library paths

=head2 cc_assert_lib %args

Checks if the given C library is installed via Devel::CheckLib.
Takes exactly what Devel::CheckLib takes. Note that you must pass
the path names explicitly.

=head2 requires_c99

Tells the build system to use C99 features.

=head2 requires_cplusplus

Tells the build system to use C++ language.

=head2 install_headers ?@header_files

Declares providing header files, extracts functions from these header files,
and adds these functions to C<MakeMaker>'s C<FUNCLIST>.

If I<@header_files> are omitted, all the header files in B<include paths> will
be installed.

=head2 cc_append_to_inc @include_paths

Low level API.

=head2 cc_append_to_libs @libraries

Low level API.

=head2 cc_append_to_ccflags @ccflags

Low level API.

=head2 cc_append_to_funclist @funclist

Low level API.

=head1 OPTIONS

Under the control of this module, F<Makefile.PL> accepts C<-g> option, which
sets C<MakeMaker>'s C<OPTIMIE> C<-g> (or something like). It will disable
optimization and enable some debugging features.

=head1 DEPENDENCIES

Perl 5.5.3 or later.

=head1 NOTE

In F<Makefile.PL>, you might want to use C<author_requires>, which is
provided by C<Module::Install::AuthorReauires>, in order to tell co-developers
that they need to install this plugin.

    author_requires 'Module::Install::XSUtil';

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENT

Thanks to Taro Nishino for the test reports.

Tanks to lestrrat for the suggestions and patches.

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>.

=head1 SEE ALSO

L<ExtUtils::Depends>.

L<Module::Install>.

L<Module::Install::CheckLib>.

L<Devel::CheckLib>.

L<ExtUtils::MakeMaker>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2010, Goro Fuji (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

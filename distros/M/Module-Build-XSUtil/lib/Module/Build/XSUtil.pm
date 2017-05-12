package Module::Build::XSUtil;
use 5.008005;
use strict;
use warnings;
use Config;
use Module::Build;
use File::Basename;
use File::Path;
our @ISA = qw(Module::Build);

our $VERSION = "0.16";

__PACKAGE__->add_property( 'ppport_h_path'   => undef );
__PACKAGE__->add_property( 'xshelper_h_path' => undef );

sub new {
    my $invocant = shift;
    my $class    = ref($invocant) || $invocant;
    my %args     = @_;

    my $self = $class->SUPER::new(%args);

    if ( !defined $args{cc_warnings} ) {
        $args{cc_warnings} = 1;
    }

    unless ( $self->have_c_compiler() ) {
        warn "This distribution requires a C compiler, but it's not available, stopped.\n";
        exit -1;
    }

    # cleanup options
    if ( $^O eq 'cygwin' ) {
        $self->add_to_cleanup('*.stackdump');
    }

    # debugging options
    if ( $self->_xs_debugging() ) {
        if ( $self->_is_msvc() ) {
            $self->_add_extra_compiler_flags('-Zi');
        }
        else {
            $self->_add_extra_compiler_flags(qw/-g -ggdb -g3/);
        }
        $self->_add_extra_compiler_flags('-DXS_ASSERT');
    }

    # c++ options
    if ( $args{needs_compiler_cpp} ) {
        require ExtUtils::CBuilder;
        my $cbuilder = ExtUtils::CBuilder->new( quiet => 1 );
        $cbuilder->have_cplusplus or do {
            warn "This environment does not have a C++ compiler(OS unsupported)\n";
            exit 0;
        };
        if ( $self->_is_gcc ) {
            $self->_add_extra_compiler_flags('-xc++');
            $self->_add_extra_linker_flags('-lstdc++');
            $self->_add_extra_compiler_flags('-D_FILE_OFFSET_BITS=64')
                if $Config::Config{ccflags} =~ /-D_FILE_OFFSET_BITS=64/;
            $self->_add_extra_linker_flags('-lgcc_s')
                if $^O eq 'netbsd' && !grep {/\-lgcc_s/} @{ $self->extra_linker_flags };
            if ( $args{needs_compiler_cpp} == 11 && $self->_enable_cpp11 ) {

                # Use C++11
                $self->_add_extra_compiler_flags('-std=c++11');
                if ( $self->_is_clang ) {
                    $self->_add_extra_compiler_flags('-stdlib=libc++');
                }
            }
        }
        if ( $self->_is_msvc ) {
            $self->_add_extra_compiler_flags('-TP -EHsc');
            $self->_add_extra_linker_flags('msvcprt.lib');
        }
    }

    # c99 is required
    if ( $args{needs_compiler_c99} ) {
        require Devel::CheckCompiler;
        Devel::CheckCompiler::check_c99_or_exit();

        if ( _is_gcc() ) {
            my $gccversion = _gcc_version();
            if ( $gccversion < 5 ) {
                $self->_add_extra_compiler_flags('-std=c99');
            }
        }
    }

    if ( $args{cc_warnings} ) {
        $self->_add_extra_compiler_flags( $self->_cc_warnings( \%args ) );
    }

    # xshelper.h
    if ( my $xshelper = $args{generate_xshelper_h} ) {
        if ( $xshelper eq '1' ) {    # { xshelper => 1 }
            $xshelper = 'xshelper.h';
        }
        $self->xshelper_h_path($xshelper);
        $self->add_to_cleanup($xshelper);

        # generate ppport.h to same directory automatically.
        unless ( defined $args{generate_ppport_h} ) {
            ( my $ppport = $xshelper ) =~ s!xshelper\.h$!ppport\.h!;
            $args{generate_ppport_h} = $ppport;
        }
    }

    # ppport.h
    if ( my $ppport = $args{generate_ppport_h} ) {
        if ( $ppport eq '1' ) {
            $ppport = 'ppport.h';
        }
        $self->ppport_h_path($ppport);
        $self->add_to_cleanup($ppport);
    }

    return $self;
}

sub ACTION_code {
    my $self = shift;

    # write xshelper.h
    if ( my $xshelper = $self->xshelper_h_path ) {
        File::Path::mkpath( File::Basename::dirname($xshelper) );

        if ( open( my $fh, '>', $xshelper ) ) {
            print $fh _xshelper_h();
            close $fh;
        }
    }

    # write ppport.h
    if ( my $ppport = $self->ppport_h_path ) {
        File::Path::mkpath( File::Basename::dirname($ppport) );
        require Devel::PPPort;
        Devel::PPPort::WriteFile($ppport);
    }
    $self->SUPER::ACTION_code(@_);
}

sub ACTION_manifest_skip {
    my $self = shift;
    $self->SUPER::ACTION_manifest_skip(@_);
    if ( -e 'MANIFEST.SKIP' ) {
        open( my $fh, '<', 'MANIFEST.SKIP' ) or die $!;
        my $content = do { local $/; <$fh> };
        close $fh;
        my $ppport = $self->ppport_h_path;
        if ( $ppport && $content !~ /\Q${ppport}\E/ ) {

            my $safe = quotemeta($ppport);
            $self->_append_maniskip("^$safe\$");
        }

        my $xshelper = $self->xshelper_h_path;
        if ( $xshelper && $content !~ /\Q${xshelper}\E/ ) {
            my $safe = quotemeta($xshelper);
            $self->_append_maniskip("^$safe\$");
        }
    }
}

sub auto_require {
    my ($self) = @_;
    my $p = $self->{properties};
    if (    $self->dist_name ne 'Module-Build-XSUtil'
        and $self->auto_configure_requires )
    {
        if ( not exists $p->{configure_requires}{'Module::Build::XSUtil'} ) {
            ( my $ver = $VERSION ) =~ s/^(\d+\.\d\d).*$/$1/;    # last major release only
            $self->_add_prereq( 'configure_requires', 'Module::Build::XSUtil', $ver );
        }
    }

    $self->SUPER::auto_require();

    return;
}

sub _xs_debugging {
    my ($self) = @_;
    return $ENV{XS_DEBUG} || $self->args('g');
}

sub _is_gcc {
    return $Config{gccversion};
}

# Microsoft Visual C++ Compiler (cl.exe)
sub _is_msvc {
    return $Config{cc} =~ /\A cl \b /xmsi;
}

sub _enable_cpp11 {
    if ( _is_clang() ) {
        my $ver = _llvm_version();
        warn $ver->{major};
        return ( $ver->{major} >= 3 && $ver->{minor} >= 2 );
    }
    elsif ( _is_gcc() ) {
        my $ver = _gcc_version();
        my ( $major, $minor ) = $ver =~ /([0-9]+\.([0-9]+))/;
        return ( $major >= 4 && $minor >= 7 );
    }
}

sub _is_clang {
    my $ver = `$Config{cc} --version`;
    return $ver =~ /clang\-[0-9]+/ ? 1 : 0;
}

sub _llvm_version {
    my $ver = `$Config{cc} --version`;
    return unless _is_clang();
    my ( $llvm_majar, $llvm_minor ) = $ver =~ /LLVM\s+([0-9]+)\.([0-9]+)/;
    return { major => $llvm_majar, minor => $llvm_minor };
}

sub _gcc_version {
    my $res = `$Config{cc} --version`;
    my ($version) = $res =~ /(?:\(GCC\)|g?cc \([^)]+\)) ([0-9.]+)/;
    no warnings 'numeric', 'uninitialized';
    return sprintf '%g', $version;
}

sub _cc_warnings {
    my ( $self, $args ) = @_;

    my @flags;
    if ( $self->_is_gcc() ) {
        push @flags, qw(-Wall);

        my $gccversion = $self->_gcc_version();
        if ( $gccversion >= 4.0 ) {
            push @flags, qw(-Wextra);
            if ( !( $args->{needs_compiler_c99} or $args->{needs_compiler_cpp} ) ) {

                # Note: MSVC++ doesn't support C99,
                # so -Wdeclaration-after-statement helps
                # ensure C89 specs.
                push @flags, qw(-Wdeclaration-after-statement);
            }
            if ( $gccversion >= 4.1 && !$args->{needs_compiler_cpp} ) {
                push @flags, qw(-Wc++-compat);
            }
        }
        else {
            push @flags, qw(-W -Wno-comment);
        }
    }
    elsif ( $self->_is_msvc() ) {
        push @flags, qw(-W3);
    }
    else {

        # TODO: support other compilers
    }

    return @flags;
}

sub _add_extra_compiler_flags {
    my ( $self, @flags ) = @_;
    $self->extra_compiler_flags( @{ $self->extra_compiler_flags }, @flags );
}

sub _add_extra_linker_flags {
    my ( $self, @flags ) = @_;
    $self->extra_linker_flags( @{ $self->extra_linker_flags }, @flags );
}

sub _xshelper_h {
    my $h = <<'XSHELPER_H';
:/* THIS FILE IS AUTOMATICALLY GENERATED BY Module::Build::XSUtil $VERSION. */
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
:# if defined(__cplusplus) || (defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L))
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
    $h =~ s/\$VERSION\b/$VERSION/xms;
    return $h;
}

1;
__END__
 
=encoding utf-8
 
=head1 NAME
 
Module::Build::XSUtil - A Module::Build class for building XS modules
 
=head1 SYNOPSIS

Use in your Build.PL

    use strict;
    use warnings;
    use Module::Build::XSUtil;
    
    my $builder = Module::Build::XSUtil->new(
        dist_name            => 'Your-XS-Module',
        license              => 'perl',
        dist_author          => 'Your Name <yourname@example.com>',
        dist_version_from    => 'lib/Your/XS/Module',
        generate_ppport_h    => 'lib/Your/XS/ppport.h',
        generate_xshelper_h  => 'lib/Your/XS/xshelper.h',
        needs_compiler_c99   => 1,
    );
    
    $builder->create_build_script();

Use in custom builder module.

    pakcage builder::MyBuilder;
    use strict;
    use warnings;
    use base 'Module::Build::XSUtil';
    
    sub new {
        my ($class, %args) = @_;
        my $self = $class->SUPER::new(
            %args,
            generate_ppport_h    => 'lib/Your/XS/ppport.h',
            generate_xshelper_h  => 'lib/Your/XS/xshelper.h',
            needs_compiler_c99   => 1,
        );
        return $self;
    }
    
    1;


=head1 DESCRIPTION
 
Module::Build::XSUtil is subclass of L<Module::Build> for support building XS modules.

This is a list of a new parameters in the Module::Build::new method:

=over

=item needs_compiler_c99

This option checks C99 compiler's availability. If it's not available, Build.PL exits by 0.

=item needs_compiler_cpp

This option checks C++ compiler's availability. If it's not available, Build.PL exits by 0.

In addition, append 'extra_compiler_flags' and 'extra_linker_flags' for C++.

=item generate_ppport_h

Genereate ppport.h by L<Devel::PPPort>.

=item generate_xshelper_h

Genereate xshelper.h which is a helper header file to include EXTERN.h, perl.h, XSUB.h and ppport.h, 
and defines some portability stuff which are not supported by ppport.h.

It is porting from L<Module::Install::XSUtil>.

=item cc_warnings

Enable compiler warnings flag. It is enable by default. 

=item -g options

If invoke Build.PL with '-g' option, It will build with debug options.

=back

=head1 SEE ALSO

L<Module::Install::XSUtil>

=head1 LICENSE
 
Copyright (C) Hideaki Ohno.
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=head1 AUTHOR
 
Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>
 
=cut

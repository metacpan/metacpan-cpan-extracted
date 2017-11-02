[![Build Status](https://travis-ci.org/hideo55/Module-Build-XSUtil.svg?branch=master)](https://travis-ci.org/hideo55/Module-Build-XSUtil)
# NAME

Module::Build::XSUtil - A Module::Build class for building XS modules

# SYNOPSIS

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

    package builder::MyBuilder;
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

# DESCRIPTION

Module::Build::XSUtil is subclass of [Module::Build](https://metacpan.org/pod/Module::Build) for support building XS modules.

This is a list of a new parameters in the Module::Build::new method:

- needs\_compiler\_c99

    This option checks C99 compiler's availability. If it's not available, Build.PL exits by 0.

- needs\_compiler\_cpp

    This option checks C++ compiler's availability. If it's not available, Build.PL exits by 0.

    In addition, append 'extra\_compiler\_flags' and 'extra\_linker\_flags' for C++.

- generate\_ppport\_h

    Genereate ppport.h by [Devel::PPPort](https://metacpan.org/pod/Devel::PPPort).

- generate\_xshelper\_h

    Genereate xshelper.h which is a helper header file to include EXTERN.h, perl.h, XSUB.h and ppport.h, 
    and defines some portability stuff which are not supported by ppport.h.

    It is porting from [Module::Install::XSUtil](https://metacpan.org/pod/Module::Install::XSUtil).

- cc\_warnings

    Enable compiler warnings flag. It is enable by default. 

- -g options

    If invoke Build.PL with '-g' option, It will build with debug options.

# SEE ALSO

[Module::Install::XSUtil](https://metacpan.org/pod/Module::Install::XSUtil)

# LICENSE

Copyright (C) Hideaki Ohno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hideaki Ohno <hide.o.j55 {at} gmail.com>

[![Build Status](https://travis-ci.org/kazeburo/POSIX-strftime-Compiler.svg?branch=master)](https://travis-ci.org/kazeburo/POSIX-strftime-Compiler)
# NAME

POSIX::strftime::Compiler - GNU C library compatible strftime for loggers and servers

# SYNOPSIS

    use POSIX::strftime::Compiler qw/strftime/;

    say strftime('%a, %d %b %Y %T %z',localtime):
    
    my $fmt = '%a, %d %b %Y %T %z';
    my $psc = POSIX::strftime::Compiler->new($fmt);
    say $psc->to_string(localtime);

# DESCRIPTION

POSIX::strftime::Compiler provides GNU C library compatible strftime(3). But this module will not affected
by the system locale.  This feature is useful when you want to write loggers, servers and portable applications.

For generate same result strings on any locale, POSIX::strftime::Compiler wraps POSIX::strftime and 
converts some format characters to perl code

# FUNCTION

- strftime($fmt:String, @time)

    Generate formatted string from a format and time.

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
        strftime('%d/%b/%Y:%T %z',$sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst):

    Compiled codes are stored in `%POSIX::strftime::Compiler::STRFTIME`. This function is not exported by default.

# METHODS

- new($fmt)

    create instance of POSIX::strftime::Compiler

- to\_string(@time)

    Generate formatted string from time.

# FORMAT CHARACTERS

POSIX::strftime::Compiler supports almost all characters that GNU strftime(3) supports. 
But `%E[cCxXyY]` and `%O[deHImMSuUVwWy]` are not supported, just remove E and O prefix.

# A RECOMMEND MODULE

- [Time::TZOffset](https://metacpan.org/pod/Time::TZOffset)

    If [Time::TZOffset](https://metacpan.org/pod/Time::TZOffset) is available, P::s::Compiler use it for more faster time zone offset calculation.
    I strongly recommend you to install this if you use `%z`.

# PERFORMANCE ISSUES ON WINDOWS

Windows and Cygwin and some system may not support `%z` and `%Z`. For these system, 
POSIX::strftime::Compiler calculate time zone offset and find zone name. This is not fast.
If you need performance on Windows and Cygwin, please install [Time::TZOffset](https://metacpan.org/pod/Time::TZOffset)

# SEE ALSO

- [POSIX::strftime::GNU](https://metacpan.org/pod/POSIX::strftime::GNU)

    POSIX::strftime::Compiler is built on POSIX::strftime::GNU::PP code

- [POSIX](https://metacpan.org/pod/POSIX)
- [Apache::LogFormat::Compiler](https://metacpan.org/pod/Apache::LogFormat::Compiler)

# LICENSE

Copyright (C) Masahiro Nagano.

Format specification is based on strftime(3) manual page which is a part of the Linux man-pages project.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masahiro Nagano <kazeburo@gmail.com>

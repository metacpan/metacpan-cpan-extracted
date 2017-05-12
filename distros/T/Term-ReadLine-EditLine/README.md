# NAME

Term::ReadLine::EditLine - Term::ReadLine style wrapper for Term::EditLine

# SYNOPSIS

    use Term::ReadLine;

    my $t = Term::ReadLine->new('program name');
    while (defined($_ = $t->readline('prompt> '))) {
        ...
        $t->addhistory($_) if /\S/;
    }

# DESCRIPTION

Term::ReadLine::EditLine provides [Term::ReadLine](http://search.cpan.org/perldoc?Term::ReadLine) interface using [Term::EditLine](http://search.cpan.org/perldoc?Term::EditLine).

# MOTIVATION

[Term::ReadLine::Gnu](http://search.cpan.org/perldoc?Term::ReadLine::Gnu) is great, but it's hard to install on Mac OS X. Because it has pre-installed
libedit but it does not contain GNU readline.

Term::ReadLine::EditLine is very easy to install on OSX.

# INTERFACE

You can use following methods in Term::ReadLine interface.

- Term::ReadLine->new($program\_name\[, IN, OUT\])
- $t->addhistory($history)
- my $line = $t->readline()
- $t->ReadLine()
- $t->IN()
- $t->OUT()
- $t->findConsole()
- $t->Attribs()
- $t->Features()

Additionally, you can use `$t->editline()` method to access [Term::EditLine](http://search.cpan.org/perldoc?Term::EditLine) instance.

# ENVIRONMENT

The Term::ReadLine interface module uses the PERL\_RL variable to decide which module to load; so if you want to use this module for all your perl applications, try something like:

    export PERL_RL=EditLine

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF@ GMAIL COM>

# SEE ALSO

This module provides interface for [Term::ReadLine](http://search.cpan.org/perldoc?Term::ReadLine), based on [Term::EditLine](http://search.cpan.org/perldoc?Term::EditLine).

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

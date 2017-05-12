# NAME

Module::Build::Pluggable - Module::Build meets plugins

# SYNOPSIS

    use Module::Build::Pluggable (
        'Repository',
        'ReadmeMarkdownFromPod',
        'PPPort',
    );

    my $builder = Module::Build::Pluggable->new(
        ... # normal M::B args
    );
    $builder->create_build_script();

# DESCRIPTION

Module::Build::Pluggable adds pluggability for Module::Build.

# HOW CAN I WRITE MY OWN PLUGIN?

Module::Build::Pluggable call __HOOK\_prepare__ on preparing arguments for `Module::Build->new`, __HOOK\_configure__ on configuration step, and __HOOK\_build__ on build step.

That's all.

And if you want a help, you can use [Module::Build::Pluggable::Base](http://search.cpan.org/perldoc?Module::Build::Pluggable::Base) as base class.

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF@ GMAIL COM>

# SEE ALSO

This module built on [Module::Build](http://search.cpan.org/perldoc?Module::Build).

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

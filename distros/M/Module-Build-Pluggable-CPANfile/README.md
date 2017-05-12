# NAME

Module::Build::Pluggable::CPANfile - Include cpanfile

# SYNOPSIS

    # cpanfile
    requires 'Plack', 0.9;
    on test => sub {
        requires 'Test::Warn';
    };
    

    # Build.PL
    use Module::Build::Pluggable (
        'CPANfile'
    );
    

    my $builder = Module::Build::Pluggable->new(
          ... # normal M::B args. but not required prereqs
    );
    $builder->create_build_script();

# DESCRIPTION

Module::Build::Pluggable::CPANfile is plugin for Module::Build::Pluggable to include dependencies from cpanfile into meta files. 
This modules is [Module::Install::CPANfile](http://search.cpan.org/perldoc?Module::Install::CPANfile) for Module::Build

__THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE__.

# AUTHOR

Masahiro Nagano <kazeburo@gmail.com>

# SEE ALSO

[Module::Install::CPANfile](http://search.cpan.org/perldoc?Module::Install::CPANfile), [cpanfile](http://search.cpan.org/perldoc?cpanfile), [Module::Build::Pluggable](http://search.cpan.org/perldoc?Module::Build::Pluggable)

# LICENSE

Copyright (C) Masahiro Nagano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

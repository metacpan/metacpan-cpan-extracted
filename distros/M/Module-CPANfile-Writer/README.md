# NAME

Module::CPANfile::Writer - Module for modifying the cpanfile

# SYNOPSIS

    use Module::CPANfile::Writer;

    my $writer = Module::CPANfile::Writer->new('cpanfile');
    $writer->add_prereq('Moo', '2.003004');
    $writer->add_prereq('Test2::Suite', undef, relationship => 'recommends');
    $writer->save('cpanfile');

# DESCRIPTION

Module::CPANfile::Writer lets you modify the version of modules in the existing cpanfile.

cpanfile is very flexible because it is written in Perl by using DSL, you can write comments and even code.
Therefore, modifying the cpanfile is not easy and you have to understand Perl code.

The idea of modifying the cpanfile was inspired by [App::CpanfileSliptop](https://metacpan.org/pod/App::CpanfileSliptop).
This module uses [PPI](https://metacpan.org/pod/PPI) to parse and analyze the cpanfile as Perl code.
But PPI depends XS modules such as [Clone](https://metacpan.org/pod/Clone) and [Params::Util](https://metacpan.org/pod/Params::Util), so these modules are annoying to fatpack in one pure-perl script.

Module::CPANfile::Writer has no XS modules in dependencies because it uses [Babble](https://metacpan.org/pod/Babble) and [PPR](https://metacpan.org/pod/PPR) to parse (recognize) Perl code.

# METHODS

- $writer = Module::CPANfile::Writer->new($file)
- $writer = Module::CPANfile::Writer->new(\\$src)

    This will create a new instance of [Module::CPANfile::Writer](https://metacpan.org/pod/Module::CPANfile::Writer).

    It takes the filename or the content of cpanfile as scalarref.

- $writer->src

    This will returns the content of modified cpanfile.

- $writer->add\_prereq($module, \[$version, relationship => $relationship)

    Modify the version of specified `$module` in cpanfile.

    You can also pass `$version` to 0 or undef, this will remove the version requirement of `$module`.

- $writer->save($file);

    Write the content of modified cpanfile to the `$file`.

# SEE ALSO

[Module::CPANfile](https://metacpan.org/pod/Module::CPANfile)

# LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takumi Akiyama <t.akiym@gmail.com>

[![Build Status](https://travis-ci.org/Songmu/p5-SQL-Translator-Producer-Teng.png?branch=master)](https://travis-ci.org/Songmu/p5-SQL-Translator-Producer-Teng)
# NAME

SQL::Translator::Producer::Teng - Teng-specific producer for SQL::Translator

# SYNOPSIS

Use via SQL::Translator:

    use SQL::Translator;
    my $t = SQL::Translator->new( parser => '...' );
    $t->producer('Teng', package => 'MyApp::DB::Schema');
    $t->translate;

# DESCRIPTION

This module will produce text output of the schema suitable for [Teng](http://search.cpan.org/perldoc?Teng).
It will be a '.pm' file of [Teng::Schema::Declare](http://search.cpan.org/perldoc?Teng::Schema::Declare) format.

# ARGUMENTS

This producer takes a single optional producer\_arg `package`, which
provides the package name of the target schema '.pm' file.

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>

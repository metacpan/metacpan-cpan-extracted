[![Build Status](https://travis-ci.org/akiym/OrePAN2-Indexer-Tiny.svg?branch=master)](https://travis-ci.org/akiym/OrePAN2-Indexer-Tiny)
# NAME

OrePAN2::Indexer::Tiny - Minimal DarkPAN indexer

# SYNOPSIS

    use OrePAN2::Indexer::Tiny;

    my $orepan = OrePAN2::Indexer::Tiny->new(
        directory => $directory,
    );
    $orepan->load_index();
    for my $archive_file ($self->list_archive_files()) {
        $self->add_index( $archive_file );
    }
    $self->write_index();

# DESCRIPTION

OrePAN2::Indexer::Tiny is minimal [OrePAN2](https://metacpan.org/pod/OrePAN2) indexer which have less dependencies.

Original code is taken from [OrePAN2](https://metacpan.org/pod/OrePAN2).

# SEE ALSO

[OrePAN2](https://metacpan.org/pod/OrePAN2)

# LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takumi Akiyama <t.akiym@gmail.com>

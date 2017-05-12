[![Build Status](https://travis-ci.org/moznion/TV-ARIB-ProgramGenre.png?branch=master)](https://travis-ci.org/moznion/TV-ARIB-ProgramGenre)
# NAME

TV::ARIB::ProgramGenre - Utilities for TV program genre of ARIB

# SYNOPSIS

    use utf8;
    use Encode qw/encode_utf8/;
    use TV::ARIB::ProgramGenre qw/get_genre_name get_genre_id
                                  get_parent_genre_name get_parent_genre_id/;

    my $genre = get_genre_name(0, 1);       # => encode_utf8('天気')
    my $id    = get_genre_id('国内アニメ'); # => is_deeply [7, 0]

    my $parent_genre    = get_parent_genre_name(1);      # => encode_utf8('スポーツ')
    my $parent_genre_id = get_parent_genre_id('ドラマ'); # => 3

# DESCRIPTION

TV::ARIB::ProgramGenre is the utilities for TV program genre of ARIB.
Details about ARIB TV program genre are in [http://www.arib.or.jp/english/html/overview/doc/2-STD-B10v5_1.pdf](http://www.arib.or.jp/english/html/overview/doc/2-STD-B10v5_1.pdf) (Japanese pdf).

# FUNCTIONS

- get\_genre\_name($parent\_genre\_id, $child\_genre\_id)

    Get genre name by parent genre ID and child genre ID

- get\_genre\_id($genre\_name)

    Get genre ID by genre name. It returns array reference like so `[$parent_genre_id, $child_genre_id]`

- get\_parent\_genre\_name($parent\_genre\_id)

    Get parent genre name by parent genre ID

- get\_parent\_genre\_id($parent\_genre\_name)

    Get parent genre ID by parent genre name

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

moznion <moznion@gmail.com>

[![Build Status](https://travis-ci.org/nnutter/mojo-pgx-cursor.svg?branch=master)](https://travis-ci.org/nnutter/mojo-pgx-cursor)
# NAME

Mojo::PgX::Cursor - Cursor Extension for Mojo::Pg

# SYNOPSIS

    my $pg = Mojo::PgX::Cursor->new('postgresql://postgres@/test');
    my $results = $pg->db->cursor('select * from some_big_table');
    while (my $next = $results->hash) {
      say $next->{name};
    }

# DESCRIPTION

[DBD::Pg](https://metacpan.org/pod/DBD::Pg) fetches all rows when a statement is executed whereas other drivers
usually fetch rows using the `fetch*` methods.  Mojo::PgX::Cursor is an
extension to work around this issue using PostgreSQL cursors while providing a
[Mojo::Pg](https://metacpan.org/pod/Mojo::Pg)-style API for iteratoring over the results; see
[Mojo::PgX::Cursor::Results](https://metacpan.org/pod/Mojo::PgX::Cursor::Results) for details.

# METHODS

## db

This subclass overrides [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg)'s implementation in order to subclass the
resulting [Mojo::Pg::Database](https://metacpan.org/pod/Mojo::Pg::Database) object into a [Mojo::PgX::Cursor::Database](https://metacpan.org/pod/Mojo::PgX::Cursor::Database).

# VERSIONING

This module will follow [Semantic Versioning
2.0.0](http://semver.org/spec/v2.0.0.html).  Once the API feels reasonable I'll
release v1.0.0 which would correspond to 1.000000 according to [version](https://metacpan.org/pod/version),

    version->declare(q(v1.0.0))->numify # 1.000000
    version->parse(q(1.000000))->normal # v1.0.0

# MONKEYPATCH

    require Mojo::Pg;
    require Mojo::PgX::Cursor;
    use Mojo::Util 'monkey_patch';
    monkey_patch 'Mojo::Pg::Database', 'cursor', \&Mojo::PgX::Cursor::Database::cursor;

Just because you can doesn't mean you should but if you want you can
`monkey_patch` [Mojo::Pg::Database](https://metacpan.org/pod/Mojo::Pg::Database) rather than swapping out your
construction of [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg) objects with the [Mojo::PgX::Cursor](https://metacpan.org/pod/Mojo::PgX::Cursor) subclass.

# DISCUSSION

This module would be unnecessary if [DBD::Pg](https://metacpan.org/pod/DBD::Pg) did not fetch all rows during
`execute` and since `libpq` supports that it would be much better to fix
`fetch*` than to implement this.  However, I am not able to do so at this
time.

# CONTRIBUTING

If you would like to submit bug reports, feature requests, questions, etc. you
should create an issue on the [GitHub Issue
Tracker](https://github.com/nnutter/mojo-pgx-cursor/issues) for this module.

# REFERENCES

- [#93266 for DBD-Pg: DBD::Pg to set the fetch size](https://rt.cpan.org/Public/Bug/Display.html?id=93266)
- [#19488 for DBD-Pg: Support of cursor concept](https://rt.cpan.org/Public/Bug/Display.html?id=19488)

# LICENSE

Copyright (C) Nathaniel Nutter.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Nathaniel Nutter `nnutter@cpan.org`

# SEE ALSO

[DBD::Pg](https://metacpan.org/pod/DBD::Pg), [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg), [Mojo::PgX::Cursor::Cursor](https://metacpan.org/pod/Mojo::PgX::Cursor::Cursor),
[Mojo::PgX::Cursor::Database](https://metacpan.org/pod/Mojo::PgX::Cursor::Database), [Mojo::PgX::Cursor::Results](https://metacpan.org/pod/Mojo::PgX::Cursor::Results)

# NAME

SQL::NamedPlaceholder - extension of placeholder

# SYNOPSIS

    use SQL::NamedPlaceholder qw(bind_named);

    my ($sql, $bind) = bind_named(q[
        SELECT *
        FROM entry
        WHERE
            user_id = :user_id
    ], {
        user_id => $user_id
    });

    $dbh->prepare_cached($sql)->execute(@$bind);

# DESCRIPTION

SQL::NamedPlaceholder is extension of placeholder. This enable more readable and robust code.

# FUNCTION

- ($sql, $bind) = bind\_named($sql, $hash);

    The $sql parameter is SQL string which contains named placeholders. The $hash parameter is map of bind parameters.

    The returned $sql is new SQL string which contains normal placeholders ('?'), and $bind is array reference of bind parameters.

# SYNTAX

- :foobar

    Replace as placeholder which uses value from $hash->{foobar}.

- foobar = ?, foobar > ?, foobar < ?, foobar <> ?, etc.

    This is same as 'foobar = :foobar'.

# AUTHOR

cho45 <cho45@lowreal.net>

# SEE ALSO

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

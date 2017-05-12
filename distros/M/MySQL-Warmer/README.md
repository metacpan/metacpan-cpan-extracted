# NAME

MySQL::Warmer - execute warming up queries for InnoDB

# SYNOPSIS

    use MySQL::Warmer;
    MySQL::Warmer->new(dbh => $dbh)->run;

# DESCRIPTION

MySQL::Warmer is to execute warming up queries on cold DB server.

I consulted following entry about warming up strategy of this module.

[http://labs.cybozu.co.jp/blog/kazuho/archives/2007/10/innodb\_warmup.php](http://labs.cybozu.co.jp/blog/kazuho/archives/2007/10/innodb_warmup.php)

# SEE ALSO

[mysql-warmup](https://metacpan.org/pod/mysql-warmup)

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>

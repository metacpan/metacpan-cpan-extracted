# NAME

Perl5::CoreSmokeDB::Schema - [DBIC::Schema](https://metacpan.org/pod/DBIx::Class::Schema) for the smoke reports database

# SYNOPSIS

```perl
use Perl5::CoreSmokeDB::Schema;
my $schema = Perl5::CoreSmokeDB::Schema->connect($dsn, $user, $pswd, $options);

my $report = $schema->resultset('Report')->find({ id => 1 });
```
# DESCRIPTION

This class is used in the backend for accessing the database.

Another use is: `$schema->deploy()`

# AUTHOR

&copy; MMXIII - MMXXII Abe Timmerman <abeltje@cpan.org>, H.Merijn Brand

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.


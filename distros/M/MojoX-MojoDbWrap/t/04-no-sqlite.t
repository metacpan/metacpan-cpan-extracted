use strict;
use Test::More;
use Test::Exception;

# pretend Mojo::SQLite is not installed
unshift @INC, sub {
   die "Can't locate Mojo/SQLite.pm in \@INC (hidden by test)\n"
      if $_[1] eq 'Mojo/SQLite.pm';
   return;
};

use MojoX::MojoDbWrap;

for my $url (qw< data.db sqlite:/x.db >) {
   throws_ok { MojoX::MojoDbWrap->new(db_url => $url)->mdb }
      qr{Can't locate Mojo/SQLite\.pm},
      "missing Mojo::SQLite is reported as such ($url)";
   unlike "$@", qr{unsupported DB URL}, "not as an unsupported URL ($url)";
}

done_testing();

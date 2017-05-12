use strict;
use Test::More;
use Scope::Container;
use Scope::Container::DBI;

{
    my $sc = start_scope_container();
    eval {
        my $dbh = Scope::Container::DBI->connect("dbi:__foobarbaz__:dbname=a","","",{RaiseError=>1, PrintError=>0});
    };
    my $err = $@;
    like $err, qr!__foobarbaz__!;
}

{
    my $sc = start_scope_container();
    eval {
        my $dbh = Scope::Container::DBI->connect("dbi:__foobarbaz__:dbname=a","","",{RaiseError=>0, PrintError=>0});
    };
    my $err = $@;
    like $err, qr!__foobarbaz__!;
}

done_testing();


#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Role::Tiny;
use Tables::Test::Angka;

my $t = Tables::Test::Angka->new;
Role::Tiny->apply_roles_to_object($t, 'TablesRole::Util::Basic');

subtest as_aoa => sub {
    my $aoa = $t->as_aoa;
    is_deeply($aoa, [
        [1,'one','satu'],
        [2,'two','dua'],
        [3,'three','tiga'],
        [4,'four','empat'],
        [5,'five','lima'],
    ]) or diag explain $aoa;
};

subtest as_aoh => sub {
    my $aoh = $t->as_aoh;
    is_deeply($aoh, [
        {number=>1,en_name=>'one',id_name=>'satu'},
        {number=>2,en_name=>'two',id_name=>'dua'},
        {number=>3,en_name=>'three',id_name=>'tiga'},
        {number=>4,en_name=>'four',id_name=>'empat'},
        {number=>5,en_name=>'five',id_name=>'lima'},
    ]) or diag explain $aoh;
};

done_testing;

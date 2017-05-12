#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use_ok('Parse::SSH2::PublicKey');

my $k = Parse::SSH2::PublicKey->new( encryption => 'ssh-rsa',
                       key  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC6ogUplPsKJkz2FNiD4nQaPyTzMaXt8V75/hmy4dHNGWzmvMJTqJHPFM3BthQLZkjCem6Lk6rtj61CgqvWwo/yjRLuy7wFdOhwEs+ByT2BlVmvxhvTBwhL0gK2/AGSIiAUmuWguXZfNlqUN4bokr0caSv7JH8pwc+4OsUBfyGpMc8DO8SfNhyGvAiOZlUfcCJiikdEw+H9n+zq/r9vPlN6sQEO99akeGpIWkiVUfSjKrdgP6LdfeBltv1zQf2rGA0G/rKNx5r1X7tw2bIfKymVDUV/maTwPwXrQrJ/JHQjONREqmNJpq+EkugqR46Kbr3NVMGXvl8g63t1IKXNcPAZ',
                       comment => 'testusr@testhost',
                       type => 'public',
                     );
ok(1);


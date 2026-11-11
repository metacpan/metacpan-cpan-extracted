#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Punk::Config;

# The config loader's refusals and accessors: an option that is not one,
# the retired `secrets` option, a load with no file, a secret that is not
# there, a path that is not there, and the files and env the handle reports.

plan skip_all => 'YAML::XS required for these tests' unless eval { require YAML::XS; 1 };

my $dir = File::Temp->newdir;
sub spew { my ($f, $s) = @_; open my $fh, '>', $f or die "$f: $!"; print $fh $s; close $fh }
spew("$dir/punk.yml", "name: base\ndatabase:\n  dsn: dbi:SQLite:dbname=x.db\n  password: { \$literal: shh }\n");
spew("$dir/punk.test.yml", "name: test\n");

sub refuses {
    my ($re, $name, $code) = @_;
    my $e = '';
    eval { $code->(); 1 } or $e = $@;
    like($e, $re, $name);
}

refuses(qr/Punk::Config->load: unknown option 'bogus'/, 'an option that is not one', sub { Punk::Config->load(file => "$dir/punk.yml", bogus => 1) });
refuses(qr/Punk::Config->load: the 'secrets' option is gone/, 'the retired secrets option', sub { Punk::Config->load(file => "$dir/punk.yml", secrets => 'strict') });
refuses(qr/Punk::Config->load: a file is required/, 'a load with no file', sub { Punk::Config->load(env => 'test') });

my $cfg = Punk::Config->load(file => "$dir/punk.yml", env => 'test');
is($cfg->get('name'), 'test', 'the environment layer wins');
is($cfg->env, 'test', 'env reports the layer that applied');
is_deeply([ map { (my $b = $_) =~ s{.*/}{}; $b } @{ $cfg->files } ], [ 'punk.yml', 'punk.test.yml' ], 'files lists the layers that exist, in order');
is($cfg->secret('database.password'), 'shh', 'a secret resolves');
refuses(qr/Punk::Config: no secret at 'database.dsn'/, 'a path that is not a secret', sub { $cfg->secret('database.dsn') });
refuses(qr/Punk::Config: no secret at 'nowhere.at.all'/, 'nor a path that is not there', sub { $cfg->secret('nowhere.at.all') });
ok(!defined $cfg->get('nowhere.at.all'), 'get of a path that is not there is undef');
ok(!defined $cfg->get('database.dsn.deeper'), 'as is a path through a scalar');
is($cfg->config->{database}{password}, '[redacted]', 'the public copy redacts the secret');

done_testing;

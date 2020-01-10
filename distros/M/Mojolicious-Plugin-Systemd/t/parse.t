use Mojo::Base -strict;
use Test::More;
use Mojolicious::Plugin::Systemd;

my $env_file
  = Mojo::File::curfile->sibling(qw(data foo.env))->to_abs->to_string;
my $unit_file
  = Mojo::File::curfile->sibling(qw(data foo.service))->to_abs->to_string;
plan skip_all => 'could not find foo.service'
  unless -r $env_file and -r $unit_file;

my $p = Mojolicious::Plugin::Systemd->new;

$ENV{$_} = $_ for qw(BAR BAZ BAZ_BAZ BAZ_Q FOO);
$p->_parse_environment_file($env_file);
is_deeply [@ENV{qw(BAR BAZ BAZ_BAZ BAZ_Q FOO)}],
  ['b aaaa r r', '', ' baz', '', '4'], '_parse_environment_file';

$ENV{$_} = $_ for qw(BAR BAZ BAZ_Q FOO X Y_Y_Y);
$p->_parse_unit_file($unit_file);
is_deeply [@ENV{qw(BAR BAZ FOO MOJO_REVERSE_PROXY MYAPP_HOME X Y_Y_Y)}],
  ['word3', '$word 5 6', 'w=1', undef, '/var/my-app', undef, undef],
  '_parse_unit_file';

done_testing;

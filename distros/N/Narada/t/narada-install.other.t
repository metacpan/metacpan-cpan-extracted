use lib 't'; use share; guard my $guard;

require (wd().'/blib/script/narada-install');


sub is_trace;
my $migrate;
my $module = Test::MockModule->new('main');
$module->mock(load => sub {
    my @args = @_;
    my @result;
    output_from { @result = $module->original('load')->(@args) };
    return wantarray ? @result : $result[0];
});


# - load
#   * no next_version file
throws_ok { load('0.1.0', '9.9.9') } qr/No such file/i, 'no next_version file';
#   * only next_version file
lives_ok { $migrate = load('0.0.0', 'l1') } 'only next_version file';
is_trace ['0.0.0','l1'], ['a'];
#   * next_version and prev_version files, in order
lives_ok { $migrate = load('l1pre', 'l1') } 'next_version and prev_version files';
is_trace ['0.0.0','l1'], ['a'];
lives_ok { $migrate = load('l1', 'l1pre') } 'next_version and prev_version files, other order';
is_trace ['0.0.0','l1'], ['pre_a'];
#   * extra files and next_version file, in order
lives_ok { $migrate = load('0.0.0', 'l1', '.release/l1ex1.migrate', '.release/l1ex2.migrate') }
    'extra files and next_version file';
is_trace ['0.0.0','l1'], ['ex1'];
#   * extra files, next_version and prev_version file, in order
lives_ok { $migrate = load('l1pre', 'l1', '.release/l1ex1.migrate', '.release/l1ex2.migrate') }
    'extra files, next_version and prev_version file';
is_trace ['0.0.0','l1'], ['ex1'];

# - get_path
#   * no paths
$migrate = load('l3', 'l3a');
throws_ok { get_path($migrate, 'l2a', 'l3b') } qr/Unable to find/i, 'no paths';
#   * two paths
throws_ok { get_path($migrate, 'l2a', 'l2') } qr/more than one/i, 'two paths';
#   * one path
$migrate = load('l3', 'l3b');
is_deeply get_path($migrate, 'l2a', 'l3b'), ['l2a','l3b'], 'one path';
is_deeply get_path($migrate, 'l2a', 'l2'), ['l2a','l1','l2'], 'one path';

# - check_path
#   * wrong path (from --path)
$migrate = load('l3', 'l3a');
throws_ok { check_path($migrate, ['l1','l3'], 0, 0) } qr/one-step/i, 'wrong path';
#   * path require --allow-downgrade, with/without it
throws_ok { check_path($migrate, ['l2','l1'], 0, 0) } qr/--allow-downgrade/, 'downgrade not allowed';
lives_ok  { check_path($migrate, ['l2','l1'], 1, 0) } 'downgrade allowed';
#   * path require --allow-downgrade, and --allow-restore provide it
lives_ok  { check_path($migrate, ['l2','l1'], 0, 1) } 'restore allowed downgrade';
#   * path require --allow-restore, with/without it
throws_ok { check_path($migrate, ['l2a','l1'], 0, 0) } qr/--allow-restore/, 'restore not allowed';
throws_ok { check_path($migrate, ['l2a','l1'], 1, 0) } qr/--allow-restore/, 'restore not allowed';
#   * path require both --allow-downgrade and --allow-restore, with/without them
throws_ok { check_path($migrate, ['l3','l2a','l1','0.0.0'], 0, 0) } qr/--allow-downgrade/, 'downgrade not allowed';
throws_ok { check_path($migrate, ['l3','l2a','l1','0.0.0'], 1, 0) } qr/--allow-restore/, 'restore not allowed';
#   * path require restoring from backup, with/without it
throws_ok { check_path($migrate, ['l3','l2a','l1','0.0.0'], 0, 1) } qr/backup not found/, 'restore without backup';
path('.backup/full-l1.tar')->touch;
lives_ok  { check_path($migrate, ['l3','l2a','l1','0.0.0'], 0, 1) } 'restore with backup';


done_testing();


sub is_trace {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is_deeply [
        map {$_->{args}[0]}
        grep {$_->{type} ne 'VERSION' && $_->{cmd} eq 'true'}
        $migrate->get_steps($_[0])
    ], $_[1], $_[2] // "trace for [@{$_[0]}] is: @{$_[1]}";
}

use Test::More tests => 14;
use File::Spec;

BEGIN {
    use_ok( 'Path::Iter' );
}

diag( "Testing Path::Iter $Path::Iter::VERSION" );

chdir 't'; # just in case we're not already there
BAIL_OUT('I am not in the right place, sorry') if !-d 'path';

symlink('path','link');
BAIL_OUT('Could not make the symlink') if !-l 'link';

my @lookup_build = (
    [qw(dir.a)],
    [qw(file.b)],
    [qw(file.z)],
    [qw(dir.a dir.a)],
    [qw(dir.a dir.b)],
    [qw(dir.a file.x)],
    [qw(dir.a file.y)],
);

my %path_lookup = ( 'path' => 1, map { File::Spec->catdir('path',@{$_}) => 1 } @lookup_build );
my %link_lookup = ( 'link' => 1, map { File::Spec->catdir('link',@{$_}) => 1 } @lookup_build );
my @path_readdir_handler   = ( 'path', map { File::Spec->catdir('path',@{$_}) } @lookup_build );

my %results;
my $iter = Path::Iter::get_iterator('path/');
ok(ref $iter eq 'CODE', 'iterator is a code ref');

while(my $key = $iter->()) {
    # diag($key);
    $results{$key}++;
}
is_deeply(\%results, \%path_lookup, 'path traversal');
%results = ();
$iter = Path::Iter::get_iterator('link/');
while(my $key = $iter->()) {
    $results{$key}++;
}
is_deeply(\%results, { 'link' => 1 }, 'link - slash');

%results = ();
$iter = Path::Iter::get_iterator('link');
while(my $key = $iter->()) {
    $results{$key}++;
}
is_deeply(\%results, { 'link' => 1 }, 'link - no slash');

my %initial;
%results = ();
$iter = Path::Iter::get_iterator('link/', {'symlink_handler' => sub { return }, 'initial' => \%initial, });
while(my $key = $iter->()) {
    $results{$key}++;
}
ok(keys %initial == 1, 'initial arg populated');
ok(exists $initial{'link'}, 'arg cleaned');
is_deeply(\%results, { 'link' => 1 }, 'symlink not traversed w/ symlink_handler return false');

%initial = ();
%results = ();
$iter = Path::Iter::get_iterator('link', {'symlink_handler' => sub { return 1 }, 'initial' => \%initial, });
while(my $key = $iter->()) {
    $results{$key}++;
}
is_deeply(\%results, \%link_lookup, 'link traversal w/ symlink_handler return 1');

%initial = ();
%results = ();
$iter = Path::Iter::get_iterator('link', {'symlink_handler' => sub { return 2 }, 'initial' => \%initial, });
while(my $key = $iter->()) {
    $results{$key}++;
}
is_deeply(\%results, \%path_lookup, 'link traversal w/ symlink_handler return 2');
ok(!exists $initial{'link'}, 'arg change ! included');
ok(exists $initial{'path'}, 'arg change included');
ok(keys %initial == 1, 'arg change changed');

my @results;
$iter = Path::Iter::get_iterator('path/', { 'readdir_handler' => sub { my ($dir, @contents) = @_;  sort { $a cmp $b } @contents } });
while(my $key = $iter->()) {
    push @results, $key;
}
is_deeply(\@results, \@path_readdir_handler, 'readdir_handler');

# TODO: errors and stop_when_opendir_fails keys
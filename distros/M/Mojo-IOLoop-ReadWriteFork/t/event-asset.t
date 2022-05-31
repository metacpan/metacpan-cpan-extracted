use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

my $rwf = Mojo::IOLoop::ReadWriteFork->new;
my @assets;

$rwf->on(
  asset => sub {
    my ($rwf, $asset) = @_;
    $asset->max_memory_size(3) if $asset->can('max_memory_size');
    $rwf->write("line one\n") unless @assets;
    push @assets, $asset;
  }
);

$rwf->once(read => sub { shift->write("line two\n")->close('stdin'); });
$rwf->run_and_capture_p(sub { print while <> })->then(sub { push @assets, shift })->wait;

my $path = $assets[-1]->path;
like $assets[-1]->slurp, qr/line one\nline two\n/, 'finish';
isa_ok $_, 'Mojo::Asset' for @assets;
is @assets, 3, 'got three assets';
ok $path, 'got file asset';

my %subscribers = map { ($_ => $rwf->subscribers($_)) } qw(error finish read);
is_deeply \%subscribers, {error => [], finish => [], read => []}, 'run_and_capture_p clean up subscribers after run'
  or diag explain \%subscribers;

@assets = ();
ok !-e $path, 'file asset was cleaned up';

done_testing;

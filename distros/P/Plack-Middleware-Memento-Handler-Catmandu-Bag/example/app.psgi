use Catmandu::Sane;
use Catmandu;
use Plack::Builder;
use Plack::App::Catmandu::Bag;

Catmandu->define_store('example',
    Hash => (bags => {example => {plugins => ['Versioning', 'Datestamps']}}));

my $data = Catmandu->importer('JSON', file => 'example.json');
my $bag = Catmandu->store('example')->bag('example');
$bag->add_many($data);
$bag->commit;

my $app = Plack::App::Catmandu::Bag->new(
    store => 'example',
    bag => 'example',
)->to_app;

builder {
  enable 'Memento', handler => 'Catmandu::Bag', store => 'example', bag => 'example';
  $app
};

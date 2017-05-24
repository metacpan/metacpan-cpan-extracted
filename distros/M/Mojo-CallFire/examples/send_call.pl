use 5.010;
use Mojo::CallFire;

my $cf = Mojo::CallFire->new(username => '...', password => '...');
say $cf->post(calls => [{phoneNumber => '...', liveMessage => 'Test Call from Mojo CallFire'}])->result->body;

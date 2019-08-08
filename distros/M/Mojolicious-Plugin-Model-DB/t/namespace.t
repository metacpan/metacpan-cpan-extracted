use Test::Mojo;
use Test::More;
use Mojolicious::Lite;

plugin 'Model::DB' => {
    namespace => 'DataBase',
    namespaces => ['Local::Model']
};

get '/' => sub {
    my $c = shift;
    
    my $name = $c->db('person')->name;
    
    $c->render(text => $name);
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('Baz');

done_testing;

package Local::Model::DataBase::Person;
use Mojo::Base 'MojoX::Model';

sub name {
    return 'Baz';
}

1;
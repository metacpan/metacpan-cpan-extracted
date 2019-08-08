use Test::Mojo;
use Test::More;
use Mojolicious::Lite;

plugin 'Model::DB' => {namespaces => ['Local::Model']};

get '/' => sub {
    my $c = shift;
    
    my $name = $c->db('person')->name;
    $name = $c->model('func')->uppercase_first($name);
    
    $c->render(text => $name);
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('Foo');

done_testing;

package Local::Model::DB::Person;
use Mojo::Base 'MojoX::Model';

sub name {
    return 'foo';
}

1;

package Local::Model::Func;
use Mojo::Base 'MojoX::Model';

sub uppercase_first {
    return ucfirst($_[1]);
}

1;
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;

plugin 'Model::DB' => {
    namespaces => ['Local::Model'],
    SQLite     => 'sqlite:t/demo.db'
};

get '/:id/:type' => sub {
    my $c = shift;

    my $id = $c->param('id');
    my $type = $c->param('type');

    my $demo = $c->db('demo')->find($id);

    $c->render(text => $demo->{$type});
};

my $t = Test::Mojo->new;
$t->get_ok('/1/ID')->status_is(200)->content_is('1');
$t->get_ok('/1/Name')->status_is(200)->content_is('foo');
$t->get_ok('/1/Hint')->status_is(200)->content_is('Foo');
$t->get_ok('/2/ID')->status_is(200)->content_is('2');
$t->get_ok('/2/Name')->status_is(200)->content_is('baz');
$t->get_ok('/2/Hint')->status_is(200)->content_is('Baz');
$t->get_ok('/3/ID')->status_is(200)->content_is('3');
$t->get_ok('/3/Name')->status_is(200)->content_is('bar');
$t->get_ok('/3/Hint')->status_is(200)->content_is('Bar');
done_testing;

package Local::Model::DB::Demo;
use Mojo::Base 'MojoX::Model';

sub find {
    my ($self, $id) = @_;

    return $self->sqlite->db->select(
        'demo',
        undef,
        {
            id => $id
        }
    )->hash;
}

1;

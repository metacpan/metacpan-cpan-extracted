# SSODemoIdP

A [Punk](https://metacpan.org/pod/Punk) application.

## Run it

    plackup app.psgi

or, on the event-loop server Punk is built for:

    hyperman app.psgi

Then open <http://localhost:5000/>.

## Test it

    prove -l t/

## Layout

    lib/SSODemoIdP.pm                     routes and wiring
    lib/SSODemoIdP/Controller/Web/Root.pm the front page
    config/punk.yml                   views, database, plugins, secrets
    root/templates/                   Stencil templates
    root/static/                      files served at /static

## Where to go next

Add a route in `lib/SSODemoIdP.pm`:

    get '/hello/:name' => sub {
        my ($c) = @_;
        return $c->text('hello ' . $c->param('name'));
    };

Add a model - declare the connection in `config/punk.yml`, then:

    # lib/SSODemoIdP/Model/Thing.pm
    package SSODemoIdP::Model::Thing;
    use Punk::Model;

    table 'things';
    field id    => { type => 'integer' };
    field title => { type => 'string', required => 1 };

Models under `SSODemoIdP::Model::` are discovered automatically; reach one
with `$c->model('Thing')`.

See `perldoc Punk` for the full keyword list.

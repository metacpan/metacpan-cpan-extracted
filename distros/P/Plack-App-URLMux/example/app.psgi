use strict;
use Plack::App::URLMux;

my $app1 = sub {
    my $env = shift;
    my %params = @{$env->{'plack.urlmux.params.url'}};
    my $name = $params{name};
    [200, [ 'Content-Type' => 'text/plain' ], ["app1: name='$name' script_name='$env->{SCRIPT_NAME}' path_info='$env->{PATH_INFO}'"]]
};

my $app2 = sub {
    my $env = shift;
    my %params = @{$env->{'plack.urlmux.params.map'}};
    my $test = $params{test};
    [200, [ 'Content-Type' => 'text/plain' ], ["app2: test='$test' script_name='$env->{SCRIPT_NAME}' path_info='$env->{PATH_INFO}'"]]
};

my $app3 = sub {
    my $env = shift;
    [200, [ 'Content-Type' => 'text/plain' ], ["app3: script_name='$env->{SCRIPT_NAME}' path_info='$env->{PATH_INFO}'"]]
};

my $app4 = sub {
    my $env = shift;
    [200, [ 'Content-Type' => 'text/plain' ], ["app4: quantified script_name='$env->{SCRIPT_NAME}' path_info='$env->{PATH_INFO}'"]]
};

my $urlmap = Plack::App::URLMux->new;
$urlmap->map('/foo/:name/baz' => $app1);
$urlmap->map('/foo/bar/baz' => $app2, test=>'foo');
$urlmap->map('/foo/bar/foo' => $app3);

$urlmap->map('/one-or-more/:name+/baz' => $app4);
$urlmap->map('/none-or-more/:name*/baz' => $app4);
$urlmap->map('/none-or-one/:name?/baz' => $app4);
$urlmap->map('/n/:name{1}/baz' => $app4);
$urlmap->map('/n-or-more/:name{2,}/baz' => $app4);
$urlmap->map('/m/:name{2,3}/baz' => $app4);
$urlmap->map('/incorrect1/:name+*/baz' => $app4);
$urlmap->map('/incorrect2/:name*+/baz' => $app4);

my $app = $urlmap->to_app();



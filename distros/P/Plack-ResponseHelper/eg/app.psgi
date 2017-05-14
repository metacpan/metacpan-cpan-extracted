use Plack::ResponseHelper text => 'Text';
sub {
    respond text => 'Hello world!';
}

use Test::Chunks;

plan tests => ~~chunks;

run_is encoded => 'decoded';

__END__
=== Test One
--- encoded base64_decode
SSBMb3ZlIEx1Y3kK

--- decoded
I Love Lucy







=== Test Two

--- encoded
c3ViIHJ1bigmKSB7CiAgICBteSAkc2VsZiA9ICRkZWZhdWx0X29iamVjdDsKICAgIG15ICRjYWxs
YmFjayA9IHNoaWZ0OwogICAgZm9yIG15ICRjaHVuayAoJHNlbGYtPmNodW5rcykgewogICAgICAg
ICZ7JGNhbGxiYWNrfSgkY2h1bmspOwogICAgfQp9Cg==

--- decoded base64_encode

sub run(&) {
    my $self = $default_object;
    my $callback = shift;
    for my $chunk ($self->chunks) {
        &{$callback}($chunk);
    }
}



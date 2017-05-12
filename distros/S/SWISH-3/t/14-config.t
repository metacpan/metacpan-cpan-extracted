use Test::More tests => 75;
use strict;

use SWISH::3;

ok( my $s3 = SWISH::3->new(
        config => 't/t.conf'

    ),
    "new s3 object"
);

ok( my $config = $s3->config, "get config" );

#$config->debug;
#undef $config;
eval { $s3->set_config(undef) };
ok( $@, "set config with undef" );

eval { $s3->set_config( bless( {}, 'not_a_config' ) ) };
ok( $@, "set config with non-Config class" );

ok( my $properties = $s3->config->get_properties, "get properties" );

my %uniq;

for my $name ( sort @{ $properties->keys } ) {

    #diag($name);

    my $prop = $properties->get($name);

    #diag( "$name refcount = " . $prop->refcount );

    ok( !$uniq{ $prop->id }++, "uniq prop id" );
    is( $name, $prop->name, "prop name" );

    # test hash overloading
    is( $properties->{$name}->{id}, $prop->id, "hashref overloading" );
}

ok( my $metanames = $s3->config->get_metanames, "get metanames" );

%uniq = ();
for my $name ( sort @{ $metanames->keys } ) {

    my $meta = $metanames->get($name);

    ok( !$uniq{ $meta->id }++, "uniq meta id" );
    is( $name,                     $meta->name, "meta name" );
    is( $metanames->{$name}->{id}, $meta->id,   "hashref overloading" );
}

ok( my $index = $s3->config->get_index, "get index" );

my %indexv = (
    Format => 'Native',
    Locale => '(UTF-8|utf8)',
    Name   => 'index.swish'
);

for my $key ( sort keys %indexv ) {
    like( $index->get($key), qr/$indexv{$key}$/, "index $key" );
    like( $index->{$key},    qr/$indexv{$key}$/, "hashref overloading" );
}

# test merging
ok( $s3->config->add('<swish><foo>1</foo></swish>'), "add raw xml" );
ok( my $misc = $s3->config->get_misc(), "get_misc" );
ok( $misc->get('foo'), "config directive added" );
ok( $s3->config->merge('<swish><bar>2</bar></swish>'), "add raw xml bar" );
ok( $misc->get('bar'),                                 "get bar" );

# TODO test hash functions: delete, exists, set

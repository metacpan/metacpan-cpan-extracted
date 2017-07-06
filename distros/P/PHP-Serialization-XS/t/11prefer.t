use Test::More tests => 4;
BEGIN { use_ok('PHP::Serialization::XS') };

my $class = 'PHP::Serialization::XS';
my $pu = $class->new(prefer_undef => 1);
my $pa = $class->new(); # use default
my $ph = $class->new(prefer_hash  => 1);

my $x = q(a:1:{s:1:"x";a:0:{}});
is_deeply($pu->decode($x), { x => undef });
is_deeply($ph->decode($x), { x => {} } );
is_deeply($pa->decode($x), { x => [] } );


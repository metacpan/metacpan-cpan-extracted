use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Mojo::Collection 'c';

note 'Test get_keys';
my $c = c(1, 2, 3)->with_roles('+Transform');

is_deeply
    $c->hashify(sub { $_ }),
    { map { $_ => $_ } @$c },
    'default value sub uses value in collection'
    ;

is_deeply
    $c->hashify(sub { $_[0] }),
    { map { $_ => $_ } @$c },
    'collection value avaliable in get_keys as first argument'
    ;

is_deeply
    $c->hashify(sub { $_ * $_ }),
    { map { $_ * $_ => $_ } @$c },
    'get_keys sub uses returned value'
    ;

is_deeply
    $c->hashify(sub { $_, $_ * $_ }),
    { map { $_ => { $_ * $_ => $_} } @$c },
    'multiple keys can be returned'
    ;

note 'Test get_value';
is_deeply
    $c->hashify(sub { $_, $_ * $_ }, sub { $_ * $_ * $_ }),
    { map { $_ => { $_ * $_ => $_ * $_ * $_ } } @$c },
    'get_value sub used if provided'
    ;

is_deeply
    $c->hashify(sub { $_, $_ * $_ }, sub { $_[0] * $_[0] * $_[0] }),
    { map { $_ => { $_ * $_ => $_ * $_ * $_ } } @$c },
    'collection value avaliable in get_value as first argument'
    ;

note 'Test get_value returns multiple values throws';
throws_ok
    { $c->hashify(sub { $_ }, sub { ($_) x 2 }) }
    qr/multiple values returned from get_value sub when one is expected/,
    'multiple values returned from get_value throws (2 values returned)'
    ;

throws_ok
    { $c->hashify(sub { $_ }, sub { ($_) x 3 }) }
    qr/multiple values returned from get_value sub when one is expected/,
    'multiple values returned from get_value throws (3 values returned)'
    ;

done_testing;

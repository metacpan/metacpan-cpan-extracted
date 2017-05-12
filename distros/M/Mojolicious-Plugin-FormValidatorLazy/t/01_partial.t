use strict;
use warnings;
use utf8;
use Test::More tests => 26;
use Mojolicious::Plugin::FormValidatorLazy;

{
    no strict 'refs';
    *{__PACKAGE__. '::deserialize'} = \&Mojolicious::Plugin::FormValidatorLazy::deserialize;
    *{__PACKAGE__. '::serialize'} = \&Mojolicious::Plugin::FormValidatorLazy::serialize;
    *{__PACKAGE__. '::sign'} = \&Mojolicious::Plugin::FormValidatorLazy::sign;
    *{__PACKAGE__. '::unsign'} = \&Mojolicious::Plugin::FormValidatorLazy::unsign;
}

is sign(1, 'secret'), '1--51a1e4d3cd5e8b890b9cad1f46ba51e711c095d4', 'right value';
is sign(2, 'secret'), '2--a9b5b99e990a1f666ad589d7debf870dc12b5187', 'right value';
is unsign(sign(1, 'secret'), 'secret'), '1', 'right value';
is unsign(sign(2, 'secret'), 'secret'), '2', 'right value';
is unsign('2--51a1e4d3cd5e8b890b9cad1f46ba51e711c095d4', 'secret'), undef, 'right value';
is unsign('2--', 'secret'), undef, 'right value';
is unsign('2', 'secret'), undef, 'right value';
is serialize('a'), 'ImEi', 'right value';
is serialize(''), 'IiI=', 'right value';
is serialize(), undef, 'right value';
is serialize(undef), undef, 'right value';
is serialize(1), 'MQ==', 'right value';
is serialize('1'), 'IjEi', 'right value';
is_deeply deserialize(serialize(1)), '1', 'roundtrip ok';
is_deeply deserialize(serialize('1')), '1', 'roundtrip ok';
is_deeply deserialize(serialize('')), '', 'roundtrip ok';
is_deeply deserialize(serialize([])), [], 'roundtrip ok';
is_deeply deserialize(serialize({})), {}, 'roundtrip ok';
is_deeply deserialize(serialize(["'"])), ["'"], 'roundtrip ok';
is_deeply deserialize(serialize(["/"])), ["/"], 'roundtrip ok';
is_deeply deserialize(serialize(["\/"])), ["\/"], 'roundtrip ok';
is_deeply deserialize(serialize(["\""])), ["\""], 'roundtrip ok';
is_deeply deserialize(serialize(["\\\""])), ["\\\""], 'roundtrip ok';
is_deeply deserialize(serialize(["\\\/"])), ["\\\/"], 'roundtrip ok';
is_deeply deserialize(serialize(["\/\/"])), ["\/\/"], 'roundtrip ok';
is_deeply deserialize(serialize(["やったー"])), ["やったー"], 'roundtrip ok';

__END__

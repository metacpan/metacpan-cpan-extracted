use Test2::V0;

use lib 't/lib';

use Sub::Meta;
use MySubMeta::Param;

sub param {
    my @args = @_;
    return Sub::Meta::Param->new(@args)
}

my $parameters = Sub::Meta::Parameters->new(args => []);
is $parameters->nshift, 0;
is $parameters->invocant, undef, 'no invocant';

is $parameters->set_nshift(1), $parameters, 'if set nshift';
is $parameters->nshift, 1;
is $parameters->invocant, param(invocant => 1), 'then set default invocant';

like dies { $parameters->set_nshift(2) }, qr/^Can't set this nshift: /, $parameters;
like dies { $parameters->set_nshift(undef) }, qr/^Can't set this nshift: /, $parameters;

is $parameters->set_nshift(0), $parameters, 'if set nshift:0';
is $parameters->invocant, undef, 'then remove invocant';

is $parameters->set_invocant(param(name => '$self')), $parameters, 'if set original invocant';
is $parameters->invocant, param(name => '$self', invocant => 1), 'then original with invocant flag';

is $parameters->set_invocant({ name => '$class'}), $parameters, 'set_invocant can take hashref';
is $parameters->invocant, param(name => '$class', invocant => 1);

my $some = bless {}, 'Some';
is $parameters->set_invocant($some), $parameters, 'set_invocant can take type';
is $parameters->invocant, param(type=> $some, invocant => 1);

my $myparam = MySubMeta::Param->new(name => '$self');
is $parameters->set_invocant($myparam), $parameters, 'set_invocant can take your Sub::Meta::Param';
is $parameters->invocant, $myparam->set_invocant(1);

done_testing;

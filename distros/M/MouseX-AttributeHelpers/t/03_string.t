use Test::More tests => 26;
use Test::Deep;

do {
    package MyClass;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'string' => (
        metaclass => 'String',
        is        => 'rw',
        isa       => 'Str',
        default   => '',
        provides  => {
            inc     => 'inc_string',
            append  => 'append_string',
            prepend => 'prepend_string',
            match   => 'match_string',
            replace => 'replace_string',
            chop    => 'chop_string',
            chomp   => 'chomp_string',
            clear   => 'clear_string',
        },
        curries   => {
            append  => { exclaim         => [ '!' ] },
            replace => { capitalize_last => [ qr/(.)$/, sub { uc $1 } ] },
            match   => { invalid_number  => [ qr/\D/ ] }
        }
    );
};

my $obj = MyClass->new;

my @providers = qw(
    inc_string append_string prepend_string match_string
    replace_string chop_string chomp_string clear_string
);
for my $method (@providers) {
    can_ok $obj => $method;
}

my @curries = qw(exclaim capitalize_last invalid_number);
for my $method (@curries) {
    can_ok $obj => $method;
}

is $obj->string => '', 'get default value ok';

# provides
$obj->string('a');
$obj->inc_string;
is $obj->string => 'b', 'increment string ok';

$obj->inc_string;
is $obj->string => 'c', 'increment string again ok';

$obj->append_string("foo$/");
is $obj->string => "cfoo$/", 'append string ok';

$obj->chomp_string;
is $obj->string => 'cfoo', 'chomp string ok';

$obj->chomp_string;
is $obj->string => 'cfoo', 'chomp is noop';

$obj->chop_string;
is $obj->string => 'cfo', 'chop string ok';

$obj->prepend_string('bar');
is $obj->string => 'barcfo', 'prepend string ok';

cmp_deeply [ $obj->match_string(qr/([ao])/) ] => [ 'a' ], 'match string ok';

$obj->replace_string(qr/([ao])/ => sub { uc($1) });
is $obj->string => 'bArcfo', 'replace string ok';

$obj->clear_string;
is $obj->string => '', 'clear string ok';

# curries
$obj->string('Mousex');
$obj->capitalize_last;
is $obj->string => 'MouseX', 'curries capitalize_last ok';

$obj->exclaim;
is $obj->string => 'MouseX!', 'curries exclaim ok';

$obj->string('1234');
ok !$obj->invalid_number, 'curries invalid_number ok';

$obj->string('one two three four');
ok $obj->invalid_number, 'curries invalid_number again ok';


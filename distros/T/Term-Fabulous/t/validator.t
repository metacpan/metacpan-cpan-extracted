use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use utf8;

use Test2::V0;

use Object::Pad 0.825;

use Term::Fabulous::Static;
use Term::Fabulous::Validator;
use Term::Fabulous::Widget::Input;

# An input that only navigates and holds no value of its own.
class Navigator :isa(Term::Fabulous::Widget::Input) :strict(params) {
	method natural_size () { return ( 3, 1 ) }

	method paint () {
		$self->paint_text( 0, 0, 'nav', $self->foreground_attr, undef );
		return;
	}
}

my $class = 'Term::Fabulous::Validator';

sub coerced (@spec) {
	return $class->coerce(@spec);
}

subtest 'named validators accept and reject' => sub {
	my %examples = (
		email    => [ [ 'ada@example.com', 'a.b+c@sub.example.org' ], [ 'ada', 'ada@example', 'a @example.com', '@example.com' ] ],
		integer  => [ [ '0', '42', '-7' ],                            [ '', '4.2', '1e3', 'x', '+3' ] ],
		number   => [ [ '0', '-3.5', '.5', '3.' ],                    [ '.', '1,5', 'x', '--1' ] ],
		url      => [ [ 'https://example.com/a?b=c', 'ftp://x' ],     [ 'example.com', 'http//x', 'http://a b' ] ],
		hostname => [ [ 'localhost', 'a-b.example.com', 'x.' ],       [ '-a.com', 'a_b', 'a..b', 'a' x 64 . '.com' ] ],
		ip       => [ [ '127.0.0.1', '::1', '2001:db8::ff00:42' ],    [ '1.2.3', '256.1.1.1', 'localhost', '1.2.3.4.5' ] ],
		date     => [ [ '2024-02-29', '1999-12-31' ],                 [ '2026-02-29', '2026-13-01', '2026-04-31', '26-1-1' ] ],
		time     => [ [ '00:00', '23:59', '12:30:15' ],               [ '24:00', '12:60', '9:30', '12:30:60' ] ],
	);
	foreach my $name ( sort keys %examples ) {
		my ( $valid, $invalid ) = @{ $examples{$name} };
		my $validator = coerced($name);
		is $validator->name, $name, "$name: the name";
		is $validator->check($_), undef, "$name accepts '$_'" foreach @$valid;
		like $validator->check($_), qr/\APlease /, "$name rejects '$_'" foreach @$invalid;
	}
};

subtest 'messages and ranges' => sub {
	is coerced('email')->check('x'),                    'Please enter an e-mail address.', 'the default message';
	is $class->email( message => 'Mail?' )->check('x'), 'Mail?',                           'a message option replaces it';

	my $port = $class->integer( min => 1, max => 65535 );
	is $port->check('80'),                       undef,                                              'within the range';
	is $port->check('0'),                        'Please enter a whole number between 1 and 65535.', 'below it, with the range in the message';
	is $port->check('70000'),                    'Please enter a whole number between 1 and 65535.', 'above it';
	is $class->number( min => 0 )->check('-1'),  'Please enter a number at least 0.',                'a lower bound only';
	is $class->integer( max => 9 )->check('10'), 'Please enter a whole number at most 9.',           'an upper bound only';
	like dies { $class->integer( min => 5, max => 1 ) }, qr/min 5 is above max 1/, 'a reversed range dies';
	like dies { $class->integer( min => 'x' ) },         qr/integer min must be/,  'a non-numeric bound dies';
	like dies { $class->email( color => 'red' ) }, qr/does not take color/, 'an unknown option dies';
};

subtest 'suggested accept' => sub {
	is coerced('integer')->accept, '0-9-',  'integer suggests digits and the minus sign';
	is coerced('number')->accept,  '0-9.-', 'number adds the dot';
	is coerced('date')->accept,    '0-9-',  'date';
	is coerced('time')->accept,    '0-9:',  'time';
	is coerced('email')->accept,   undef,   'email suggests nothing';
};

subtest 'pattern, code and all' => sub {
	my $pattern = coerced(qr/\A[A-Z]{3}\z/);
	is $pattern->name,         'pattern',                           'a regular expression becomes a pattern';
	is $pattern->check('ABC'), undef,                               'matching is valid';
	is $pattern->check('ab'),  'Please match the expected format.', 'not matching gives the default message';

	my $even = coerced( sub ($value) { $value % 2 ? 'Odd!' : undef } );
	is $even->name,                                                 'code',           'a code reference becomes a code validator';
	is $even->check('2'),                                           undef,            'false means valid';
	is $even->check('3'),                                           'Odd!',           'a string is the message';
	is $class->code( sub { 1 } )->check('x'),                       'Invalid value.', 'a bare true value gives the default message';
	is $class->code( sub { 1 }, message => 'No.' )->check('x'),     'No.',            'or the message option';
	is $class->code( sub { 'Bad' }, message => 'No.' )->check('x'), 'Bad',            'a returned string wins over the message option';

	my $all = coerced( [ 'hostname', qr/\.example\.com\z/ ] );
	is $all->name,                                 'all',                               'a list becomes all';
	is $all->check('www.example.com'),             undef,                               'all pass';
	is $all->check('-x.example.com'),              'Please enter a host name.',         'the first failing message wins';
	is $all->check('www.example.org'),             'Please match the expected format.', 'the second is checked after the first';
	is $all->accept,                               undef,                               'no suggestion among them';
	is coerced( [ 'integer', 'number' ] )->accept, '0-9-',                              'the first suggestion among them';
	is coerced( ['email'] )->name,                 'email',                             'a list of one is that validator';
	like dies { $class->all }, qr/at least one/, 'an empty list dies';
};

subtest 'coerce' => sub {
	my $validator = coerced('email');
	is coerced($validator), exact_ref($validator),                                'a validator is returned as it is';
	is coerced(undef),      undef,                                                'undef stays undef';
	is [ $class->names ],   [qw(email integer number url hostname ip date time)], 'the names';
	like dies { coerced('mail') },                                        qr/unknown validator 'mail'; the names are email, integer/, 'an unknown name dies with the list';
	like dies { coerced( {} ) },                                          qr/got a HASH reference/,                                   'a hash reference dies';
	like dies { $class->pattern('x') },                                   qr/pattern takes a regular expression/,                     'pattern wants a regexp';
	like dies { $class->code('x') },                                      qr/code takes a code reference/,                            'code wants code';
	like dies { $class->new( name => 'x', message => 'm', check => 1 ) }, qr/check must be a code reference/,                         'new checks its code';
};

subtest 'an input without a value of its own' => sub {
	my $navigator = Navigator->new;
	is $navigator->value, undef, 'its value is undef';
	ok $navigator->is_valid, 'and valid';
	is [ Term::Fabulous::Static->new( root => $navigator, width => 3 )->render_lines( colors => 0 ) ], ['nav'], 'so it paints';
	$navigator->required(1);
	ok !$navigator->is_valid, 'unless it is required';
};

done_testing;

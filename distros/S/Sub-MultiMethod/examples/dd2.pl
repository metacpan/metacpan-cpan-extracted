#! /usr/bin/env perl

BEGIN{ package MyClass; sub dd() { return '(MyClass)' } }

{
	package Local::MD;

	use v5.22;
	use warnings;
	use experimental 'refaliasing';
	use Scalar::Util 1.14 'looks_like_number';

	use Multi::Dispatch;
	use Types::Standard qw< Num Object >;

	# Create a mini Data::Dumper clone that outputs in void context...
	multi dd :before :where(VOID) (@data)  { say &next::variant }

	# Format pairs and array/hash references...
	multi dd ($k, $v)  { dd($k) . ' => ' . dd($v) }
	multi dd (\@data)  { '[' . join(', ', map {dd($_)}                 @data) . ']' }
	multi dd (\%data)  { '{' . join(', ', map {dd($_, $data{$_})} keys %data) . '}' }

	# Format strings, numbers, regexen...
	multi dd ($data)                             { '"' . quotemeta($data) . '"' }
	multi dd ($data :where(\&looks_like_number)) { $data }
	multi dd ($data :where(Regexp))              { 'qr{' . $data . '}' }

	# Format objects...
	multi dd (Object $data)               { '<' .ref($data).' object>' }
	multi dd (Object $data -> can('dd'))  { $data->dd(); }

	# Format typeglobs...
	multi dd (GLOB $data)                { "" . *$data }
}

{
	package Local::SMM;

	use v5.10;
	use strict;
	use warnings;

	use Types::Common -types;
	use Sub::MultiMethod 'multifunction' => { -as => 'multi' };

	# Format pairs and array/hash references...

	# Create a mini Data::Dumper clone that outputs in void context...
	multi dd => (
		want => 'VOID',
		code => sub { say dd(@_) },
	);

	multi dd => (
		pos  => [ Str, Any ],
		code => sub { dd_str(shift) . ' => ' . dd(shift) },
	);

	multi dd => (
		pos  => [ ArrayRef ],
		code => sub { '[' . join(', ', map {dd($_)} @{+shift}) . ']' },
	);

	multi dd => (
		pos  => [ HashRef ],
		code => sub { '{' . join(', ', map {dd($_, $_[0]{$_})} keys %{$_[0]}) . '}' },
	);

	# Format strings, numbers, regexen...

	multi dd => (
		pos  => [ Str ],
		code => sub { '"' . quotemeta(shift) . '"' },
		alias => 'dd_str',
	);

	multi dd => (
		pos  => [ Num ],
		code => sub { 0 + shift },
	);

	multi dd => (
		pos  => [ RegexpRef ],
		code => sub { 'qr{' . shift . '}' },
	);

	# Format objects...

	multi dd => (
		pos  => [ Object ],
		code => sub { '<' . ref(shift) . ' object>' },
	);

	multi dd => (
		pos  => [ HasMethods['dd'] ],
		code => sub { shift->dd },
	);

	multi dd => (
		pos  => [ Ref['GLOB'] ],
		code => sub { '' . *{+shift} },
	);
}

package main;

my @cases = (
	[ 3.1415926 ],
	[ 'string' ],
	[ qr{ \A \d* \h (?= \d) }xms ],
	[ [0..2] ],
	[ { a=>1, b=>2, z=>[3, 'three', 3] } ],
	[ \*STDERR ],
	[ bless {}, 'MyClass' ],
	[ Object ],
	['label' => { a=>1, b=>2, z=>[3, 'three', 3] } ],
);

for my $case ( @cases ) {
	my $got1 = Local::MD::dd( @$case );
	my $got2 = Local::SMM::dd( @$case );
	$got1 eq $got2 or warn "$got1 vs $got2";
}

our $test_data = [ 'label' => { a=>1, b=>2, z=>[3, 'three', 3] }, 'label2' => qr{foo} ];

use Benchmark 'cmpthese';

Local::MD::dd($main::test_data);
Local::SMM::dd($main::test_data);

cmpthese -3 => {
	MD  => q{ my $x = Local::MD::dd($main::test_data) },
	SMM => q{ my $x = Local::SMM::dd($main::test_data) },
};

use B::Deparse;
#print B::Deparse->new->coderef2text( \&Local::MD::dd );
#print B::Deparse->new->coderef2text( \&Local::SMM::dd );

use strict;
use warnings;
use Test::More;

use Sub::HandlesVia::CodeGenerator;
use Sub::HandlesVia::HandlerLibrary::Array;

my $gen = 'Sub::HandlesVia::CodeGenerator'->new(
	toolkit               => __PACKAGE__,
	target                => 'My::Class',
	attribute             => 'attr',
	env                   => {},
	coerce                => !!0,
	generator_for_slot    => sub { my $self = shift->generate_self; "$self\->{attr}" },
	generator_for_get     => sub { my $self = shift->generate_self; "$self\->{attr}" },
	generator_for_set     => sub { my $self = shift->generate_self; "( $self\->{attr} = @_ )" },
	get_is_lvalue         => !!0,
	set_checks_isa        => !!1,
	set_strictly          => !!1,
	generator_for_default => sub { 'undef' },
	generator_for_prelude => sub { 'my $GUARD = undef;' },
);

my $push    = 'Sub::HandlesVia::HandlerLibrary::Array'->get_handler( 'push' );
my $ec_args = $gen->_generate_ec_args_for_handler( 'my_push', $push );
my $coderef = $gen->generate_coderef_for_handler( 'my_push', $push );

my ( $found ) = grep /GUARD/, @{ $ec_args->{source} };
is( $found, 'my $GUARD = undef;' );

my $foo = bless { attr => [] }, 'My::Class';
$foo->$coderef( 1, 2, 3 );
$foo->$coderef( 4 );
is_deeply( $foo->{attr}, [1..4] );

done_testing;
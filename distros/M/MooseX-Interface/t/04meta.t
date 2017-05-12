use Data::Dumper;
use Test::More tests => 4;
use Test::Exception;

{
	package LoggerAPI;
	use MooseX::Interface;
	requires log => ['Str'];
	one;
}

{
	package ArrayLogger;
	use Moose;
	with 'LoggerAPI';
	has logged => (
		is      => 'ro',
		isa     => 'ArrayRef',
		default => sub { [] },
	);
	sub log
	{
		my ($self, $message) = @_;
		push @{ $self->logged }, $message;
	}
	__PACKAGE__->meta->make_immutable;
}

my ($required) = LoggerAPI->meta->get_required_method_list;
is($required->name, 'log');
is_deeply($required->signature, ['Str']);

my $logger = ArrayLogger->new;
$logger->log($_) for qw(Hello World);
is_deeply($logger->logged, [qw(Hello World)]);

throws_ok {
	$logger->log( [] );
} qr{did not conform to signature defined in interface};

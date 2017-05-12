use Test::More tests => 5;

BEGIN{
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

{
	package TestPackage1;
	
	use metaclass (
		metaclass   => 'Moose::Meta::Class',
		error_class => 'MooseX::Error::Exception::Class',
	);
	use Moose 0.88;
	
	has attributes => (
		is       => 'ro',
		isa      => 'Int',
		reader   => 'get_attributes',
		required => 1,
	);
	
	no Moose;
	__PACKAGE__->meta->make_immutable;

}

eval { TestPackage1->new(); };
my $no_attr = $EVAL_ERROR;

like($no_attr, qr{Attribute \(attributes\) is required}, 'Error #1 gives the expected text');
isa_ok($no_attr, 'Exception::Moose', 'Error #1');

eval { TestPackage1->new(attributes => 'Bad'); };
my $bad_attr = $EVAL_ERROR;

like($bad_attr, qr{'attributes' not Int}, 'Error #2 gives the expected text');
isa_ok($bad_attr, 'Exception::Moose::Validation', 'Error #2');
isa_ok($bad_attr, 'Exception::Moose', 'Error 2');
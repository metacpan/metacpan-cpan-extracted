use Test::More;

my ($pass1, $pass2, $pass3);

BEGIN {
	package Local::Aspect1;
	no thanks;
	use MooseX::Aspect;
	
	create_join_point 'quux';
	
	apply_to 'Local::Class1', role {
		before qr{foo} => sub {
			$pass1++;
		};
		whenever [qr{quux}] => sub {
			$pass2++ if $_[1] eq 'monkey';
		};
	};
	
	optionally_apply_to 'Local::Class1', role {
		whenever quux => sub {
			$pass3++ if $_[1] eq 'ape';
		};
	};
};

BEGIN {
	package Local::Class1;
	no thanks;
	use Moose;
	use MooseX::Aspect::Util qw( join_point );
	sub foo {
		join_point 'Local::Aspect1' => qw( quux );
	}
};

ok not (
	Local::Class1->meta->can('employs_aspect') &&
	Local::Class1->meta->employs_aspect('Local::Aspect1')
);

Local::Aspect1->setup;
ok( Local::Class1->meta->employs_aspect('Local::Aspect1') );

Local::Class1->new->foo('monkey');
Local::Class1->new->foo('ape');

ok  $pass1;
ok  $pass2;
ok !$pass3;

Local::Aspect1->setup('Local::Class1');

Local::Class1->new->foo('ape');
ok  $pass3;

done_testing();


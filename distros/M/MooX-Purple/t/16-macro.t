use Test::More;
use MooX::Purple -prefix => 'Macro';
use MooX::Purple::G -prefix => 'Macro', -lib => 't/lib';

class +Simple {
	macro generic {
		return 'not';
	};
	macro second {
		my $x = 0;
		$x++ for (0..100);
		return $x;
	};
	trigger one {
		print "trigger\n";
		return 'crazy';
	}
	start one {
		print "before\n";
	}
	end one {
		print "after\n";
	}
	during one {
		print "around\n";
		$self->$orig();
	};
	public one { &generic; }
	public two { &second; }
};

class +Inherit is +Simple {};

my $simple = Macro::Simple->new();

is($simple->one, 'crazy');
is($simple->two, 101);

$simple = Macro::Inherit->new();
is($simple->one, 'crazy');
is($simple->two, 101);

done_testing();

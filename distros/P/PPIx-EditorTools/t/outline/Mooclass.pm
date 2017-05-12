use MooseX::Declare;

class Mooclass {

	has 'moo_att' => ( is => 'rw', );

	has [qw/ label progress butWarn butTime start_stop /] =>
		( isa => 'Ref', is => 'rw' );

	has qw(account) => ( is => 'rw', );
	
	has non_quoted_attr => ( is=> 'rw' ); 

	method pub_sub {
		return;
	}

	method _pri_sub {
		return;
	}

	before mm_before {
		return;
	}

	after mm_after {
		return;
	}
	
	around mm_around {
		return;
	}
	
	override mm_override {
		return;
	}
	
	augment mm_augment {
		return;
	}
}


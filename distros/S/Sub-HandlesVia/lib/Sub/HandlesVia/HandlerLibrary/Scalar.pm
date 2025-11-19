use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary::Scalar;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.050007';

use Sub::HandlesVia::HandlerLibrary;
our @ISA = 'Sub::HandlesVia::HandlerLibrary';

use Sub::HandlesVia::Handler qw( handler );
our @METHODS = qw(
	scalar_reference make_getter make_setter get set
	stringify
);

sub scalar_reference {
	handler
		name      => 'Scalar:scalar_reference',
		args      => 0,
		template  => '$GET;\\($SLOT)',
		documentation => "Returns a scalar reference to the attribute value's slot within its object.",
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => 10 );\n",
				"  my \$ref = \$object->$method;\n",
				"  \$\$ref++;\n",
				"  say \$object->$attr; ## ==> 11\n",
				"\n";
		},
		allow_getter_shortcuts => 0,
}

sub make_getter {
	handler
		name      => 'Scalar:make_getter',
		args      => 0,
		template  => 'my $s = $SELF; sub { unshift @_, $s; $GET }',
		documentation => "Returns a getter coderef.",
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => 10 );\n",
				"  my \$getter = \$object->$method;\n",
				"  \$object->_set_$attr( 11 );\n",
				"  say \$getter->(); ## ==> 11\n",
				"\n";
		},
		allow_getter_shortcuts => 0,
}

sub make_setter {
	handler
		name      => 'Scalar:make_setter',
		args      => 0,
		template  => 'my $s = $SELF; sub { my $val = shift; unshift @_, $s; « $val » }',
		documentation => "Returns a setter coderef.",
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => 10 );\n",
				"  my \$setter = \$object->$method;\n",
				"  \$setter->( 11 );\n",
				"  say \$object->$attr; ## ==> 11\n",
				"\n";
		},
		allow_getter_shortcuts => 0,
}

sub get {
	handler
		name      => 'Scalar:get',
		args      => 0,
		template  => '$GET',
		documentation => "Gets the current value of the scalar.",
		allow_getter_shortcuts => 0,
}

sub set {
	handler
		name      => 'Scalar:set',
		args      => 1,
		template  => '« $ARG »',
		lvalue_template => '$GET = $ARG',
		usage     => '$value',
		documentation => "Sets the scalar to a new value.",
}

sub stringify {
	handler
		name      => 'Scalar:stringify',
		args      => 0,
		template  => 'do { my $shv_tmp = $GET; sprintf q(%s), $shv_tmp; }',
		documentation => "Gets the current value of the scalar, but as a string.",
		allow_getter_shortcuts => 0,
}

1;

use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary::Bool;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.050003';

use Sub::HandlesVia::HandlerLibrary;
our @ISA = 'Sub::HandlesVia::HandlerLibrary';

use Sub::HandlesVia::Handler qw( handler );
our @METHODS = qw( set unset toggle not reset );

sub set {
	handler
		name      => 'Bool:set',
		args      => 0,
		template  => '« !!1 »',
		documentation => 'Sets the value of the boolean to true.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$object = $class\->new();\n",
				"  \$object->$method\();\n",
				"  say \$object->$attr; ## ==> true\n",
				"\n";
		},
}

sub unset {
	handler
		name      => 'Bool:unset',
		args      => 0,
		template  => '« !!0 »',
		documentation => 'Sets the value of the boolean to false.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$object = $class\->new();\n",
				"  \$object->$method\();\n",
				"  say \$object->$attr; ## ==> false\n",
				"\n";
		},
}

sub toggle {
	handler
		name      => 'Bool:toggle',
		args      => 0,
		template  => '« !$GET »',
		documentation => 'Toggles the truth value of the boolean.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$object = $class\->new();\n",
				"  \$object->$method\();\n",
				"  say \$object->$attr; ## ==> true\n",
				"  \$object->$method\();\n",
				"  say \$object->$attr; ## ==> false\n",
				"\n";
		},
}

sub not {
	handler
		name      => 'Bool:not',
		args      => 0,
		template  => '!$GET',
		documentation => 'Returns the opposite value of the boolean.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$object = $class\->new( $attr => 1 );\n",
				"  say \$object->$method\(); ## ==> false\n",
				"\n";
		},
}

sub reset {
	handler
		name      => 'Bool:reset',
		args      => 0,
		template  => '« $DEFAULT »',
		default_for_reset => sub { 0 },
		documentation => 'Sets the boolean to its default value, or false if it has no default.',
}

1;

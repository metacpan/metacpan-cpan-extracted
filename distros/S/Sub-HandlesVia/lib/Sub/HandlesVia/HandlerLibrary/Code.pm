use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary::Code;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.032';

use Sub::HandlesVia::HandlerLibrary;
our @ISA = 'Sub::HandlesVia::HandlerLibrary';

use Sub::HandlesVia::Handler qw( handler );
our @METHODS = qw( execute execute_method );

sub execute {
	handler
		name      => 'Code:execute',
		template  => '$GET->(@ARG)',
		usage     => '@args',
		prefer_shift_self => 1,
		documentation => 'Calls the coderef, passing it any arguments.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$coderef = sub { 'code' };\n",
				"  my \$object  = $class\->new( $attr => \$coderef );\n",
				"  \n",
				"  # \$coderef->( 1, 2, 3 )\n",
				"  \$object->$method\( 1, 2, 3 );\n",
				"\n";
		},
}

sub execute_method {
	handler
		name      => 'Code:execute_method',
		template  => '$GET->($SELF, @ARG)',
		prefer_shift_self => 1,
		usage     => '@args',
		documentation => 'Calls the coderef as if it were a method, passing any arguments.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$coderef = sub { 'code' };\n",
				"  my \$object  = $class\->new( $attr => \$coderef );\n",
				"  \n",
				"  # \$coderef->( \$object, 1, 2, 3 )\n",
				"  \$object->$method\( 1, 2, 3 );\n",
				"\n";
		},
}

1;

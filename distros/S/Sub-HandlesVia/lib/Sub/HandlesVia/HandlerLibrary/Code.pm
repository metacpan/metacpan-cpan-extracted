use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary::Code;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.052000';

use Sub::HandlesVia::HandlerLibrary;
our @ISA = 'Sub::HandlesVia::HandlerLibrary';

use Sub::HandlesVia::Handler qw( handler );
our @METHODS = qw(
	execute         execute_method
	execute_list    execute_method_list
	execute_scalar  execute_method_scalar
	execute_void    execute_method_void
);

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
				"  # Calls: \$coderef->( 1, 2, 3 )\n",
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
				"  # Calls: \$coderef->( \$object, 1, 2, 3 )\n",
				"  \$object->$method\( 1, 2, 3 );\n",
				"\n";
		},
}

sub execute_list {
	handler
		name      => 'Code:execute_list',
		template  => 'my @shv_list = $GET->(@ARG); wantarray ? @shv_list : \@shv_list',
		usage     => '@args',
		prefer_shift_self => 1,
		documentation => 'Calls the coderef, passing it any arguments, and forcing list context. If called in scalar context, returns an arrayref.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$context;\n",
				"  my \$coderef = sub { \$context = wantarray(); 'code' };\n",
				"  my \$object  = $class\->new( $attr => \$coderef );\n",
				"  \n",
				"  # Calls: \$coderef->( 1, 2, 3 )\n",
				"  my \$result = \$object->$method\( 1, 2, 3 );\n",
				"  \n",
				"  say Dumper( \$result );  ## ==> [ 'code' ]\n",
				"  say \$context;           ## ==> true\n",
				"\n";
		},
}

sub execute_method_list {
	handler
		name      => 'Code:execute_method_list',
		template  => 'my @shv_list = $GET->($SELF, @ARG); wantarray ? @shv_list : \@shv_list',
		prefer_shift_self => 1,
		usage     => '@args',
		documentation => 'Calls the coderef as if it were a method, passing any arguments, and forcing list context. If called in scalar context, returns an arrayref.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$context;\n",
				"  my \$coderef = sub { \$context = wantarray(); 'code' };\n",
				"  my \$object  = $class\->new( $attr => \$coderef );\n",
				"  \n",
				"  # Calls: \$coderef->( \$object, 1, 2, 3 )\n",
				"  my \$result = \$object->$method\( 1, 2, 3 );\n",
				"  \n",
				"  say Dumper( \$result );  ## ==> [ 'code' ]\n",
				"  say \$context;           ## ==> true\n",
				"\n";
		},
}

sub execute_scalar {
	handler
		name      => 'Code:execute_scalar',
		template  => 'scalar( $GET->(@ARG) )',
		usage     => '@args',
		prefer_shift_self => 1,
		documentation => 'Calls the coderef, passing it any arguments, and forcing scalar context.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$context;\n",
				"  my \$coderef = sub { \$context = wantarray(); 'code' };\n",
				"  my \$object  = $class\->new( $attr => \$coderef );\n",
				"  \n",
				"  # Calls: \$coderef->( 1, 2, 3 )\n",
				"  my \$result = \$object->$method\( 1, 2, 3 );\n",
				"  \n",
				"  say \$result;  ## ==> 'code'\n",
				"  say \$context; ## ==> false\n",
				"\n";
		},
}

sub execute_method_scalar {
	handler
		name      => 'Code:execute_method_scalar',
		template  => 'scalar( $GET->($SELF, @ARG) )',
		prefer_shift_self => 1,
		usage     => '@args',
		documentation => 'Calls the coderef as if it were a method, passing any arguments, and forcing scalar context.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$context;\n",
				"  my \$coderef = sub { \$context = wantarray(); 'code' };\n",
				"  my \$object  = $class\->new( $attr => \$coderef );\n",
				"  \n",
				"  # Calls: \$coderef->( \$object, 1, 2, 3 )\n",
				"  my \$result = \$object->$method\( 1, 2, 3 );\n",
				"  \n",
				"  say \$result;  ## ==> 'code'\n",
				"  say \$context; ## ==> false\n",
				"\n";
		},
}

sub execute_void {
	handler
		name      => 'Code:execute_void',
		template  => '$GET->(@ARG); undef',
		usage     => '@args',
		prefer_shift_self => 1,
		documentation => 'Calls the coderef, passing it any arguments, and forcing void context. Returns undef.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$context;\n",
				"  my \$coderef = sub { \$context = wantarray(); 'code' };\n",
				"  my \$object  = $class\->new( $attr => \$coderef );\n",
				"  \n",
				"  # Calls: \$coderef->( 1, 2, 3 )\n",
				"  my \$result = \$object->$method\( 1, 2, 3 );\n",
				"  \n",
				"  say \$result;  ## ==> undef\n",
				"  say \$context; ## ==> undef\n",
				"\n";
		},
}

sub execute_method_void {
	handler
		name      => 'Code:execute_method_void',
		template  => '$GET->($SELF, @ARG); undef',
		prefer_shift_self => 1,
		usage     => '@args',
		documentation => 'Calls the coderef as if it were a method, passing any arguments, and forcing void context. Returns undef.',
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$context;\n",
				"  my \$coderef = sub { \$context = wantarray(); 'code' };\n",
				"  my \$object  = $class\->new( $attr => \$coderef );\n",
				"  \n",
				"  # Calls: \$coderef->( \$object, 1, 2, 3 )\n",
				"  my \$result = \$object->$method\( 1, 2, 3 );\n",
				"  \n",
				"  say \$result;  ## ==> undef\n",
				"  say \$context; ## ==> undef\n",
				"\n";
		},
}

1;

use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary::String;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.052000';

use Sub::HandlesVia::HandlerLibrary;
our @ISA = 'Sub::HandlesVia::HandlerLibrary';

use Sub::HandlesVia::Handler qw( handler );
use Types::Standard qw( Optional Str CodeRef RegexpRef Int Any Item Defined );

our @METHODS = qw(
	set get inc append prepend chop chomp trim clear reset
	length substr replace replace_globally uc lc fc
	starts_with   ends_with   contains   match   cmp  eq  ne  gt  lt  ge  le
	starts_with_i ends_with_i contains_i match_i cmpi eqi nei gti lti gei lei
);

my $fold = ( $] >= 5.016 ) ? 'CORE::fc' : 'lc';

sub _type_inspector {
	my ($me, $type) = @_;
	if ($type == Str or $type == Defined) {
		return {
			trust_mutated => 'always',
		};
	}
	return $me->SUPER::_type_inspector($type);
}

sub set {
	handler
		name      => 'String:set',
		args      => 1,
		signature => [Str],
		template  => '« $ARG »',
		lvalue_template => '$GET = $ARG',
		usage     => '$value',
		documentation => "Sets the string to a new value.",
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$object = $class\->new( $attr => 'foo' );\n",
				"  \$object->$method\( 'bar' );\n",
				"  say \$object->$attr; ## ==> 'bar'\n",
				"\n";
		},
}

sub get {
	handler
		name      => 'String:get',
		args      => 0,
		template  => '$GET',
		documentation => "Gets the current value of the string.",
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$object = $class\->new( $attr => 'foo' );\n",
				"  say \$object->$method; ## ==> 'foo'\n",
				"\n";
		},
}

sub inc {
	handler
		name      => 'String:inc',
		args      => 0,
		template  => '« do { my $shv_tmp = $GET; ++$shv_tmp } »',
		lvalue_template => '++$GET',
		additional_validation => 'no incoming values',
		documentation => "Performs C<< ++ >> on the string.",
}

sub append {
	handler
		name      => 'String:append',
		args      => 1,
		signature => [Str],
		template  => '« $GET . $ARG »',
		lvalue_template => '$GET .= $ARG',
		usage     => '$tail',
		documentation => "Appends another string to the end of the current string and updates the attribute.",
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$object = $class\->new( $attr => 'foo' );\n",
				"  \$object->$method( 'bar' );\n",
				"  say \$object->$attr; ## ==> 'foobar'\n",
				"\n";
		},
}

sub prepend {
	handler
		args      => 1,
		name      => 'String:prepend',
		signature => [Str],
		template  => '« $ARG . $GET »',
		usage     => '$head',
		documentation => "Prepends another string to the start of the current string and updates the attribute.",
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$object = $class\->new( $attr => 'foo' );\n",
				"  \$object->$method( 'bar' );\n",
				"  say \$object->$attr; ## ==> 'barfoo'\n",
				"\n";
		},
}

sub replace {
	handler
		name      => 'String:replace',
		args      => 2,
		signature => [ Str|RegexpRef, Str|CodeRef ],
		usage     => '$regexp, $replacement',
		template  => sprintf(
			'my $shv_tmp = $GET; if (%s) { my $shv_callback = $ARG[2]; $shv_tmp =~ s/$ARG[1]/$shv_callback->()/e } else { $shv_tmp =~ s/$ARG[1]/$ARG[2]/ } «$shv_tmp»',
			CodeRef->inline_check('$ARG[2]'),
		),
		lvalue_template => sprintf(
			'if (%s) { my $shv_callback = $ARG[2]; $GET =~ s/$ARG[1]/$shv_callback->()/e } else { $GET =~ s/$ARG[1]/$ARG[2]/ } $GET',
			CodeRef->inline_check('$ARG[2]'),
		),
		documentation => "Replaces the first regexp match within the string with the replacement string.",
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$object = $class\->new( $attr => 'foo' );\n",
				"  \$object->$method( 'o' => 'a' );\n",
				"  say \$object->$attr; ## ==> 'fao'\n",
				"\n",
				"  my \$object2 = $class\->new( $attr => 'foo' );\n",
				"  \$object2->$method( qr/O/i => sub { return 'e' } );\n",
				"  say \$object2->$attr; ## ==> 'feo'\n",
				"\n";
		},
}

sub replace_globally {
	handler
		name      => 'String:replace_globally',
		args      => 2,
		signature => [ Str|RegexpRef, Str|CodeRef ],
		usage     => '$regexp, $replacement',
		template  => sprintf(
			'my $shv_tmp = $GET; if (%s) { my $shv_callback = $ARG[2]; $shv_tmp =~ s/$ARG[1]/$shv_callback->()/eg } else { $shv_tmp =~ s/$ARG[1]/$ARG[2]/g } «$shv_tmp»',
			CodeRef->inline_check('$ARG[2]'),
		),
		lvalue_template => sprintf(
			'if (%s) { my $shv_callback = $ARG[2]; $GET =~ s/$ARG[1]/$shv_callback->()/eg } else { $GET =~ s/$ARG[1]/$ARG[2]/g } $GET',
			CodeRef->inline_check('$ARG[2]'),
		),
		documentation => "Replaces the all regexp matches within the string with the replacement string.",
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$object = $class\->new( $attr => 'foo' );\n",
				"  \$object->$method( 'o' => 'a' );\n",
				"  say \$object->$attr; ## ==> 'faa'\n",
				"\n",
				"  my \$object2 = $class\->new( $attr => 'foo' );\n",
				"  \$object2->$method( qr/O/i => sub { return 'e' } );\n",
				"  say \$object2->$attr; ## ==> 'fee'\n",
				"\n";
		},
}

sub match {
	handler
		name      => 'String:match',
		args      => 1,
		signature => [ Str|RegexpRef ],
		usage     => '$regexp',
		template  => '$GET =~ /$ARG/',
		documentation => "Returns true iff the string matches the regexp.",
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$object = $class\->new( $attr => 'foo' );\n",
				"  if ( \$object->$method\( '^f..\$' ) ) {\n",
				"    say 'matched!';\n",
				"  }\n",
				"\n";
		},
}

sub match_i {
	handler
		name      => 'String:match_i',
		args      => 1,
		signature => [ Str|RegexpRef ],
		usage     => '$regexp',
		template  => '$GET =~ /$ARG/i',
		documentation => "Returns true iff the string matches the regexp case-insensitively.",
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$object = $class\->new( $attr => 'foo' );\n",
				"  if ( \$object->$method\( '^F..\$' ) ) {\n",
				"    say 'matched!';\n",
				"  }\n",
				"\n";
		},
}

sub starts_with {
	handler
		name      => 'String:starts_with',
		args      => 1,
		signature => [ Str ],
		usage     => '$head',
		template  => 'substr($GET, 0, length $ARG) eq $ARG',
		documentation => "Returns true iff the string starts with C<< \$head >>.",
}

sub starts_with_i {
	handler
		name      => 'String:starts_with_i',
		args      => 1,
		signature => [ Str ],
		usage     => '$head',
		template  => sprintf( '%s(substr($GET, 0, length $ARG)) eq %s($ARG)', $fold, $fold ),
		documentation => "Returns true iff the string starts with C<< \$head >> case-insensitvely.",
}

sub ends_with {
	handler
		name      => 'String:ends_with',
		args      => 1,
		signature => [ Str ],
		usage     => '$tail',
		template  => 'substr($GET, -length $ARG) eq $ARG',
		documentation => "Returns true iff the string ends with C<< \$tail >>.",
}

sub ends_with_i {
	handler
		name      => 'String:ends_with_i',
		args      => 1,
		signature => [ Str ],
		usage     => '$tail',
		template  => sprintf( '%s(substr($GET, -length $ARG)) eq %s($ARG)', $fold, $fold ),
		documentation => "Returns true iff the string ends with C<< \$tail >> case-insensitvely.",
}

sub contains {
	handler
		name      => 'String:contains',
		args      => 1,
		signature => [ Str ],
		usage     => '$str',
		template  => 'index($GET, $ARG) != -1',
		documentation => "Returns true iff the string contains C<< \$str >>.",
}

sub contains_i {
	handler
		name      => 'String:contains_i',
		args      => 1,
		signature => [ Str ],
		usage     => '$str',
		template  => sprintf( 'index(%s($GET), %s($ARG)) != -1', $fold, $fold ),
		documentation => "Returns true iff the string contains C<< \$str >> case-insensitvely.",
}

sub chop {
	handler
		name      => 'String:chop',
		args      => 0,
		template  => 'my $shv_return = chop(my $shv_tmp = $GET); «$shv_tmp»; $shv_return',
		lvalue_template => 'chop($GET)',
		additional_validation => 'no incoming values',
		documentation => "Like C<chop> from L<perlfunc>.",
}

sub chomp {
	handler
		name      => 'String:chomp',
		args      => 0,
		template  => 'my $shv_return = chomp(my $shv_tmp = $GET); «$shv_tmp»; $shv_return',
		lvalue_template => 'chomp($GET)',
		additional_validation => 'no incoming values',
		documentation => "Like C<chomp> from L<perlfunc>.",
}

sub trim {
	handler
		name      => 'String:trim',
		args      => 0,
		template  => 'my $shv_tmp = $GET; s/\A\s+//, s/\s+\z// for $shv_tmp; «$shv_tmp»;',
		lvalue_template => 's/\A\s+//, s/\s+\z// for $GET',
		additional_validation => 'no incoming values',
		documentation => "Like C<trim> from L<builtin>, but in-place.",
}

sub clear {
	handler
		name      => 'String:clear',
		args      => 0,
		template  => '«q()»',
		additional_validation => 'no incoming values',
		documentation => "Sets the string to the empty string.",
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$object = $class\->new( $attr => 'foo' );\n",
				"  \$object->$method;\n",
				"  say \$object->$attr; ## nothing\n",
				"\n";
		},
}

sub reset {
	handler
		name      => 'String:reset',
		args      => 0,
		template  => '« $DEFAULT »',
		default_for_reset => sub { 'q()' },
		documentation => 'Resets the attribute to its default value, or an empty string if it has no default.',
}

sub length {
	handler
		name      => 'String:length',
		args      => 0,
		template  => 'length($GET)',
		documentation => "Like C<length> from L<perlfunc>.",
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return join "",
				"  my \$object = $class\->new( $attr => 'foo' );\n",
				"  say \$object->$method; ## ==> 3\n",
				"\n";
		},
}

sub substr {
	handler
		name      => 'String:substr',
		min_args  => 1,
		max_args  => 3,
		signature => [Int, Optional[Int], Optional[Str]],
		usage     => '$start, $length?, $replacement?',
		template  => 'if (#ARG==1) { substr($GET, $ARG[1]) } elsif (#ARG==2) { substr($GET, $ARG[1], $ARG[2]) } elsif (#ARG==3) { my $shv_tmp = $GET; my $shv_return = substr($shv_tmp, $ARG[1], $ARG[2], $ARG[3]); «$shv_tmp»; $shv_return } ',
		lvalue_template  => 'if (#ARG==1) { substr($GET, $ARG[1]) } elsif (#ARG==2) { substr($GET, $ARG[1], $ARG[2]) } elsif (#ARG==3) { substr($GET, $ARG[1], $ARG[2], $ARG[3]) } ',
		documentation => "Like C<substr> from L<perlfunc>, but is not an lvalue.",
}

for my $comparison ( qw/ cmp eq ne lt gt le ge / ) {
	no strict 'refs';

	*$comparison = sub {
		handler
			name      => "String:$comparison",
			args      => 1,
			signature => [Str],
			usage     => '$str',
			template  => "\$GET $comparison \$ARG",
			documentation => "Returns C<< \$object->attr $comparison \$str >>.",
	};

	*{ $comparison . 'i' } = sub {
		handler
			name      => "String:$comparison" . 'i',
			args      => 1,
			signature => [Str],
			usage     => '$str',
			template  => "$fold(\$GET) $comparison $fold(\$ARG)",
			documentation => "Returns C<< fc(\$object->attr) $comparison fc(\$str) >>. Uses C<lc> instead of C<fc> in versions of Perl older than 5.16.",
	};
}

for my $mutation ( qw/ uc fc lc / ) {
	no strict 'refs';
	my $mutationf = $mutation;
	if ( $mutationf eq 'fc' ) {
		$mutationf = $fold;
	}
	*$mutation = sub {
		handler
			name      => "String:$mutation",
			args      => 0,
			template  => "$mutationf(\$GET)",
			documentation => "Returns C<< $mutation(\$object->attr) >>.",
	};
}

1;

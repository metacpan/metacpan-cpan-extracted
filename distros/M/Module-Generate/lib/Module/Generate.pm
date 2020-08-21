package Module::Generate;

use 5.006;
use strict;
use warnings;

use Cwd qw/abs_path/;
use Perl::Tidy;
use Data::Dumper;
use Module::Starter;
$Data::Dumper::Deparse = 1;
our $VERSION = '0.20';
our %CLASS;
our $SUB_INDEX = 1;

sub start {
	return ref $_[0] ? $_[0] : bless {}, $_[0];
}

sub dist {
	$CLASS{DIST} = $_[1];
	return ref $_[0] ? $_[0] : bless {}, $_[0];
}

sub class {
	my ($self, $class) = @_;
	$CLASS{CURRENT} = $CLASS{$class} = {
		NAME => $class
	};
	return ref $self ? $self : bless {}, $self;
}

sub lib {
	$CLASS{LIB} = $_[1];
	return ref $_[0] ? $_[0] : bless {}, $_[0];
}

sub tlib {
	$CLASS{TLIB} = $_[1];
	return ref $_[0] ? $_[0] : bless {}, $_[0];
}

sub author {
	$CLASS{AUTHOR} = $_[1];
	return ref $_[0] ? $_[0] : bless {}, $_[0];
}

sub email {
	$CLASS{EMAIL} = $_[1];
	return ref $_[0] ? $_[0] : bless {}, $_[0];
}

sub version {
	$CLASS{VERSION} = $_[1];
	return ref $_[0] ? $_[0] : bless {}, $_[0];
}

sub synopsis {
	$CLASS{CURRENT}{SYNOPSIS} = $_[1];
	return $_[0];
}

sub abstract {
	$CLASS{CURRENT}{ABSTRACT} = $_[1];
	return $_[0];
}

sub use {
	my $self = shift;
	$CLASS{CURRENT}{USE} ||= [];
	push @{ $CLASS{CURRENT}{USE} }, @_;
	return $self;
}

sub base {
	my $self = shift;
	$CLASS{CURRENT}{BASE} ||= [];
	push @{ $CLASS{CURRENT}{BASE} }, @_;
	return $self;
}

sub parent {
	my $self = shift;
	$CLASS{CURRENT}{PARENT} ||= [];
	push @{ $CLASS{CURRENT}{PARENT} }, @_;
	return $self;
}

sub require {
	my $self = shift;
	$CLASS{CURRENT}{REQUIRE} ||= [];
	push @{ $CLASS{CURRENT}{REQUIRE} }, @_;
	return $self;
}

sub our {
	my $self = shift;
	$CLASS{CURRENT}{GLOBAL} ||= [];
	push @{ $CLASS{CURRENT}{GLOBAL} }, @_;
	return $self;
}

sub begin {
	$CLASS{CURRENT}{BEGIN} = $_[1];
	return $_[0];
}

sub unitcheck {
	$CLASS{CURRENT}{UNITCHECK} = $_[1];
	return $_[0];
}

sub check {
	$CLASS{CURRENT}{CHECK} = $_[1];
	return $_[0];
}

sub init {
	$CLASS{CURRENT}{INIT} = $_[1];
	return $_[0];
}

sub end {
	$CLASS{CURRENT}{END} = $_[1];
	return $_[0];
}

sub new {
	my ($self, $sub) = @_;
	$CLASS{CURRENT}{SUBS}{CURRENT} = $CLASS{CURRENT}{SUBS}{new} = {
		INDEX => $SUB_INDEX++,
		POD => "Instantiate a new $CLASS{CURRENT}{NAME} object.",
		EXAMPLE => "$CLASS{CURRENT}{NAME}\-\>new"
	};
	$CLASS{CURRENT}{SUBS}{CURRENT}{CODE} = $sub ? $sub : eval "sub {
		my (\$cls, \%args) = (shift, scalar \@_ == 1 ? \%{\$_[0]} : \@_);
		bless \\%args, \$cls;
	}";
	$CLASS{CURRENT}{SUBS}{CURRENT}{TEST} = [
		['ok', sprintf 'my $obj = %s->new', $CLASS{CURRENT}{NAME}],
		['isa_ok', '$obj', qq|'$CLASS{CURRENT}{NAME}'|], 
	];
	return $self;
}

sub accessor {
	my ($self, $sub, $code) = @_;
	$CLASS{CURRENT}{SUBS}{CURRENT} = $CLASS{CURRENT}{SUBS}{$sub} = {
		INDEX => $SUB_INDEX++,
		ACCESSOR => 1,
		POD => "get or set ${sub}.",
		EXAMPLE => "\$obj->${sub}\;\n\n\t\$obj->${sub}(\$value)\;"
	};
	$CLASS{CURRENT}{SUBS}{CURRENT}{CODE} = $code ? $code : eval "sub {
		my (\$self, \$value) = \@_;
		if (defined \$value) {
			\$self->{$sub} = \$value;
		}
		return \$self->{$sub}
	}";
	$CLASS{CURRENT}{SUBS}{CURRENT}{TEST} = [
		['can_ok', qq|\$obj|, qq|'$sub'|],
		['is',  qq|\$obj->$sub|, 'undef'],
		['is',  qq|\$obj->$sub('test')|, qq|'test'|], 
		['deep',qq|\$obj->$sub({ a => 'b' })|, qq|{ a => 'b' }|],
		['deep',qq|\$obj->$sub|, qq|{ a => 'b' }|]
	];
	return $self;
}

sub sub {
	my ($self, $sub) = @_;
	$CLASS{CURRENT}{SUBS}{CURRENT} = $CLASS{CURRENT}{SUBS}{$sub} = {
		INDEX => $SUB_INDEX++
	};
	$CLASS{CURRENT}{SUBS}{CURRENT}{TEST} = [
		['can_ok', qq|\$obj|, qq|'$sub'|],
	];
	return $self;
}

sub macro {
	my ($self, $name, $code) = @_;
	$code = ref $code ? Dumper $code : $code;
	$code =~ s/\$VAR1 = //;
	$code =~ s/sub\s*//;
	$code =~ s/{\s*\n*|\s*\n*};$//g;
	$CLASS{MACRO}{$name} = $code;
	return $self;
}

sub keyword {
	my ($self, $name, %keyword) = (shift, shift, (! ref $_[0] ? @_ : ref $_[0] eq 'HASH' ? %{$_[0]} : (
		CODE => $_[0],
		KEYWORDS => $_[1] || [],
		($_[2] ? ( POD_TITLE => $_[2] ) : ())	
	)));
	push @{$keyword{KEYWORDS}}, $name;
	$CLASS{KEYWORD}{$name} = \%keyword;
	my $MACROS = join '|', map { quotemeta($_) } keys %{$CLASS{MACRO}};
	{
		no strict 'refs';
		my $cls = ref $self;
		*{"${cls}::$name"} = sub {
			my ($self, $value) = (shift, _stringify_struct($MACROS, @_));
			$CLASS{CURRENT}{SUBS}{CURRENT} = $CLASS{CURRENT}{SUBS}{$SUB_INDEX} = {
				INDEX => $SUB_INDEX++,
				KEYWORD => $name,
				$name => $value
			};
			for (qw/POD EXAMPLE/) {
				if ($CLASS{KEYWORD}{$name}{"POD_$_"}) {
					$CLASS{CURRENT}{SUBS}{CURRENT}{$_} = $CLASS{KEYWORD}{$name}{"POD_$_"};
					$CLASS{CURRENT}{SUBS}{CURRENT}{$_} =~ s/\$keyword/$value/g;
				}
			}
			return $self;
		};
		for my $add (@{$keyword{KEYWORDS}}) {
			next if $add eq $name;
			*{"${cls}::$add"} = sub {
				my ($self, $code) = (shift, _stringify_struct($MACROS, @_));
				$CLASS{CURRENT}{SUBS}{CURRENT}{$add} = $code;
				return $self;
			};
		}
	}
	return $self;
}

sub code {
	my ($self, $code) = @_;
	$CLASS{CURRENT}{SUBS}{CURRENT}{CODE} = $code;
	return $self;
}

sub pod {
	my ($self, $pod) = @_;
	$CLASS{CURRENT}{SUBS}{CURRENT}{POD} = $pod;
	return $self;
}

sub example {
	my ($self, $pod) = @_;
	$CLASS{CURRENT}{SUBS}{CURRENT}{EXAMPLE} = $pod;
	return $self;
}

sub test {
	my ($self, @tests) = @_;
	push @{$CLASS{CURRENT}{SUBS}{CURRENT}{TEST}}, @tests;
	return $self;
}

sub clear_tests {
	my ($self) = @_;
	$CLASS{CURRENT}{SUBS}{CURRENT}{TEST} = [];
	return $self;
}

sub generate {
	my ($self, %args) = @_;

	my @classes = sort grep { $_ !~ m/^(LIB|TLIB|AUTHOR|EMAIL|VERSION|DIST|CURRENT|MACRO|KEYWORD)$/ } keys %CLASS;

	my $lib = $CLASS{LIB} || ".";
	my $tlib = $CLASS{TLIB};
	if ($CLASS{DIST}) {
		my $distro = delete $CLASS{DIST};
		Module::Starter->create_distro(
			dir => $lib . "/$distro",
			distro => $distro,
			builder => 'ExtUtils::MakeMaker',
			modules => [@classes],
			author => 'LNATION',
			email => 'email@lnation.org',
			%{$args{DIST}}
		);
		$tlib = "$lib/$distro/t";
		$lib = "$lib/$distro/lib";
	}
	
	for my $class (@classes) {
		my $cls = _perl_tidy(
			sprintf(
				qq{package %s; use strict; use warnings;%s\n%s\n%s\n%s\n\n1;\n\n__END__%s },
					$class,
					_build_use($CLASS{$class}),
					_build_global($CLASS{$class}{GLOBAL}),
					_build_phase($CLASS{$class}),
					_build_subs($CLASS{$class}),
					_build_pod($class, $CLASS{$class})
			)
		);
		(my $path = $class) =~ s/\:\:/\//g;
		my $file = sprintf "%s/%s.pm", $lib, $path;
		_make_path($file);
		open(my $fh, '>', $file) or die "Cannot open file to write $!";
		print $fh $cls;
		close $fh;
		if ($tlib) {
			my $test_file = _perl_tidy(
				sprintf(
					qq{use Test::More; use strict; use warnings;%sdone_testing();},
						_build_tests($CLASS{$class})
				)
			);
			$class =~ s/\:\:/-/g;
			my $file = sprintf "%s/%s.t", $tlib,  $class;
			_make_path($file);
			open(my $fh, '>', $file) or die "Cannot open file to write $!";
			print $fh $test_file;
			close $fh;
		}
	}
}


sub _make_path {
	my $path = abs_path();
	for (split '/', $_[0]) {
		next if $_ =~ m/\.pm|\.t/;
		$path .= "/$_";
		$path =~ m/(.*)/;
		if (! -d $1) {
			mkdir $1 or die "Cannot open file for writing $!";
		}
	}
	return $path;
}

sub _build_use {
	my @codes;
	push @codes, map { "use $_;" } @{$_[0]->{USE}} if $_[0]->{USE};
	push @codes, sprintf("use base qw/%s/;", join " ", @{$_[0]->{BASE}}) if $_[0]->{BASE};
	push @codes, sprintf("use base qw/%s/;", join " ", @{$_[0]->{PARENT}}) if $_[0]->{PARENT};
	push @codes, map { "use $_;" } @{$_[0]->{REQUIRE}} if $_[0]->{REQUIRE};
	return join "\n", @codes;
}

sub _build_global {
	my @codes = map { "our $_;" } @{$_[0]};
	$CLASS{VERSION} ||= 0.01;
	unshift @codes, "our \$VERSION = $CLASS{VERSION};";
	return join "\n", @codes;
}

sub _build_phase {
	my $phases = shift;
	my @codes;
	for (qw/BEGIN UNITCHECK CHECK INIT END/) {
		if ($phases->{$_}) {
			my $code = ref $phases->{$_} ? Dumper $phases->{$_} : $phases->{$_};
			$code =~ s/\$VAR1 = //;
			$code =~ s/sub\s*//;
			$code =~ s/};$/}/;
			$code = sprintf "%s %s;", 'BEGIN', $code;
			push @codes, $code;
		}
	}
	return join "\n", @codes;
}

sub _stringify_struct {
	my ($MACROS, @struct) = @_;
	if ($#struct > 0) {
		return '(' . (join ", ", map {  _stringify_struct($MACROS, $_) } @struct) . ')';
	}
	$struct[0] = ref $struct[0] ? Dumper $struct[0] : $struct[0];
	$struct[0] =~ s/\$VAR1 = //;
	$struct[0] =~ s/\s*\n*\s*package Module\:\:Generate\;|use warnings\;|use strict\;//g;
	$struct[0] =~ s/{\s*\n*/{/;
	$struct[0] =~ s/};$/}/;
	$struct[0] =~ s/\&($MACROS)/$CLASS{MACRO}{$1}/g;
	return $struct[0];
}

sub _build_subs {
	my ($class) = @_;
	my @codes;
	delete $class->{SUBS}{CURRENT};

	my $MACROS = join '|', map { quotemeta($_) } keys %{$CLASS{MACRO}};
	for my $sub (sort {
		$class->{SUBS}{$a}{INDEX} <=> $class->{SUBS}{$b}{INDEX}
	} keys %{$class->{SUBS}}) {
		my $code;
		if ($class->{SUBS}{$sub}{KEYWORD}) {
			my $meta = $class->{SUBS}{$sub};
			my $keyword = $CLASS{KEYWORD}{$class->{SUBS}{$sub}{KEYWORD}}; 
			$meta->{CODE} = _stringify_struct(
				$MACROS, 
				((ref($meta->{CODE}) || "") eq "ARRAY" ? @{$meta->{CODE}} : $meta->{CODE})
			) if defined $meta->{CODE};
			$code = $keyword->{CODE}->($meta, $keyword->{KEYWORDS});
		} elsif ($class->{SUBS}{$sub}{CODE}) {
			$code = ref $class->{SUBS}{$sub}{CODE} ? Dumper $class->{SUBS}{$sub}{CODE} : $class->{SUBS}{$sub}{CODE};
			$code =~ s/\$VAR1 = //;
			$code =~ s/sub\s*//;
			$code =~ s/\s*\n*\s*package Module\:\:Generate\;|use warnings\;|use strict\;//g;
			$code =~ s/{\s*\n*/{/;
			$code =~ s/};$/}/;
			$code =~ s/\&($MACROS)/$CLASS{MACRO}{$1}/g;
			$code = sprintf "sub %s %s", $sub, $code;
		} else {
			$code = sprintf "sub %s {\n\n\n}", $sub;
		}
		push @codes, $code;
	}
	return join "\n", @codes;
}

sub _build_pod {
	my ($class, $definition) = @_;
	my $d = do { no strict 'refs'; \*{"Module::Generate::DATA"} };
	seek $d, 0, 0;
	my $content = join '', <$d>;
	$content =~ s/^.*\n__DATA__\n/\n/s;
	$content =~ s/\n__END__\n.*$/\n/s;

	my %sections = (
		subs => [],
		accessor => []
	);

	for my $sub (sort {
		$definition->{SUBS}{$a}{INDEX} <=> $definition->{SUBS}{$b}{INDEX}
	} keys %{$definition->{SUBS}}) {
		my $spod = $definition->{SUBS}{$sub}{POD} ? $definition->{SUBS}{$sub}{POD} : "";
		if ($definition->{SUBS}{$sub}{KEYWORD}) {
			my $name = $definition->{SUBS}{$sub}{$definition->{SUBS}{$sub}{KEYWORD}};  
			push @{$sections{$definition->{SUBS}{$sub}{KEYWORD}}}, $definition->{SUBS}{$sub}{EXAMPLE}
				? sprintf("=head2 %s\n\n%s\n\n\t%s",
					$name, $spod, $definition->{SUBS}{$sub}{EXAMPLE})
				: sprintf("=head2 %s\n\n%s", $name, $spod);
		} elsif ($definition->{SUBS}{$sub}{ACCESSOR}) {
			push @{$sections{accessor}}, $definition->{SUBS}{$sub}{EXAMPLE}
				? sprintf("=head2 %s\n\n%s\n\n\t%s",
					$sub, $spod, $definition->{SUBS}{$sub}{EXAMPLE})
				: sprintf("=head2 %s\n\n%s", $sub, $spod);
		} else {
			push @{$sections{subs}}, $definition->{SUBS}{$sub}{EXAMPLE}
				? sprintf("=head2 %s\n\n%s\n\n\t%s",
					$sub, $spod, $definition->{SUBS}{$sub}{EXAMPLE})
				: sprintf("=head2 %s\n\n%s", $sub, $spod);
		}
	}

	if (scalar @{$sections{accessor}}) {
		unshift @{$sections{accessor}}, "=head1 ACCESSORS";
	}

	if (scalar @{$sections{subs}}) {
		unshift @{$sections{subs}}, "=head1 SUBROUTINES/METHODS";
	}

	for (keys %{$CLASS{KEYWORD}}) {
		unshift @{$sections{$_}}, sprintf "=head1 %s", $CLASS{KEYWORD}{$_}{POD_TITLE} ||  uc($_);
	}

	my @subs = map { @{ $sections{$_} }} 'subs', 'accessor', sort keys %{$CLASS{KEYWORD}};

	my $lcname = lc($class);
	(my $safename = $class) =~ s/\:\:/-/g;
	$CLASS{EMAIL} =~ s/\@/ at / if $CLASS{EMAIL};
	my %params = (
		lcname => $lcname,
		safename => $safename,
		name => $class,
		abstract => ($definition->{ABSTRACT} ? $definition->{ABSTRACT} : sprintf('The great new %s!', $class)),
		version => $definition->{VERSION} || '0.01',
		subs => join("\n\n", @subs),
		synopsis => ($definition->{SYNOPSIS}
			? $definition->{SYNOPSIS}
			: sprintf("\n\tuse %s;\n\n\tmy \$foo = %s->new();\n\n\t...", $class, $class)
		),
		author => $CLASS{AUTHOR} || "AUTHOR",
		email => $CLASS{EMAIL} || "EMAIL"
	);

	my $reg = join "|", keys %params;

	$content =~ s/\{\{($reg)\}\}/$params{$1}/g;

	return $content;
}

sub _perl_tidy {
	my $source = shift;

	my $dest_string;
	my $stderr_string;
	my $errorfile_string;
	my $argv = "-npro -pbp -nst -se -nola -t";

	my $error = Perl::Tidy::perltidy(
		argv	=> $argv,
		source      => \$source,
		destination => \$dest_string,
		stderr      => \$stderr_string,
		errorfile   => \$errorfile_string,
	);

	if ($stderr_string) {
		# serious error in input parameters, no tidied output
		print "<<STDERR>>\n$stderr_string\n";
		die "Exiting because of serious errors\n";
	}

	return $dest_string;
}

sub _build_tests {
	my ($class, $obj_ok) = @_;
	my $tests = sprintf("BEGIN { use_ok('%s'); }", $class->{NAME});

	if ($class->{SUBS}->{new}->{TEST}) {
		$tests .= sprintf "subtest 'new' => sub { plan tests => %s; %s };",
			scalar @{$class->{SUBS}->{new}->{TEST}}, 
			join '', map{ _build_test($_) } @{ $class->{SUBS}->{new}->{TEST} };
		$obj_ok = $class->{SUBS}->{new}->{TEST}->[0];
	}

	for my $sub (sort { ($class->{SUBS}->{$b}->{ACCESSOR} || 0) <=> ($class->{SUBS}->{$a}->{ACCESSOR} || 0) }  keys %{$class->{SUBS}}) {
		next if $sub eq 'new';
		unshift @{$class->{SUBS}->{$sub}->{TEST}}, $obj_ok if $obj_ok;
		$tests .= sprintf "subtest '%s' => sub { plan tests => %s; %s };", 
			($class->{SUBS}->{$sub}->{KEYWORD} ? ( $class->{SUBS}->{$sub}->{KEYWORD} . ' ' . quotemeta($class->{SUBS}->{$sub}->{$class->{SUBS}->{$sub}->{KEYWORD}}) ) : $sub), 
			scalar @{$class->{SUBS}->{$sub}->{TEST}}, 
			join '', map{ _build_test($_) } @{ $class->{SUBS}->{$sub}->{TEST} }
		if $class->{SUBS}->{$sub}->{TEST};
	}

	return $tests;
}

our %TESTS;
BEGIN {
	%TESTS = (
		ok => sub {
			return sprintf q|ok(%s, q{%s});|, $_[1], $_[2] || $_[1];
		},
		can_ok => sub {
			return sprintf q|can_ok(%s, %s);|, $_[1], $_[2];
		},
		isa_ok => sub {
			return sprintf q|isa_ok(%s, %s);|, $_[1], $_[2];
		},
		is => sub {
			return sprintf q|is(%s, %s, q{%s});|, $_[1], $_[2], $_[3] || $_[1];
		},
		isnt => sub {
			return sprintf q|isnt(%s, %s, q{%s});|, $_[1], $_[2], $_[3] || $_[1];
		},
		like => sub {
			return sprintf q|like(%s, %s, q{%s});|, $_[1], $_[2], $_[3] || $_[1];
		},
		unlike => sub {
			return sprintf q|unlike(%s, %s, q{%s});|, $_[1], $_[2], $_[3] || $_[1];
		},	
		deep => sub {
			return sprintf q|is_deeply(%s, %s, q{%s});|, $_[1], $_[2], $_[3] || $_[1];
		},
		eval => sub {
			return sprintf q|eval {%s}; like($@, qr/%s/, q{%s});|, $_[1], $_[2], $_[3] || $_[1];
		}
	);
}

sub _build_test {
	my $test = shift;
	return ref $test ? $TESTS{$test->[0]}->(@{$test}) : $test;
}

1;

__DATA__

=head1 NAME

{{name}} - {{abstract}}

=head1 VERSION

Version {{version}}

=cut

=head1 SYNOPSIS

Quick summary of what the module does.
{{synopsis}}

{{subs}}

=head1 AUTHOR

{{author}}, C<< <{{email}}> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-{{lcname}} at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue={{safename}}>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc {{name}}

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist={{safename}}>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/{{safename}}>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/{{safename}}>

=item * Search CPAN

L<https://metacpan.org/release/{{safename}}>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by {{author}}.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__

=head1 NAME

Module::Generate - Assisting with module generation.

=head1 VERSION

Version 0.20

=cut

=head1 SYNOPSIS

	use Module::Generate;

	Module::Generate->dist('Planes')
		->author('LNATION')
		->email('email@lnation.org')
		->version('0.01')
		->class('Planes')
			->abstract('Over my head.')
			->our('$type')
			->begin(sub {
				$type = 'boeing';
			})
			->new
				->pod('Instantiate a new plane.')
				->example('my $plane = Planes->new')
			->accessor('airline')
			->sub('type')
				->code(sub { $type })
				->pod('Returns the type of plane.')
				->example('$plane->type')
			->sub('altitude')
				->code(sub {
					$_[1] / $_[2];
					...
				})
				->pod('Discover the altitude of the plane.')
				->example('$plane->altitude(100, 100)')
		->generate;

	...

	Module::Generate->dist('Holiday')
		->author('LNATION')
		->email('email@lnation.org')
		->version('0.01')
		->class('Feed::Data')
			->use('Data::LnArray')
			->our('$holiday')
			->begin(sub {
				$holiday = Data::LnArray->new;
			})
			->sub('parse')
			->sub('write')
			->sub('render')
			->sub('generate')
			->sub('_raw')
			->sub('_text')
			->sub('_json')
		->generate;

=head1 SUBROUTINES/METHODS

=head2 start

Instantiate a new Module::Generate object.

	my $mg = Module::Generate->start;	

=head2 dist

Provide a name for the distribution.

	my $dist = Module::Generate->dist('Planes');

=cut

=head2 lib

Provide a path where the generated files will be compiled.

	my $module = Module::Generate->lib('./path/to/lib');

=cut

=head2 tlib

Provide a path where the generated test will be compiled.

	my $module = Module::Generate->tlib('./path/to/t');

=cut

=head2 author

The author of the distribution/module.

	my $module = Module::Generate->author('LNATION');

=cut

=head2 email

The authors email of the distribution/module.

	my $module = Module::Generate->email('email@lnation.org');

=cut

=head2 version

The version number of the distribution/module.

	my $version = Module::Generate->version('0.01');

=cut

=head2 class

Start a new class/package/module..

	my $class = Module::Generate->class('Planes');

=cut

=head2 abstract

Provide abstract text for the class.

	$class->abstract('Over my head.');

=head2 synopsis

Provide a synopsis for the class.

	$class->synopsis('...');

=cut

=head2 use

Declare modules that should be included in the class.

	$class->use(qw/Moo MooX::LazierAttributes/);

=cut

=head2 base

Establish an ISA relationship with base classes at compile time.

Unless you are using the fields pragma, consider this discouraged in favor of the lighter-weight parent.

	$class->base(qw/Foo Bar/);

=cut

=head2 parent

Establish an ISA relationship with base classes at compile time.

	$class->parent(qw/Foo Bar/);

=cut

=head2 require

Require library files to be included if they have not already been included.

	$class->require(qw/Foo Bar/);

=cut

=head2 our

Declare variable of the same name in the current package for use within the lexical scope.

	$class->our(qw/$one $two/);

=cut

=head2 begin

Define a code block is executed as soon as possible.

	$class->begin(sub {
		...
	});

=cut

=head2 unitcheck

Define a code block that is executed just after the unit which defined them has been compiled.

	$class->unitcheck(sub {
		...
	});

=cut

=head2 check

Define a code block that is executed just after the initial Perl compile phase ends and before the run time begins.

	$class->check(sub {
		...
	});

=cut

=head2 init

Define a code block that is executed just before the Perl runtime begins execution.

	$class->init(sub {
		...
	});

=cut

=head2 end

Define a code block is executed as late as possible.

	$class->end(sub {
		...
	});

=cut

=head2 new

Define an object constructor.

	$class->new;

equivalent to:

	sub new {
		my ($cls, %args) = (shift, scalar @_ == 1 ? %{$_[0]} : @_);
		bless \%args, $cls;
	}

optionally you can pass your own sub routine.

	$class->new(sub { ... });

=head2 accessor

Define a accessor.

	$class->accessor('test');

equivalent to:

	sub test {
		my ($self, $value) = @_;
		if ($value) {
			$self->{$sub} = $value;
		}
		return $self->{$sub}
	}";

=head2 sub

Define a sub routine/method.

	my $sub = $class->sub('name');

=cut

=head2 code

Define the code that will be run for the sub.

	$sub->code(sub {
		return 'Robert';
	});

=cut

=head2 pod

Provide pod text that describes the sub.

	$sub->pod('What is my name?');

=cut

=head2 example

Provide a code example which will be suffixed to the pod definition.

	$sub->example('$foo->name');

=cut

=head2 test

Provide tests for the sub.

	$sub->test(['is', '$obj->name', q|'test'|], [ ... ], ...)

=cut

=head2 macro 

Implement a macro that can be inserted across classes.

	my $mg = Module::Generate->author('LNATION')
		->email('email@lnation.org')
		->version('0.01');
	$mg->macro('self', sub {
		my ($self, $value) = @_;
	});
	my $class = $mg->class('Foo');
	$class->sub('bar')
		->code(sub { &self; $value; });
	$class->generate;

	###

	package Foo;
	use strict;
	use warnings;
	our $VERSION = 0.01;

	sub bar {
		my ( $self, $value ) = @_;

		$value;
	}

	1;

	__END__

=head2 keyword

Implement a keyword that can be used accross classes.


	my $mg = Module::Generate
		->author('LNATION')
		->email('email@lnation.org');
	$mg->keyword('with', sub {
		my ($meta) = @_;
		return qq|with $meta->{with};|;
	});

	$mg->keyword('has',
		CODE => sub {
			my ($meta) = @_;
			$meta->{is} ||= q|'ro'|;
			my $attributes = join ', ', map {
				($meta->{$_} ? (sprintf "%s => %s", $_, $meta->{$_}) : ())
			} qw/is required/;
			my $code = qq|
				has $meta->{has} => ( $attributes );|;
			return $code;
		},
		KEYWORDS => [qw/is required/],
		POD_TITLE => 'ATTRIBUTES',
		POD_POD => 'get or set $keyword',
		POD_EXAMPLE => "\$obj->\$keyword;\n\n\t\$obj->\$keyword(\$value);"
	);

	$mg->class('Keyword')
		->use('Moo')
		->with(qw/'Keyword::Role'/)
			->test(
				['ok', q|my $obj = Keyword->new( thing => 'abc', test => 'def' )|],
				['is', q|$obj->test|, q|'def'|]
			)
		->has('thing')->required(1)
			->test(
				['ok', q|my $obj = Keyword->new( thing => 'abc' )|],
				['is', q|$obj->thing|, q|'abc'|],
				['eval', q|$obj = Keyword->new()|, 'required']
			);

	$mg->class('Keyword::Role')
		->use('Moo::Role')
		->has('test')->is(q|'rw'|)
			->test(
				['ok', q|my $obj = do { eval q{
					package FooBar;
					use Moo;
					with 'Keyword::Role';
					1;
				}; 1; } && FooBar->new| ],
				['is', q|$obj->test|, q|undef|],
				['ok', q|$obj->test('abc')|],
				['is', q|$obj->test|, q|'abc'|]
			);

=head2 generate

Compile the code.

	$sub->generate(%args);

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-module-generate at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Generate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Generate

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Generate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Generate>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Module-Generate>

=item * Search CPAN

L<https://metacpan.org/release/Module-Generate>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Module::Generate

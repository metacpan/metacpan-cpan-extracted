package MooX::Purple::G;
use strict;
use warnings;
use 5.006;
our $VERSION = '0.19';
use PPR;
use Perl::Tidy;
use Cwd qw/abs_path/;
our %POD;

our (%HAS, $GATTRS, $SATTRS, $PATTRS, $PREFIX, %MACROS, $DIST_VERSION, $AUTHOR, $AUTHOR_EMAIL);
BEGIN {
	$DIST_VERSION = '-version';
	$AUTHOR = '-author';
	$AUTHOR_EMAIL = '-author';
	$GATTRS = '(
		allow (?&PerlNWS)
			(?:(?!qw)(?&PerlQualifiedIdentifier)|
			(?&PerlList))
		|
		with (?&PerlNWS)
			(?:(?!qw)(?&PerlPrefixUnaryOperator)*(?&PerlQualifiedIdentifier)|
			(?&PerlList))
		|
		is (?&PerlNWS)
			(?:(?!qw)(?&PerlPrefixUnaryOperator)*(?&PerlQualifiedIdentifier)|
			(?&PerlList))
		|
		use (?&PerlNWS)
			(?:(?&PerlQualifiedIdentifier)\s*(?&PerlList)|(?:(?!qw)(?&PerlQualifiedIdentifier)|
			(?&PerlList)))
		| 
		(?:(?&PerlNWS)*)
	)'; 
	$SATTRS = '(
		allow (?&PerlNWS)
			(?:(?!qw)(?&PerlQualifiedIdentifier)|
			(?&PerlList))
		|
		(?:(?&PerlNWS)*)
	)';
	$PATTRS = '(
		describe (?&PerlNWS)
			(?:(?&PerlString))
		|
		(?:(?&PerlNWS)*)
	)';
	%HAS = (
		ro => '"ro"',
		ro => '"ro"',
		is_ro => 'is => "ro"',
		rw => '"rw"',
		is_rw => 'is => "rw"',
		nan => 'undef',
		lzy => 'lazy => 1',
		bld => 'builder => 1',
		lzy_bld => 'lazy_build => 1',
		trg => 'trigger => 1',
		clr => 'clearer => 1',
		req => 'required => 1',
		coe => 'coerce => 1',
		lzy_hash => 'lazy => 1, default => sub { {} }',
		lzy_array => 'lazy => 1, default => sub { [] }',
		lzy_str => 'lazy => 1, default => sub { "" }',
		dhash => 'default => sub { {} }',
		darray => 'default => sub { [] }',
		dstr => 'default => sub { "" }',	
	);
	$HAS{compile_regex} = sprintf q|[\[\s]+(%s)[\s,]+|, join '|', keys %HAS;
	$HAS{compile_value_regex} =  sprintf q|[\[\s]+(%s)[\s,]+|, join '|', map { quotemeta($_) } 
		qw/default lazy required trigger clearer coerce handles builder predicate reader writer weak_ref init_arg moosify/;
};

sub g {
	my ($source, $keyword, $callback, $lib, $pod) = @_;
	while ($$source =~ m/
		$keyword 
		$PPR::GRAMMAR
	/xms) {
		my %hack = %+;
		$hack{generate_pod} = $pod; 
		my ($make, %makes) = $callback->(%hack);
		$hack{match} = quotemeta($hack{match});
		if ($lib) {
			$make =~ s/(^\{\s*)|(\}\s*$)//g;
			$make =~ s/^\t//gm;
			$make .= render_pod($makes{class});
			write_file(sprintf("%s/%s.pmc", $lib, $makes{class}), $make)
				if $makes{class};
			$$source =~ s/$hack{match}//;
		} else {
			$$source =~ s/$hack{match}/$make/e;
		}
	}
	$source;
}

sub p {
	g(
		g(
			g(
				g(
					g(
						g(
							g(
								g(
									$_[0],
									qq|(?<match>start\\s*
									(?<method>(?&PerlIdentifier))\\s*
									(?<block>(?&PerlBlock)))|,
									\&start
								),
								qq|(?<match>end\\s*
								(?<method>(?&PerlIdentifier))\\s*
								(?<block>(?&PerlBlock)))|,
								\&end
							),
							qq|(?<match>during\\s*
							(?<method>(?&PerlIdentifier))\\s*
							(?<block>(?&PerlBlock)))|,
							\&during
						),
						qq|(?<match>trigger\\s*
						(?<method>(?&PerlIdentifier))\\s*
						(?<block>(?&PerlBlock)))|,
						\&trigger
					),
					qq|(?<match>macro\\s*
					(?<macro> (?&PerlIdentifier))\\s*
					(?<block> (?&PerlBlock));\n*)|,
					\&macro
				),
				qq|(?<match> private\\s*
				(?<method> (?&PerlIdentifier))
				(?<attrs> (?: $SATTRS*))
				(?<block> (?&PerlBlock)))|,
				\&private,
			),
			qq|(?<match> public\\s*
			(?<method> (?&PerlIdentifier))
			(?:(?&PerlNWS))*
			(?<block> (?&PerlBlock))
			(?<pod> (?: $PATTRS*)))|,
			\&public,
			undef,
			$_[1]
		),
		qq|(?<match> attributes\\s* (?<list> (?&PerlList))\\s*\;)|,
		\&attributes
	);
}

sub i {
	my $i = shift;
	my @s;
	while ( $i =~ s/
		(?<match>\s*(?:
			(?<hash>\s*(?&PerlAnonymousHash))|
			(?<array>\s*(?&PerlAnonymousArray))|
			(?<sub>\s*(?&PerlAnonymousSubroutine))|
			(?<bless>\s*(bless\s*(?&PerlExpression)))|
			(?<ident>\s*(?&PerlIdentifier))|
			(?<string>\s*(?&PerlString))|
			(?<num>\s*(?&PerlNumber))
		)+)\s*(?&PerlComma)*
		$PPR::GRAMMAR
	//xms ) {
		push @s, {%+}
	}
	return @s;
}

sub r {
	my $i = shift;
	while ($i =~ m/$_[0]/xms) {
		my $m = $1;
		$i =~ s/$m/$_[1]->{$m}/;
	}
	$i;
}

sub kv {
	my ($i, %a) = @_;
	while (
		$i =~ s/
			\s*(?<key> (?&PerlTerm))\s*
				(?&PerlComma)
			\s*(?<value> (?&PerlTerm))\s*
			$PPR::GRAMMAR
		//xms
	) {
		my %h = %+;
		$h{key} =~ s/(^\s*)|(\s*$)//g;
		$a{$h{key}} = $h{value};
	}
	return %a;
}

sub import {
	my ($class, %args) = @_;
	$PREFIX = $args{-prefix} unless $PREFIX;
	if ($args{-author}) {
		$args{-author} =~ m/(.*)\s*\<(.*)\>/;
		$AUTHOR_EMAIL = $2;
		($AUTHOR = $1) =~ s/\s$//;
		$AUTHOR_EMAIL =~ s/\@/ at /;
	}
	$DIST_VERSION = $args{-version} if $args{-version};
	my $lib = $args{-lib};
	my $file = $args{-module} ? [caller(1)]->[1] : $0;
	open FH, "<$file";
	my $source = \join '', <FH>;
	close FH;
	g(
		g(
			g(
				$source,
				qq/(?<match>(?&PerlPod))/,
				\&parse_pod
			),
			qq/(?<match> role\\s*
			(?<class>(?&PerlPrefixUnaryOperator)*(?&PerlQualifiedIdentifier)) 
			(?<attrs> (?: $GATTRS*))
			(?<block> (?&PerlBlock)))/,
			\&roles, 
			$lib
		),
		qq/(?<match> class\\s*
		(?<class>(?&PerlPrefixUnaryOperator)*(?&PerlQualifiedIdentifier))
		(?<attrs> (?: $GATTRS*))
		(?<block> (?&PerlBlock)))/,
		\&classes,
		$lib
	);
	unless ($lib) {
		$source =~ s/use MooX\:\:Purple;\n*//;
		$source =~ s/use MooX\:\:Purple\:\:G;\n*//;
		my $current = [caller()]->[1];
		$current =~ s/\.(.*)/\.pmc/;
		write_file($current, $$source);
	}
}

sub make_path {
	my $path = abs_path();;
	for (split '/', $_[0]) {
		$path .= "/$_";
		if (! -d $path) {
			mkdir $path  or Carp::croak(qq/
				Cannot open file for writing $!
			/);
		}
	}
}

sub write_file {
	my $f = $_[0];
	$f =~ s/\:\:/\//g;
	make_path(substr($f, 0, rindex($f, '/')));
	open FH, '>', $f or die "$f cannot open file to write $!";
	print FH perl_tidy($_[1]);
	close FH;
}

sub macro {
	my %args = @_;
	$args{block} =~ s/^\n*\{\n*\s*|;\n*\t*\}\n*$//g;
	$MACROS{$args{macro}} = $args{block};
	return '';
}

sub start {
 	push @_, pre => '-';
	when(@_);  
}

sub end {
	push @_, pre => '+';
	when(@_);
}

sub during {
	push @_, pre => '~';
	when(@_);
}

sub trigger {
	push @_, pre => '=';
	when(@_);
}

sub when {
	my %args = @_;
	my %map = (
		'-' => 'before',
		'+' => 'after',
		'~' => 'around',
		'=' => 'around'
	);

	$args{block} =~ s/(^{)|(}$)//g;
	if ($args{pre} eq '~') {
		$args{block} = "{
			my (\$orig, \$self) = (shift, shift);
			$args{block};
		}";
	} elsif ($args{pre} eq '=') {
		$args{block} = "{
			my (\$orig, \$self) = (shift, shift);
			my \$out = \$self->\$orig(\@_);
			$args{block};
		}";
	} else {
		$args{block} = "{
			my (\$self) = (shift);
			$args{block};
		}";
	}
	return "$map{$args{pre}} $args{method} => sub $args{block};";
}

sub attributes {
	my %args = @_;
	my @attr;
	g(
		\$args{list}, 
		qq/(?<match> 
			\\s*(?<key> (?&PerlTerm))\\s*
				(?&PerlComma)
			\\s*(?<value> (?&PerlTerm))\\s*
		)/,
		sub {
			my %hack = _construct_attribute(@_);
			$hack{key} =~ m/\s*(?<array> (?&PerlAnonymousArray)) $PPR::GRAMMAR/xms;
			for my $key ( ($+{array} ? @{ eval $+{array} } : $hack{key}) ) {
				$key =~ s/(^\s*)|(\s*$)//g;
				push @attr, sprintf( 
q/has %s => (
	%s
);/, 
				$key, join( ",\n\t", (map { 
					$hack{$_} =~ s/(["']+)/"/g;
					qq/\t$_ => $hack{$_}/ 
				} grep { defined $hack{$_} } qw/is isa trigger builder lazy clearer/), (map {
					my $hak = [i($hack{$_})]->[0];
					$hack{$_} = defined $hak->{sub} ? $hak->{sub} : qq/sub { $hack{$_} }/;
					qq/\t$_ => $hack{$_}/; 
				} grep { $hack{$_} } qw/default/)));
			} 
		}
	);
	return join "\n\n", @attr;	
}

sub _construct_attribute {
	my (%attr) = @_;
	$attr{value} = r($attr{value}, $HAS{compile_regex}, \%HAS);
	$attr{value} =~ s/(^\s*\[)|(\s*\]$)//g;
	my @spec = i($attr{value});
	my $oc = scalar @spec;
	unshift @spec, { string => '"ro"' } if (!$spec[0]->{string});
	$attr{is} = $spec[0]->{string} =~ m/[\'\"\s]+(ro|rw)[\'\"\s]+/ 
		? shift(@spec)->{string}
		: '"ro"';
	($spec[0]->{ident} eq 'undef') 
		? shift(@spec)
		: do {
		$attr{isa} = shift(@spec)->{ident};
	} if $spec[0]->{ident};
	my $attrHash = $spec[0]->{hash} ? $spec[0]->{match} =~ m/$HAS{compile_value_regex}/g : 0;
	if ($spec[0] && keys %{$spec[0]}) {
		$attr{default} = !$attrHash && $oc <= 3 ? $spec[0]->{sub} ? shift(@spec)->{sub} : qq/sub { / . shift(@spec)->{match} . qq/ }/ : '';
		%attr = kv($spec[0]->{match}, %attr) if ($spec[0]);
	}
	delete $attr{value};
	return %attr;
}

sub roles {
	my %args = @_;
	my @hack = grep {$_ && $_ !~ m/^\s*$/} $args{attrs} =~ m/(?:$GATTRS) $PPR::GRAMMAR/gx;
	my ($body, %attrs) = _set_class_role_attrs($args{block}, _parse_role_attrs(@hack));
	$body =~ s/\s*$//;
	
	$args{class} =~ s/^\+/$PREFIX\:\:/;

	my $pod = prepare_pod($args{class});

	my $r = \qq|{
	package $args{class};
	use Moo::Role;
	use MooX::LazierAttributes;
	use MooX::ValidateSubs;
	use Data::LnArray qw/arr/;
	$attrs{with}$attrs{use}$body
	1;
}|;
	p($r, !$pod);
	return ($$r, %args);
}

sub parse_pod {
	my %h = @_;
	if ($h{match} =~ m/=head1 NAME\n*([^\s]+)/) {
		$POD{$1} = $POD{CURRENT} = { PARSED => 1, DATA => [] };	
	}
	push @{$POD{CURRENT}{DATA}}, $h{match};
}

sub prepare_pod {
	my $class = shift;
	if (!$POD{$class}) {
		$POD{$class} = $POD{CURRENT} = { PARSED => 0, DATA => [] };
		push @{$POD{$class}{DATA}}, "	=head1 NAME

	$class - The great new $class!

	=cut";
		push @{$POD{$class}{DATA}}, "	=head1 Version

	Version $DIST_VERSION

	=cut";
		push @{$POD{$class}{DATA}}, "	=head1 SYNOPSIS

		use $class;

		$class\-\>new(\\%args)

	=cut";
		push @{$POD{$class}{DATA}}, "	=head1 SUBROUTINES/METHODS

	=cut";
		return 0;
	}
	return 1;
}

sub render_pod {
	my $class = shift;
	if ($POD{$class}) {
		if (!$POD{$class}{PARSED}) {
			(my $url_class = $class) =~ s/\:\:/-/g;
			push @{$POD{$class}{DATA}}, "	=head1 AUTHOR

	$AUTHOR, C<< <$AUTHOR_EMAIL> >>

	=cut";
			push @{$POD{$class}{DATA}}, "	=head1 BUGS

	Please report any bugs or feature requests to C<bug-moox-purple at rt.cpan.org>, or through
	the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=$url_class>.  I will be notified, and then you'll
	automatically be notified of progress on your bug as I make changes.

	=cut";
			push @{$POD{$class}{DATA}}, "	=head1 SUPPORT

	You can find documentation for this module with the perldoc command.

	    perldoc $class


	You can also look for information at:

	=over 2

	=item * RT: CPAN's request tracker (report bugs here)

	L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=$url_class>

	=item * Search CPAN

	L<http://search.cpan.org/dist/$url_class/>

	=back

	=cut";
			push @{$POD{$class}{DATA}}, "	=head1 ACKNOWLEDGEMENTS

	=cut";

			push @{$POD{$class}{DATA}}, "	=head1 LICENSE AND COPYRIGHT

	Copyright 2025 $AUTHOR.

	This program is free software; you can redistribute it and/or modify it
	under the terms of the the Artistic License (2.0). You may obtain a
	copy of the full license at:

	L<http://www.perlfoundation.org/artistic_license_2_0>

	Any use, modification, and distribution of the Standard or Modified
	Versions is governed by this Artistic License. By using, modifying or
	distributing the Package, you accept this license. Do not use, modify,
	or distribute the Package, if you do not accept this license.

	If your Modified Version has been derived from a Modified Version made
	by someone other than you, you are nevertheless required to ensure that
	your Modified Version complies with the requirements of this license.

	This license does not grant you the right to use any trademark, service
	mark, tradename, or logo of the Copyright Holder.

	This license includes the non-exclusive, worldwide, free-of-charge
	patent license to make, have made, use, offer to sell, sell, import and
	otherwise transfer the Package with respect to any patent claims
	licensable by the Copyright Holder that are necessarily infringed by the
	Package. If you institute patent litigation (including a cross-claim or
	counterclaim) against any party alleging that the Package constitutes
	direct or contributory patent infringement, then this Artistic License
	to you shall terminate on the date that such litigation is filed.

	Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
	AND CONTRIBUTORS 'AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
	THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
	PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
	YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
	CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
	CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
	EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	=cut";

		}
		return join "\n", map { my $v = $_; $v =~ s/^\t//gm; $v; } @{$POD{$class}{DATA}};
	}
	return '';
}

sub classes {
	my %args = @_;
	my @hack = grep {$_ && $_ !~ m/^\s*$/} $args{attrs} =~ m/(?:$GATTRS) $PPR::GRAMMAR/gx;
	my ($body, %attrs) = _set_class_role_attrs($args{block}, _parse_role_attrs(@hack));
	$body =~ s/\s*$//;
	$args{class} =~ s/^\+/$PREFIX\:\:/;

	my $pod = prepare_pod($args{class});
	my $r = \qq|{
	package $args{class};
	use Moo;
	use MooX::LazierAttributes;
	use MooX::ValidateSubs;
	use Data::LnArray qw/arr/;
	$attrs{is}$attrs{with}$attrs{use}$body
	1;
}|;
	p($r, !$pod);
	return ($$r, %args);
}

sub macro_replacement {
	my $block = shift;
	my $mac = join '|', keys %MACROS;
	$block =~ s/&($mac)/$MACROS{$1}/g;
	return $block;
}

sub private {
	my %args = @_;
	my @hack = grep {$_ && $_ !~ m/^\s*$/} $args{attrs} =~ m/(?:$SATTRS) $PPR::GRAMMAR/gx;
	my %attrs = _parse_role_attrs(@hack);
	my $allowed = $attrs{allow} ? sprintf 'qw(%s)', join ' ', @{$attrs{allow}} : 'qw//';
	$args{block} = macro_replacement($args{block});
	$args{block} =~ s/(^{)|(}$)//g;
	$args{block} =~ s/^\s*//;
	return "sub $args{method} {
		my (\$self) = shift;
		my \$caller = caller();
		my \@allowed = $allowed;
		unless (\$caller eq __PACKAGE__ || grep { \$_ eq \$caller } \@allowed) {
			die \"cannot call private method $args{method} from \$caller\";
		}
		$args{block}
	}";
}

sub public {
	my %args = @_;
	if ($args{pod}) {
		$args{pod} =~ m/describe\s*(.*)/i;
		$args{pod} = eval $1;
	} 
	$args{pod} //= '';
	push @{ $POD{CURRENT}{DATA} }, "	=head2 $args{method}

	$args{pod}

		\$class->$args{method}

	=cut" if $args{generate_pod};
	$args{block} = macro_replacement($args{block});
	$args{block} =~ s/(^{)|(}$)//g;
	return "sub $args{method} { 
		my (\$self) = shift;
		$args{block}
	}";
}

sub _parse_role_attrs {
	my @roles = @_;
	my %attrs;
	my $i = 0;
	for (@roles) {
		if ($_ =~ m/\s*use\s*((?!qw)(?&PerlQualifiedIdentifier))\s*((?&PerlList)) $PPR::GRAMMAR/xms) {
			$attrs{use}{sprintf "%s %s", $1, $2}++;
			next;
		}
		$_ =~ m/(with|allow|is|use)(.*)/i;
		my @list = eval($2); # || $2
		push @list, do { (my $g = $2) =~ s/^\s*//; $g; } unless @list;
		for (@list) {
			$attrs{$1}{$_} = $i++;
		}
	}
	for my $o (qw/with allow is use/) {
		$attrs{$o} = [sort { $attrs{$o}{$a} <=> $attrs{$o}{$b} } keys %{$attrs{$o}}] if $attrs{$o};
	}
	return %attrs;
}

sub _set_class_role_attrs {
	my ($body, %attrs) = @_;
	if ($attrs{allow}) {
		my $allow = join ' ', @{$attrs{allow}};
		$body =~ s{private\s*(\p{XIDS}\p{XIDC}*)}{private $1 allow qw/$allow/}g;
	}
	$attrs{is} = $attrs{is} ? sprintf "extends qw/%s/;\n",  join(' ', map { my $l = $_; $l =~ s/^\s*\+/$PREFIX\:\:/; $l; } @{$attrs{is}}) : '';
	my $last;
	$attrs{with} = $attrs{with} 
		? sprintf "with qw/%s/;\n", join(' ', map { 
			my $l = $_; 
			$l =~ s/^\s*\+/$PREFIX\:\:/; 
			unless($l =~ s/^\s*\-/$last\:\:/) {
				$last = $l;
			}
			if ($l =~ s/^\s*\~//) {
				$last = $PREFIX ? ($PREFIX . '::' . $l) : $l;
				$l = '';
			}
			$l; 
		} @{$attrs{with}}) 
		: '';
	$attrs{use} = $attrs{use} ? join('', map { sprintf("\tuse %s;\n", $_) } @{$attrs{use}}) : '';
	$body =~ s/(^{)|(}$)//g;
	return $body, %attrs;
}

sub perl_tidy {
	my $source = shift;
 
	my $dest_string;
	my $stderr_string;
	my $errorfile_string;
	my $argv = "-npro";   # Ignore any .perltidyrc at this site
	$argv .= " -pbp";     # Format according to perl best practices
	$argv .= " -nst";     # Must turn off -st in case -pbp is specified
	$argv .= " -se";      # -se appends the errorfile to stderr
	$argv .= " -nola";    # Disable label indent
	$argv .= " -t";       # Use tab instead of 4 spaces
 
	my $error = Perl::Tidy::perltidy(
		argv        => $argv,
		source      => \$source,
		destination => \$dest_string,
		stderr      => \$stderr_string,
		errorfile   => \$errorfile_string,    # ignored when -se flag is set
		##phasers   => 'stun',                # uncomment to trigger an error
	);
 
	if ($error) {
		# serious error in input parameters, no tidied output
		print "<<STDERR>>\n$stderr_string\n";
		die "Exiting because of serious errors\n";
	}

	return $dest_string;
}

1;

__END__

=head1 NAME

MooX::Purple - MooX::Purple::G

=head1 VERSION

Version 0.19

=cut

=head1 SYNOPSIS

	use MooX::Purple;
	use MooX::Purple::G;

	role Before {
		public seven { return '7' }
	};

	role World allow Hello with Before {
		private six { 'six' }
	};

	class Hello with qw/World/ allow qw/main/ use Scalar::Util qw/reftype/ use qw/JSON/ {
		use Types::Standard qw/Str HashRef ArrayRef Object/;

		attributes
			one => [{ okay => 'one'}],
			[qw/two three/] => [rw, Str, { default => 'the world is flat' }];

		validate_subs
			four => {
				params => {
					message => [Str, sub {'four'}]
				}
			};

		public four { return $_[1]->{message} }
		private five { return $_[0]->six }
		public ten { reftype bless {}, 'Flat::World' }
		public eleven { encode_json { flat => "world" } }
	};

	class Night is qw/Hello/ {
		public nine { return 'nine' }
	};

	Night->new()->five();

	... writes to same/path/yourfile.pmc

	{
		package Before;
		use Moo::Role;

		sub seven { return '7' }
	};

	{
		package World;
		use Moo::Role;
		with qw/Before/;

		sub six {
			my $caller = caller();
			my @allowed = qw(Hello);
			unless ($caller eq __PACKAGE__ || grep { $_ eq $caller } @allowed) {
				die "cannot call private method six from $caller";
			}
			'six'
		}
	};	

	{
		package Hello;
		use Moo;
		use MooX::LazierAttributes;
		use MooX::ValidateSubs;
		with qw/World/;
		use Scalar::Util qw/reftype/ ;
		use JSON;

		use Types::Standard qw/Str HashRef ArrayRef Object/;

		attributes
			one => [{ okay => 'one'}],
			[qw/two three/] => [rw, Str, { default => 'the world is flat' }];

		validate_subs
			four => {
				params => {
					message => [Str, sub {'four'}]
				}
			};

		sub four { return $_[1]->{message} }
		sub five {
			my $caller = caller();
			my @allowed = qw(main);
			unless ($caller eq __PACKAGE__ || grep { $_ eq $caller } @allowed) {
				die "cannot call private method five from $caller";
			}
			return $_[0]->six
		}
		sub ten { reftype bless {}, 'Flat::World' }
		sub eleven { encode_json { flat => "world" } }
		1;
	};

	{
		package Night;
		use Moo;
		use MooX::LazierAttributes;
		use MooX::ValidateSubs;
		extends qw/Hello/;

		sub nine { return 'nine' }
		1;
	};


=head1 AUTHOR

lnation, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moox-purple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Purple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::Purple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Purple>

=item * Search CPAN

L<http://search.cpan.org/dist/MooX-Purple/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019->2025 lnation.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



1; # End of MooX::Purple

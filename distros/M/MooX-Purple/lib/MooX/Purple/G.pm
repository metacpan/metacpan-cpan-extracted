package MooX::Purple::G;
use strict;
use warnings;
use 5.006;
our $VERSION = '0.10';
use PPR;
use Cwd qw/abs_path/;

our (%HAS, $GATTRS, $SATTRS);
BEGIN {
	$GATTRS = '(
		allow (?&PerlNWS)
			(?:(?!qw)(?&PerlQualifiedIdentifier)|
			(?&PerlList))
		|
		with (?&PerlNWS)
			(?:(?!qw)(?&PerlQualifiedIdentifier)|
			(?&PerlList))
		|
		is (?&PerlNWS)
			(?:(?!qw)(?&PerlQualifiedIdentifier)|
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
	my ($source, $keyword, $callback, $lib) = @_;
	while ($$source =~ m/
		$keyword 
		$PPR::GRAMMAR
	/xms) {
		my %hack = %+;
		my ($make, %makes) = $callback->(%hack);
		$hack{match} = quotemeta($hack{match});
		if ($lib) {
			$make =~ s/(^\{\s*)|(\}\s*$)//g;
			$make =~ s/^\t//gm;
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
				$_[0],
				qq|(?<match> private\\s*
				(?<method> (?&PerlIdentifier))
				(?<attrs> (?: $SATTRS*))
				(?<block> (?&PerlBlock)))|,
				\&private,
			),
			qq|(?<match> public\\s*
			(?<method> (?&PerlIdentifier))
			(?:(?&PerlNWS))*
			(?<block> (?&PerlBlock)))|,
			\&public,
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
	my $lib = $_[1];
	open FH, "<$0";
	my $source = \join '', <FH>;
	close FH;
	g(
		g(
			$source,
			qq/(?<match> role\\s*
			(?<class> (?&PerlIdentifier)) 
			(?<attrs> (?: $GATTRS*))
			(?<block> (?&PerlBlock)))/,
			\&roles, 
			$lib
		),
		qq/(?<match> class\\s*
		(?<class> (?&PerlIdentifier))
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
	print FH $_[1];
	close FH;
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
	my $r = \qq|{
	package $args{class};
	use Moo::Role;
	use MooX::LazierAttributes;
	$attrs{with}$attrs{use}$body
	1;
}|;
	p($r);
	return ($$r, %args);
}

sub classes {
	my %args = @_;
	my @hack = grep {$_ && $_ !~ m/^\s*$/} $args{attrs} =~ m/(?:$GATTRS) $PPR::GRAMMAR/gx;
	my ($body, %attrs) = _set_class_role_attrs($args{block}, _parse_role_attrs(@hack));
	$body =~ s/\s*$//;
	my $r = \qq|{
	package $args{class};
	use Moo;
	use MooX::LazierAttributes;
	use MooX::ValidateSubs;
	$attrs{is}$attrs{with}$attrs{use}$body
	1;
}|;
	p($r);
	return ($$r, %args);
}

sub private {
	my %args = @_;
	my @hack = grep {$_ && $_ !~ m/^\s*$/} $args{attrs} =~ m/(?:$SATTRS) $PPR::GRAMMAR/gx;
	my %attrs = _parse_role_attrs(@hack);
	my $allowed = $attrs{allow} ? sprintf 'qw(%s)', join ' ', @{$attrs{allow}} : 'qw//';
	$args{block} =~ s/(^{)|(}$)//g;
	$args{block} =~ s/^\s*//;
	return "sub $args{method} {
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
	return qq|sub $args{method} $args{block}|;
}

sub _parse_role_attrs {
	my @roles = @_;
	my %attrs;
	for (@roles) {
		if ($_ =~ m/\s*use\s*((?!qw)(?&PerlQualifiedIdentifier))\s*((?&PerlList)) $PPR::GRAMMAR/xms) {
			push @{$attrs{use}}, sprintf "%s %s", $1, $2;
			next;
		}
		$_ =~ m/(with|allow|is|use)(.*)/i;
		push @{$attrs{$1}}, eval $2 || do { (my $g = $2) =~ s/^\s*//; $g; };
	}
	return %attrs;
}

sub _set_class_role_attrs {
	my ($body, %attrs) = @_;
	if ($attrs{allow}) {
		my $allow = join ' ', @{$attrs{allow}};
		$body =~ s{private\s*(\p{XIDS}\p{XIDC}*)}{private $1 allow qw/$allow/}g;
	}
	$attrs{is} = $attrs{is} ? sprintf "extends qw/%s/;\n", join ' ', @{$attrs{is}} : '';
	$attrs{with} = $attrs{with} ? sprintf "with qw/%s/;\n", join ' ', @{$attrs{with}} : '';
	$attrs{use} = $attrs{use} ? join('', map { sprintf("\tuse %s;\n", $_) } @{$attrs{use}}) : '';
	$body =~ s/(^{)|(}$)//g;
	return $body, %attrs;
}

1;

__END__

=head1 NAME

MooX::Purple - MooX::Purple::G

=head1 VERSION

Version 0.10

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

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooX-Purple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooX-Purple>

=item * Search CPAN

L<http://search.cpan.org/dist/MooX-Purple/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019 lnation.

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


=cut

1; # End of MooX::Purple

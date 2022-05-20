package MooX::Purple;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.17';
use Keyword::Declare;
our ($PREFIX, %MACROS);

sub import {
	my ($class, %args) = @_;
	$PREFIX = $args{-prefix} unless $PREFIX;
	keytype GATTRS is m{
		(?:
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
		)?+
	}xms;
	keytype SATTRS is m{
		(?:
			allow (?&PerlNWS)
				(?:(?!qw)(?&PerlQualifiedIdentifier)|
				(?&PerlList))
			|
		)?+
	}xms;
	keytype PATTRS is m{
		(?:
			describe (?&PerlNWS)
				(?:(?&PerlString))
		)?+
	}xms;
	keyword role (QualIdent $class, GATTRS @roles, Block $block) {
		_handle_role($class, $block, @roles)
	}
	keyword role (PrefixUnaryOperator $pre, QualIdent $class, GATTRS @roles, Block $block) {
		$class = $PREFIX . '::' . $class if $pre;
		_handle_role($class, $block, @roles)
	}
	keyword class (QualIdent $class, GATTRS @roles, Block $block) {
		_handle_class($class, $block, @roles);
	}
	keyword class (PrefixUnaryOperator $pre, QualIdent $class, GATTRS @roles, Block $block) {
		$class = $PREFIX . '::' . $class if $pre;	
		_handle_class($class, $block, @roles);
	}
	keyword class (PrefixUnaryOperator $pre, QualIdent $class, Block $block) {
		$class = $PREFIX . '::' . $class if $pre;	
		_handle_class($class, $block);
	}
	keyword macro (Ident $macro, Block $block) {
		return _handle_macro($macro, $block);
	}
	keyword private (Ident $method, SATTRS @roles, Block $block) {
		return _handle_private($method, $block, @roles);	
	}
	keyword public (Ident $method, Block $block, PATTRS @pod) {
		return _handle_public($method, $block, @pod);
	}
	keyword start (Ident $method, Block $block) {
		return _handle_when('-', $method, $block);	
	}
	keyword during (Ident $method, Block $block) {
		return _handle_when('~', $method, $block);	
	}
	keyword trigger (Ident $method, Block $block) {
		return _handle_when('=', $method, $block);
	}
	keyword end (Ident $method, Block $block) {
		return _handle_when('+', $method, $block);	
	}
}

sub _handle_macro {
	my ($macro, $block) = @_;
	$block =~ s/^\n*\{\n*\s*|;\n*\t*\}\n*$//g;
	$MACROS{$macro} = $block;
	return '';
}

sub _handle_public {
	my ($method, $block) = @_;
	my $mac = join '|', keys %MACROS;
	$block =~ s/&($mac)/$MACROS{$1}/g;
	$block =~ s/(^{)|(}$)//g;
	return "sub $method { 
		my (\$self) = shift;
		$block
	}";
}

sub _handle_private {
	my ($method, $block, @roles) = @_;
	my %attrs = _parse_role_attrs(@roles);
	my $allowed = $attrs{allow} ? sprintf 'qw(%s)', join ' ', @{$attrs{allow}} : 'qw//';
	my $mac = join '|', keys %MACROS;
	$block =~ s/&($mac)/$MACROS{$1}/g;
	$block =~ s/(^{)|(}$)//g;
	return "sub $method {
		my (\$self) = shift;
		my \$caller = caller();
		my \@allowed = $allowed;
		unless (\$caller eq __PACKAGE__ || grep { \$_ eq \$caller } \@allowed) {
			die \"cannot call private method $method from \$caller\";
		}
		$block
	}";
}

sub _handle_when {
	my ($pre, $method, $block) = @_;
	my %map = (
		'-' => 'before',
		'+' => 'after',
		'~' => 'around',
		'=' => 'around'
	);
	$block =~ s/(^{)|(}$)//g;
	if ($pre eq '~') {
		$block = "{
			my (\$orig, \$self) = (shift, shift);
			$block;
		}";
	} elsif ($pre eq '=') {
		$block = "{
			my (\$orig, \$self) = (shift, shift);
			my \$out = \$self->\$orig(\@_);
			$block;
		}";
	} else {
		$block = "{
			my (\$self) = (shift);
			$block;
		}"
	}
	return "$map{$pre} $method => sub $block;";
}

sub _handle_class {
	my ($class, $block, @roles) = @_;
	my ($body, %attrs) = _set_class_role_attrs($block, _parse_role_attrs(@roles));
	my $out = qq|{
		package $class;
		use Moo;
		use MooX::LazierAttributes;
		use MooX::ValidateSubs;
		use Data::LnArray qw/arr/;
		$attrs{is}
		$attrs{with}
		$attrs{use}
		$body
		1;
	}|;
	return $out;
}

sub _handle_role {
	my ($class, $block, @roles) = @_; 
	my ($body, %attrs) = _set_class_role_attrs($block, _parse_role_attrs(@roles));
	return qq|{
		package $class;
		use Moo::Role;
		use MooX::LazierAttributes;
		use MooX::ValidateSubs;
		use Data::LnArray qw/arr/;
		$attrs{with}
		$attrs{use}
		$body
		1;
	}|;
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
		push @list, $2 unless @list;
		for (@list) {
			$attrs{$1}{$_} = $i++;
		}
	}
	for my $o (qw/with allow is use/) {
		$attrs{$o} = [sort { $attrs{$o}{$a} <=> $attrs{$o}{$b} } keys %{$attrs{$o}}] if $attrs{$o};
	}
	return %attrs;
}

=pod todo uncomment and remove above hack
sub _parse_role_attrs {
	my @roles = @_;
	my %attrs;
	for (@roles) {
		if ($_ =~ m/\s*use\s*((?!qw)(?&PerlQualifiedIdentifier))\s*((?&PerlList)) $PPR::GRAMMAR/xms) {
			push @{$attrs{use}}, sprintf "%s %s", $1, $2;
			next;
		}
		$_ =~ m/(with|allow|is|use)(.*)/i;
		push @{$attrs{$1}}, eval($2) || $2;
	}
	return %attrs;
}
=cut

sub _set_class_role_attrs {
	my ($body, %attrs, %args) = @_;
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
	$attrs{use} = $attrs{use} ? join('', map { sprintf("use %s;\n", $_) } @{$attrs{use}}) : '';
	$body =~ s/(^{)|(}$)//g;
	return $body, %attrs;
}

1;

__END__

=head1 NAME

MooX::Purple - MooX::Purple

=head1 VERSION

Version 0.17

=cut

=head1 SYNOPSIS

	use MooX::Purple;

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

	...

	# ../Foo.pm
	package Foo;
	use MooX::Purple -prefix => 'Foo';
	use Foo::Roles;
	class +Class with qw/~Role -One -Two -Three -Four/ {
		public print {
			return $_[1];
		}
	}
		
	# ../Foo/Roles.pm
	package Foo::Roles;
	use MooX::Purple;
	role +Role::One {
		public one {
			$_[0]->print(1);
		}
	}
	role +Role::Two {
		public two {
			$_[0]->print(2);
		}
	}
	role +Role::Three {
		public three {
			$_[0]->print(3);
		}
	}
	role +Role::Four {
		public four {
			$_[0]->print(4);
		}
	}

	...

	use MooX::Purple -prefix => 'Macro';

	class +Simple {
		macro generic {
			'crazy';
		};
		macro second {
			my $x = 0;
			$x++ for (0..100);
			return $x;
		};
		public one { &generic; }
		
		start one {
			print "before\n";
		}
		
		during one {
			print "around\n";
			$self->$orig();
		};

		trigger one {
			print "trigger\n";
			return 'insane';
		}

		end one {
			print "after\n";
		}

		public two { 
			print &generic
			&second; 
		} describe "Add Documentation for method 'two'"
	};

	class +Inherit is +Simple {};



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

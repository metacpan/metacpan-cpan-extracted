package Sub::PatMat;
use 5.8.2;
use strict;
use warnings;
use B;
use B::Utils qw/walkoptree_filtered opgrep/;
use Carp;

use vars qw($VERSION);
$VERSION = 0.01;

my %whens;
my %names;
my $redefine_bitch;
my @redefinitions;

sub import
{
	no strict 'refs';
	my $pkg = caller(0);
	*{$pkg."::MODIFY_CODE_ATTRIBUTES"} = \&modify_code_attributes;
	eval "package $pkg; CHECK { Sub::PatMat::do_check(\"\Q$pkg\E\") }";
	eval "package $pkg; INIT { Sub::PatMat::do_init() }";
}

sub modify_code_attributes {
	my ($pkg, $sub, @attr) = @_;
	my @rest;
	my $when;
	for (@attr) {
		if (/^when(.*)$/) {
			$when = $1;
		} else {
			push @rest, $_;
		}
	}
	if (defined $when) {
		push @{$whens{$pkg}}, {
			func => $sub,
			when => $when,
		};
	}
	return @rest;
}

BEGIN {
my $old_warn_handler = $SIG{__WARN__}; 
$SIG{__WARN__} = sub { 
	return if $_[0] =~ /package attribute may clash with future reserved word: when/;
	if (!$redefine_bitch && $_[0] =~ /^Subroutine (.*) redefined/) {
		push @redefinitions, { func => $1, bitch => $_[0] };
		return;
	}
	goto &$old_warn_handler if $old_warn_handler;
	warn(@_);
};
}

sub create_pat_mat
{
	my ($pkg, $name, $info) = @_;
	my $code = "package $pkg; \*$name = sub {\n";
	my $op = "if";
	my $n = 0;
	my $cv = eval "*$pkg\::$name\{CODE}";
	if ($cv && @$info && $info->[-1]{func} ne $cv) {
		# print "fallback for $name: $cv\n";
		push @$info, { func => $cv, when => "()" };
	}
	for my $i (@$info) {
		my $cond = $i->{when};
		$cond = "(1)" if $cond eq "()";
		$cond = replace_aliases($cond, $info->[$n]{func});
		$code .= "$op $cond { &{\$info->[$n]{func}} }\n";
		$op = "elsif";
		$n++;
	}
	$code .= "else { use Carp; local \$Carp::CarpLevel = 1; croak \"Bad match calling \Q$name\E\" } }\n";
	# print $code;
	eval $code or die $@;
}

sub padname
{
	my ($padlist, $op) = @_;

	my $padname = $padlist->[0]->ARRAYelt($op->targ);
	if ($padname && !$padname->isa("B::SPECIAL")) {
		return if $padname->FLAGS & B::SVf_FAKE;
		return $padname->PVX;
	}
	return;
}

sub get_gv_name
{
	my ($padlist, $op) = @_;

	my ($gv_on_pad, $gv_idx);
	if ($op->isa("B::SVOP")) {
		$gv_idx = $op->targ;
	} elsif ($op->isa("B::PADOP")) {
		$gv_idx = $op->padix;
		$gv_on_pad = 1;
	} else {
		return "";
	}

	my $gv = $gv_on_pad ? "" : $op->sv;
	if (!$gv || !$$gv) {
		$gv = $padlist->[1]->ARRAYelt($gv_idx);
	}
	return "" unless $gv->isa("B::GV");
	$gv->NAME;
}

sub replace_aliases
{
	my ($cond, $sub) = @_;
	my $cv = B::svref_2object($sub);
	my $root = $cv->ROOT;
	my $padlist = [$cv->PADLIST->ARRAY];
	my %vars;
	walkoptree_filtered($root,
		sub { opgrep({ name => "aassign"}, @_) },
		sub {
			my ($op) = (@_);
			return unless
				$op->first->name eq "null" &&
				$op->first->first->name eq "pushmark" &&
				$op->first->first->sibling->name eq "rv2av" &&
				$op->first->first->sibling->first->name eq "gv" &&
				get_gv_name($padlist, $op->first->first->sibling->first) eq "_" &&
				$op->last->name eq "null" &&
				$op->last->first->name eq "pushmark";
			my %v;
			$op = $op->last->first->sibling;
			my $n = 0;
			my $ok = 1;
			while (1) {
				if ($op->name eq "padsv") {
					my $name = padname($padlist, $op);
					last unless $name;
					$v{$name} = "\$_[$n]";
					$n++;
				} elsif ($op->name eq "padav") {
					last;
				} elsif ($op->name eq "padhv") {
					last;
				} else {
					$ok = 0;  last;
				}
				$op = $op->sibling;
				last if $op->isa("B::NULL");
			}
			return unless $ok;
			%vars = %v;
		});
	for my $name (keys %vars) {
		$cond =~ s/\Q$name\E(?![\[\{])/$vars{$name}/g;
	}
	$cond;
}

sub do_check {
	my ($pkg) = @_;
	my %byname;
	for my $info (@{$whens{$pkg}}) {
		my $sub = $info->{func};
		my $cv = B::svref_2object($sub);
		my $gv = $cv->GV;
		my $name = $gv->NAME;
		$names{$name} = 1;
		$names{"$pkg\::$name"} = 1;
		push @{$byname{$name}}, $info;
	}
	for my $name (keys %byname) {
		create_pat_mat($pkg, $name, $byname{$name});
	}
}

sub do_init {
	for my $r (@redefinitions) {
		unless ($names{$r->{func}}) {
			$redefine_bitch = 1;
			warn $r->{bitch};
			$redefine_bitch = 0;
		}
	}
	@redefinitions = ();
}

1;
__END__

=head1 NAME

Sub::PatMat - call a version of subroutine depending on its arguments

=head1 VERSION

This document describes Sub::PatMat version 0.01

=head1 SYNOPSIS

  use Sub::PatMat;

  # basics:
  sub fact : when($_[0] <= 1) { 1 }
  sub fact                    { my ($n) = @_; $n*fact($n-1) }
  print fact(6);

  # referring to things other than @_:
  sub mysort : when($a < $b)  { -1 }
  sub mysort : when($a == $b) {  0 }
  sub mysort : when($a > $b)  {  1 }
  print join ", ", sort mysort (3,1,2);

  # intuiting parameter names:
  sub dispatch : when($ev eq "help") { my ($ev) = @_; print "help\n" }
  sub dispatch : when($ev eq "blah") { my ($ev) = @_; print "blah\n" }
  dispatch("help");
  dispatch("blah");
  # no fallback, this will die:
  dispatch("hest");  # dies with "Bad match"

  # silly
  sub do_something : when(full_moon()) { do_one_thing() }
  sub do_something                     { do_something_else() }

=head1 DESCRIPTION

The C<Sub::PatMat> module provides the programmer with the ability 
to define a subroutine multiple times and to specify what version
of the subroutine should be called, depending on the parameters
passed to it (or any other condition).

This is somewhat similar to argument pattern matching facility
provided by many programming languages.

To use argument pattern matching on a sub, the programmer has to specify
the C<when> attribute.  The parameter to the attribute must be
a single Perl expression.

When the sub is called, those expressions are evaluated
consequitively until one of them evaluates to a true value.
When this happens, the corresponding version of a sub is
called.

If none of the expressions evaluates to a true value, a
Bad Match exception is thrown.

It is possible to specify a fall-back version of the
function by doing one of the following:

=over

=item specifying C<when> without an expression

=item specifying C<when> with an empty expression

=item not specifying the C<when> attribute at all

=back

Please note that it does not make sense to specify any
non-fall-back version of the sub after the fall-back
version, since such will never be called.

There is an additional limitation for the last form of
the fall-back version (the one without the C<when> attribute at all),
namely, it must be the last version of the sub defined.

It is possible to specify named sub parameters in the
C<when>-expression.  This facility is highly experimental
and is currently limited to scalar parameters only.
The named sub parameters are extracted from expressions
of the form

  my (parameter list) = @_;

anywhere in the body of the sub.

=head1 BUGS AND LIMITATIONS

The ability to intuit parameter names is very limited and without
doubts buggy.

The C<when> attribute condition is limited to a single Perl expression.

=head1 SEE ALSO

Sub::PatternMatching, which does a more comprehensive job, 
but its syntax makes it difficult to use.

=head1 TODO

=over

=item support non-scalar named parameters

=item add positional parameter matching a la Erlang

=back

=head1 AUTHOR

Anton Berezin  C<< <tobez@tobez.org> >>

=head1 ACKNOWLEDGEMENTS

Thanks to Dmitry Karasik for discussion.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, Anton Berezin C<< <tobez@tobez.org> >>. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.


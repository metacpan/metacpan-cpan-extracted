package Regexp::Result;
use strict;
use warnings;
use Moo;
use 5.010; # we require ${^MATCH} etc
our $VERSION = '0.004';
use Exporter qw(import);
our @EXPORT_OK = qw(rr);
use Sub::Name 'subname';

=head1 NAME

Regexp::Result - store information about a regexp match for later retrieval

=head1 SYNOPSIS

	$foo =~ /(a|an|the) (\w+)/;
	my $result = Regexp::Result->new();
	
	# or, equivalently
	my $result = rr;	

	# ...
	# some other code which potentially executes a regular expression

	my $determiner = $result->c(1);
	# i.e. $1 at the time when the object was created

Have you ever wanted to retain information about a regular expression
match, without having to go through the palaver of pulling things out
of C<$1>, C<pos>, etc. and assigning them each to temporary variables
until you've decided what to use them as?

Regexp::Result objects, when created, contain as much information about
a match as perl can tell you. This means that you just need to create
one variable and keep it.

Hopefully, your code will be more comprehensible when it looks like
C<< $result->last_numbered_match_start->[-1] >>,
instead of C<$-[-1]>. The documentation for the punctuation
variables, by the way, is hidden away in C<perldoc perlvar>
along with scary things like C<^H>. I've copied most of it and/or
rewritten it below.

=head1 FUNCTIONS

=head3 rr

	use Regexp::Result qw(rr);
	
	$foo =~ /(a|an|the) (\w+)/;
	my $result = rr;	

Equivalent to calling C<< Regexp::Result->new() >>.	

=cut

sub rr {
	__PACKAGE__->new
}

=head1 METHODS

=head3 new

Creates a new Regexp::Result object. The object will gather data from
the last match (if successful) and store it for later retrieval.

Note that almost all of the contents are read-only.

=cut

=head3 numbered_captures

This accesses C<$1>, C<$2>, etc as C<< $rr->numbered_captures->[0] >>
etc. Note the numbering difference!

=cut

has numbered_captures=>
	is => 'ro',
	default => sub{
	    my $captures = [];
	    no strict 'refs';
	    for my $i (1..$#-) { #~ i.e until the end of LAST_MATCH_START
		push @$captures, ${$i};
	    }
	    use strict 'refs';
	    $captures;
	};

=head3 c

This accesses the contents of C<numbered_captures>, but uses numbers from 1
for comparability with C<$1>, C<$2>, C<$3>, etc.

=cut

sub c {
    my ($self, $number) = @_;
    if ($number) {
	#:todo: consider allowing more than one number
	return $self->numbered_captures->[$number - 1];
    }
    return undef;
}

sub _has_scalar {
	my ($name, $creator) = @_;
	has $name =>
		is => 'ro',
		default => $creator
}

#~ _has_array
#~
#~ 	_has_array primes => sub { [2,3,5,7,11] };
#~	$object->primes->[0]; # 2
#~	$object->primes(0);   # also 2

sub _has_array {
	my ($name, $creator) = @_;
	my $realName = '_'.$name;
	has $realName =>
		is => 'ro',
		default => $creator;
	my $accessor = sub {
		my $self = shift;
		if (@_) {
			#~ ideally check if @_ contains only numbers
			#~ Should foo(1,3) return something different?
			return $self->$realName->[@_];
		}
		else {
			return $self->$realName;
		}
	};
	{
		my $package = __PACKAGE__;
                no strict 'refs';
                my $fullName = $package . '::' . $name;
                *$fullName = subname( $name, $accessor );
        }
}

sub _has_hash {
	my ($name, $creator) = @_;
	my $realName = '_'.$name;
	has $realName =>
		is => 'ro',
		default => $creator;
	my $accessor = sub {
		my $self = shift;
		if (@_) {
			return $self->$realName->{@_};
		}
		else {
			return $self->$realName;
		}
	};
	{
		my $package = __PACKAGE__;
                no strict 'refs';
                my $fullName = $package . '::' . $name;
                *$fullName = subname( $name, $accessor );
        }
}

=head3 match, prematch, postmatch

	'The quick brown fox' =~ /q[\w]+/p;
	my $rr = Regexp::Result->new();
	print $rr->match;     # prints 'quick'
	print $rr->prematch;  # prints 'The '
	print $rr->postmatch; # prints ' brown fox'

When a regexp is executed with the C</p> flag, the variables
C<${^MATCH}>, C<${^PREMATCH}>, and C<${^POSTMATCH}> are set.
These correspond to the entire text matched by the regular expression,
the text in the string which preceded the matched text, and the text in
the string which followed it.

The C<match> method provides access to the data in C<${^MATCH}>.

The C<prematch> method provides access to the data in C<${^PREMATCH}>.

The C<postmatch> method provides access to the data in C<${^POSTMATCH}>.

Note: no accessor is provided for C<$&>, C<$`>, and C<$'>, because:

a) The author feels they are unnecessary since perl 5.10 introduced
C<${^MATCH}> etc.

b) Implementing accessors for them would force a performance penalty
on everyone who uses this module, even if they don't have any need of
C<$&>.

=cut

_has_scalar match => sub{
	   ${^MATCH}
	};

_has_scalar prematch => sub{
	   ${^PREMATCH}
	};

_has_scalar postmatch => sub{
	   ${^POSTMATCH}
	};
=head3 last_paren_match

Equivalent to C<$+>.

The text matched by the last capturing parentheses of the match.
This is useful if you don't know which one of a set of
alternative patterns matched. For example, in:

	/Version: (.*)|Revision: (.*)/

C<last_paren_match> stores either the version or revision (whichever
exists); perl would number these C<$1> and C<$2>.

=cut

_has_scalar last_paren_match => sub{
	   $+;
	};

=head3 last_submatch_result

Equivalent to C<$^N>.

=cut

_has_scalar last_submatch_result => sub{
	   $^N;
	};

=head3 last_numbered_match_end

Equivalent to C<@+>.

This array holds the offsets of the ends of the last successful
submatches in the currently active dynamic scope. C<$+[0]> is the
offset into the string of the end of the entire match. This is the
same value as what the C<pos> function returns when called on the
variable that was matched against. The nth element of this array
holds the offset of the nth submatch, so C<$+[1]> is the offset past
where C<$1> ends, C<$+[2]> the offset past where C<$2> ends, and so
on.

=cut

_has_array last_numbered_match_end => sub{
	   [@+]
	};

=head3 last_numbered_match_start

Equivalent to C<@->.

This array holds the offsets of the starts of the last successful
submatches in the currently active dynamic scope. C<$-[0]> is the
offset into the string of the start of the entire match. The nth
element of this array holds the offset of the nth submatch, so
C<$-[1]> is the offset where C<$1> starts, C<$-[2]> the offset
where C<$2> starts, and so on.

=cut

_has_array last_numbered_match_start => sub{
	   [@-]
	};
=head3 named_paren_matches

	'wxyz' =~ /(?<ODD>w)(?<EVEN>x)(?<ODD>y)(?<EVEN>z)/

	# named_paren_matches is now:
	#
	# {
	#     EVEN => [ 'x', 'z' ],
	#     ODD  => [ 'w', 'y' ]
	# }

Equivalent to C<%->.

This variable allows access to the named capture
groups in the last successful match in the currently active
dynamic scope. To each capture group name found in the regular
expression, it associates a reference to an array containing the
list of values captured by all buffers with that name (should
there be several of them), in the order where they appear.

=cut

_has_hash named_paren_matches => sub{
	   {%-}
	};

=head3 last_named_paren_matches

	'wxyz' =~ /(?<ODD>w)(?<EVEN>x)(?<ODD>y)(?<EVEN>z)/

	# last_named_paren_matches is now:
	#
	# {
	#     EVEN => 'x',
	#     ODD  => 'w',
	# }

The "%+" hash allows access to the named capture
buffers, should they exist, in the last successful match in the
currently active dynamic scope.

The keys of the "%+" hash list only the names of buffers that have
captured (and that are thus associated to defined values).

Note: C<%-> and C<%+> are tied views into a common internal hash
associated with the last successful regular expression. Therefore
mixing iterative access to them via C<each> may have unpredictable
results. Likewise, if the last successful match changes, then the
results may be surprising.

Author's note: I have no idea why this is a useful thing to use.
But perl provides it, and it is occasionally used according to
L<http://grep.cpan.me/> (461 distros, of which some the string
C<\%\+|\$\+\{> is in a binary stream).

=cut

_has_hash last_named_paren_match => sub{
	   {%+}
	};

=head3 last_regexp_code_result

The result of evaluation of the last successful C<(?{ code })>
regular expression assertion (see L<perlre>).

=cut

_has_scalar last_regexp_code_result => sub{
	   $^R;
	};

=head3 re_debug_flags

The current value of the regex debugging flags. Set to 0 for no
debug output even when the C<re 'debug'> module is loaded. See
L<re> for details.

=cut

_has_scalar re_debug_flags => sub{
	   ${^RE_DEBUG_FLAGS}
	};

=head3 pos

Returns the end of the match. Equivalent to C<$+[0]>.

=cut

sub pos {
    return shift->last_match_end->[0];
}

=head1 BUGS

Please report any bugs or feature requests to the github issues tracker at L<https://github.com/pdl/Regexp-Result/issues>. I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 AUTHORS

Daniel Perrett

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Daniel Perrett.

This program is free software; you can redistribute it and/or modify it under the terms of either: the GNU General Public License as published by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1;


package Regexp::Flow;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(re_matches re_substitutions);
use Regexp::Flow::Result;
use Regexp::Flow::Results;

=head1 NAME

Regexp::Flow - flow control for using regular expression

=cut

our $VERSION = '0.002';

=head1 SYNOPSIS

	use Regexp::Flow qw(re_matches re_substitutions);

	...

	my $m_results =
	    re_matches ( $string, $re, $code, $flags );

	my $s_results =
	    re_substitutions ( $string, $re, $code, $flags );

	...

	foreach (@$m_results) {
	    print $_->match; # assuming you used the /p flag
	}

	re_matches ( ... ) or warn 'no matches';
	# which is easier than using while, which doesn't allow or/else

=head1 FUNCTIONS

=cut

=head3 re_matches

	my $results = re_matches ( $string, $re, $code, $flags );
	my $results = re_matches ( $string, $re, $flags );
	say $_->prematch for re_matches('1.23', qr/\D/p,''); #?

Finds all instances of C<$re> within C<string> and runs C<$code> each
time a match is found. A M<Regexp:Flow::Result> object will be
created and passed as the first argument to C<$code>.

If C<$flags> is not present, C<g> will be assumed. If not, you must
include it yourself.

If the third argument is a string, it will be used as the flags.
Otherwise, it will be executed as a coderef on the
M<Regexp::Flow::Result> object, i.e. C<< $code->($rfr) >>

Within C<$code>, you can call C<last> on C<$rfr> to stop executing
C<$code> any more.

Note: Remember you can use any of C<msixpodual> on the regexp and do
not need to put these in C<$flags>.

So, for instance, to print C<$1> the first time it contains a word
character you could do:

	my $code = sub {
		my $rr = shift;
		if ($rr->c(1) =~ /\w/) {
			print $rr->c(1);
			$rr->last;
		}
	}

	my $string = q{'', 'a', 'b'});

	re_matches ($string, qr/'([^']+)',?/, $code);

The return value of C<$code> is discarded (this may change).

In scalar context, the return value is a L<Regexp::Flow::Results>
object (which evaluates to the number of times a match was found, and
allows access to each of the results contained within).

In void context, this value is not returned.

In list context, should it return each result?

=cut

sub re_matches {
	my $string = shift;
	my $re = shift;
	my $code = shift;
	my $flags = 'g';
	if (!ref $code) {
		$flags = $code if defined $code;
		$code = sub {};
	}
	elsif (@_) {
	    $flags = shift // $flags;
	}

	my $results;
	if (defined wantarray) {
		$results = Regexp::Flow::Results->new;
	}
	my $action = sub {
		my $rfr = shift;
		$rfr->string($string);
		$rfr->re($re);
		if (defined $results) {
			push @{$results->contents}, $rfr;
		}
		my $returnvalue = $code->($rfr);
		$returnvalue;
	};
	die unless $flags =~ /^[a-z]+$/;
	if ($flags =~ m/g/) {
		eval qq`
			while (\$string =~ m/\$re/$flags) {
				my \$rfr = Regexp::Flow::Result->new;
				\$action->(\$rfr);
				last if 'last' eq \$rfr->continue_action;
			}
		`; #~ we use the string eval to put flags in there.
	}
	else {
		eval qq`
			\$action->(
				Regexp::Flow::Result->new
			) if \$string =~ m/\$re/$flags;
		`;
	}
	if ($@) {
		die ($@);
	}
	return $results;
}

=head3 re_substitutions

	my $results = re_substitutions ( $string, $re, $code, $flags );
	my $results = re_substitutions ( $string, $re, $code );
	my $results = re_substitutions ( $string, $re, $string );
	my $results = re_substitutions ( $string, $re );

Finds all instances of C<$re> within C<$string> and runs C<$code> each
time a match is found. A L<Regexp:Flow::Result> object will be
created and passed as the first argument to C<$code>.
The return value of C<$code> is used as the replacement for the
matched string. If a string is passed as the third argument, it
(C<$string>) will be the replcement. Therefore B<do not> pass flags
as the third argument.

Just like C<s///>, this makes changes to the source string, unless
the C<r> flag is present, in which case the source string will be
untouched and the return value will be the modified string.

If flags are not provided, C<g> is assumed.

=cut

sub re_substitutions {
	my ($string, $re, $code, $flags) = @_; #~ we need to leave them in @_ to do in-place substitution
	if (!ref $code) {
		$code = sub {$code};
	}
	$flags //= 'g';
	my $rflag = ($flags =~ /r/ ? 1 :0 );
	my $results;
	if (defined wantarray) {
		$results = Regexp::Flow::Results->new;
	}
	my $last = 0;
	my $action = sub {
	    	my $rfr = shift;
		if (defined $results) {
			push @{$results->contents}, $rfr;
		}
		my $returnvalue = $code->($rfr);
		$last = 1 if 'last' eq $rfr->continue_action;
		$returnvalue;
	};
	die ('Unexpected flags [a-z] only permitted in '.$flags)
		unless $flags =~ /^[a-z]+$/;
	#~ In the following code, We will be using s~~~e
	eval qq`
		\$string =~ s~\$re~
    			my \$rfr = Regexp::Flow::Result->new;
			\$rfr->string(\$string);
			\$rfr->re(\$re);
			if (!\$last) {
				\$action->(\$rfr);
			}
			else {
			    \$rfr->match;
			}
		~e$flags
	`; #~ we use the string eval to put flags in there.
	if ($@) {
		warn ($@);
	}
	if ($rflag) {
		return $string;
	}
	#~ implicit else
	$_[0] = $string if $results;
	return $results;
}

=head1 SEE ALSO

Regexp::Result - base class for information about a regexp match

Regexp::Flow::Result - the class available within coderefs above

Regexp::Flow::Results - the list of results returned by functions above

=head1 BUGS

Please report any bugs or feature requests to the github issues tracker
at L<https://github.com/pdl/Regexp-Result/issues>. I will be notified,
and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 AUTHORS

Daniel Perrett

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Daniel Perrett.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;




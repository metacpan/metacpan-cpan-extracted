package Regex::PreSuf;

use strict;
local $^W = 1;
use vars qw($VERSION $DEBUG);

$VERSION = "1.17";

$DEBUG = 0;

=pod

=head1 NAME

Regex::PreSuf - create regular expressions from word lists

=head1 SYNOPSIS

	use Regex::PreSuf;
	
	my $re = presuf(qw(foobar fooxar foozap));

	# $re should be now 'foo(?:zap|[bx]ar)'

=head1 DESCRIPTION

The B<presuf()> subroutine builds regular expressions out of 'word
lists', lists of strings.  The regular expression matches the same
words as the word list.  These regular expressions normally run faster
than a simple-minded '|'-concatenation of the words.

Examples:

=over 4

=item *

	'foobar fooxar' => 'foo[bx]ar'

=item *

	'foobar foozap' => 'foo(?:bar|zap)'

=item *

	'foobar fooar'  => 'foob?ar'

=back

The downsides:

=over 4

=item *

The original order of the words is not necessarily respected,
for example because the character class matches are collected
together, separate from the '|' alternations.

=item *

The module blithely ignores any specialness of any regular expression
metacharacters such as the C<.*?+{}[]^$>, they are just plain ordinary
boring characters.

=back

For the second downside there is an exception.  The module has some
rudimentary grasp of how to use the 'any character' metacharacter.
If you call B<presuf()> like this:

	my $re = presuf({ anychar=>1 }, qw(foobar foo.ar fooxar));

	# $re should be now 'foo.ar'

The module finds out the common prefixes and suffixes of the words and
then recursively looks at the remaining differences.  However, by
default only common prefixes are used because for many languages
(natural or artificial) this seems to produce the fastest matchers.
To allow also for suffixes use

	my $re = presuf({ suffixes=>1 }, ...);

To use B<only> suffixes use

	my $re = presuf({ prefixes=>0 }, ...);

(this implicitly enables suffixes)

=head2 Debugging

In case you want to flood your session without debug messages
you can turn on debugging by saying

	Regex::PreSuf::debug(1);

How to turn them off again is left as an exercise for the kind reader.

=head1 COPYRIGHT

Jarkko Hietaniemi

This code is distributed under the same copyright terms as Perl itself.

=cut

use vars qw(@ISA @EXPORT);
require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(presuf);

sub debug {
    if (@_) {
	$DEBUG = shift;
    } else {
	return $DEBUG;
    }
}

sub prefix_length {
    my $n = 0;
    my %diff;

    for(my $m = 0; ; $m++) {
	foreach (@_) {
            $diff{ @{$_} <= $m ? '' : $_->[$m] }++;
	}
        last if keys %diff > 1;
	if (exists $diff{ '' } and $diff{ '' } == @_) {
	    %diff = ();
	    last;
	}
	%diff = ();
        $n = $m+1;
    }

    return ($n, %diff);
}

sub suffix_length {
    my $n = 0;
    my %diff;

    for(my $m = 1; ; $m++) {
	foreach (@_){
	    $diff{ @{$_} < $m ? '' : $_->[-$m] }++;
	}
        last if keys %diff > 1;
	if (exists $diff{ '' } and $diff{ '' } == @_) {
	    %diff = ();
	    last;
	}
        %diff = ();
        $n = $m;
    }

    return ($n, %diff);
}

sub _presuf {
    my $level = shift;
    my $INDENT = " " x $level if $DEBUG;
    my $param = shift;
    
    print "_presuf:$INDENT <- ", join(" ", map { join('', @$_) } @_), "\n"
	if $DEBUG;

    return '' if @_ == 0;

    if (@_ == 1) {
	my $presuf = join('', @{ $_[0] });
	print "_presuf:$INDENT -> $presuf\n" if $DEBUG;
	return $presuf;
    }

    my ($pre_n, %pre_d) = prefix_length @_;
    my ($suf_n, %suf_d) = suffix_length @_;

    if ($DEBUG) {
	print "_presuf:$INDENT pre_n = $pre_n (",join(" ",%pre_d),")\n";
	print "_presuf:$INDENT suf_n = $suf_n (",join(" ",%suf_d),")\n";
    }

    my $prefixes =  not exists $param->{ prefixes } ||
	                       $param->{ prefixes };
    my $suffixes =             $param->{ suffixes } ||
	           (    exists $param->{ prefixes } &&
                    not        $param->{ prefixes });

    if ($prefixes and not $suffixes) {
	# On qw(rattle rattlesnake) clear suffix.
	foreach (keys %pre_d) {
	    if ($_ eq '') {
		$suf_n = 0;
		%suf_d = ();
		last;
	    }
	}
    }

    if ($suffixes and not $prefixes) {
	foreach (keys %suf_d) {
	    if ($_ eq '') {
		$pre_n = 0;
		%pre_d = ();
		last;
	    }
	}
    }

    if ($pre_n or $suf_n) {
	if ($pre_n == $suf_n) {
	    my $eq_n = 1;
	    my $eq_s = join('', @{ $_[0] });

	    foreach (@_[ 1 .. $#_ ]) {
		last if $eq_s ne join('', @{ $_ });
		$eq_n++;
	    }

	    if ($eq_n == @_) {  # All equal.  How boring.
		print "_presuf:$INDENT -> $eq_s\n" if $DEBUG;
		return $eq_s;
	    }
	}

	my $ps_n = $pre_n + $suf_n;
	my $overlap; # Guard against prefix and suffix overlapping.

	foreach (@_) {
	    if (@{ $_ } < $ps_n) {
		$overlap = 1;
		last;
	    }
	}

	# Remove prefixes and suffixes and recurse.

	my $pre_s = $pre_n ?
	            join('', @{ $_[0] }[ 0 .. $pre_n - 1 ]) : '';
	my $suf_s = $suf_n ?
	            join('', @{ $_[0] }[ -$suf_n .. -1 ]) : '';
	my @presuf;

	if ($overlap) {
	    if ($prefixes and not $suffixes) {
		$suf_s = '';
		foreach (@_) {
		    push @presuf,
                         [ @{ $_ }[ $pre_n .. $#{ $_ } ] ];
		}
	    } elsif ($suffixes) {
		$pre_s = '';
		foreach (@_) {
		    push @presuf,
                         [ @{ $_ }[ 0 .. $#{ $_ } - $suf_n ] ];
		}
	    }
	} else {
	    foreach (@_) {
		push @presuf,
                     [ @{ $_ }[ $pre_n .. $#{ $_ } - $suf_n ] ];
	    }
	}

	if ($DEBUG) {
	    print "_presuf:$INDENT pre_s = $pre_s\n";
	    print "_presuf:$INDENT suf_s = $suf_s\n";
	    print "_presuf:$INDENT presuf = ",
	          join(" ", map { join('', @$_) } @presuf), "\n";
	}

	my $presuf = $pre_s . _presuf($level + 1, $param, @presuf) . $suf_s;

	print "_presuf:$INDENT -> $presuf\n" if $DEBUG;

	return $presuf;
    } else {
	my @len_n;
	my @len_1;
	my $len_0 = 0;
	my (@alt_n, @alt_1);

	foreach (@_) {
	    my $len = @{$_};
	    if    ($len >  1) { push @len_n, $_ }
	    elsif ($len == 1) { push @len_1, $_ }
	    else              { $len_0++        } # $len == 0
	}

	# NOTE: does not preserve the order of the words.

	if (@len_n) {	# Alternation.
	    if (@len_n == 1) {
		@alt_n = join('', @{ $len_n[0] });
	    } else {
		my @pre_d = keys %pre_d;
		my @suf_d = keys %suf_d;

		my (%len_m, @len_m);

		if ($prefixes and $suffixes) {
		    if (@pre_d < @suf_d) {
			$suffixes = 0;
		    } else {
			if (@pre_d == @suf_d) {
			    if ( $param->{ suffixes } ) {
				$prefixes = 0;
			    } else {
				$suffixes = 0;
			    }
			} else {
			    $prefixes = 0;
			}
		    }
		}

		if ($prefixes) {
		    foreach (@len_n) {
			push @{ $len_m{ $_->[  0 ] } }, $_;
		    }
		} elsif ($suffixes) {
		    foreach (@len_n) {
			push @{ $len_m{ $_->[ -1 ] } }, $_;
		    }
		}

		foreach (sort keys %len_m) {
		    if (@{ $len_m{ $_ } } > 1) {
			push @alt_n,
                             _presuf($level + 1, $param, @{ $len_m{ $_ } });
		    } else {
			push @alt_n, join('', @{ $len_m{ $_ }->[0] });
		    }
		}
	    }
	}

	if (@len_1) { # Character classes.
	    if ($param->{ anychar } and
		(exists $pre_d{ '.' } or exists $suf_d{ '.' }) and
	        grep { $_->[0] eq '.' } @len_1) {
		push @alt_1, '.';
	    } else {
		if (@len_1 == 1) {
		    push @alt_1,
                         join('', @{$len_1[0]});
		} else {
		    my %uniq;
		    push @alt_1,
                         join('', '[', (sort
					grep { ! $uniq{$_}++ }
					map { join('', @$_) } @len_1), ']' );
		}
	    }
	}

	my $alt = join('|', @alt_n, @alt_1);

	$alt = '(?:' . $alt . ')' unless @alt_n == 0;

	$alt .= '?' if $len_0;

	print "_presuf:$INDENT -> $alt\n" if $DEBUG;

	return $alt;
    }
}

sub presuf {
    my $param = ref $_[0] eq 'HASH' ? shift : { };

    return '' if @_ == 0;

    my @args = map { quotemeta() } @_;

    # Undo quotemeta for anychars.
    @args = map { s/\\\././g; $_ } @args if $param->{ anychar };

    s/\\(\s)/$1/g for @args;

    foreach (@args) {
	$_ = [ /(\\?.)/gs ];
    }

    return _presuf(0, $param, @args);
}

1;

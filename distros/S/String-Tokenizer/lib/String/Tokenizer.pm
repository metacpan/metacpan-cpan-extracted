
package String::Tokenizer;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.06';

use constant RETAIN_WHITESPACE => 1;
use constant IGNORE_WHITESPACE => 0;

### constructor

sub new {
	my ($_class, @args) = @_;
	my $class = ref($_class) || $_class;
	my $string_tokenizer = {
		tokens => [],
        delimiter => undef,
        handle_whitespace => IGNORE_WHITESPACE
		};
	bless($string_tokenizer, $class);
	$string_tokenizer->tokenize(@args) if @args;
	return $string_tokenizer;
}

### methods

sub setDelimiter {
    my ($self, $delimiter) = @_;
    my $delimiter_reg_exp = join "\|" => map { s/(\W)/\\$1/g; $_ } split // => $delimiter;
    $self->{delimiter} = qr/$delimiter_reg_exp/;
}

sub handleWhitespace {
    my ($self, $value) = @_;
    $self->{handle_whitespace} = $value;
}

sub tokenize {
	my ($self, $string, $delimiter, $handle_whitespace) = @_;
    # if we have a delimiter passed in then use it
    $self->setDelimiter($delimiter)             if defined $delimiter;
    # if we are asking about whitespace then handle it
    $self->handleWhitespace($handle_whitespace) if defined $handle_whitespace;
    # if the two above are not handled, then the object will use
    # the values set already.
	# split everything by whitespace no matter what
	# (possible multiple occurances of white space too)
	my @tokens;
    if ($self->{handle_whitespace}) {
        @tokens = split /(\s+)/ => $string;
    }
    else {
        @tokens = split /\s+/ => $string;
    }
	if ($self->{delimiter}) {
		# create the delimiter reg-ex
		# escape all non-alpha-numeric
		# characters, just to be safe
		my $delimiter = $self->{delimiter};
		# loop through the tokens
		@tokens = map {
				# if the token contains a delimiter then ...
				if (/$delimiter/) {
					my ($token, @_tokens);
					# split the token up into characters
					# and the loop through all the characters
					foreach my $char (split //) {
						# if the character is a delimiter
						if ($char =~ /^$delimiter$/) {
							# and we already have a token in the works
							if (defined($token) && $token =~ /^.*$/) {
								# add the token to the
								# temp tokens list
								push @_tokens => $token;
							}
							# and then push our delimiter character
							# onto the temp tokens list
							push @_tokens => $char;
							# now we need to undefine our token
							$token = undef;
						}
						# if the character is not a delimiter then
						else {
							# check to make sure the token is defined
							$token = "" unless defined $token;
							# and then add the chracter to it
							$token .= $char;
						}
					}
					# now push any remaining token onto
					# the temp tokens list
					push @_tokens => $token if defined $token;
					# and return tokens
					@_tokens;
				}
				# if our token does not have
				# the delimiter in it
				else {
					# just return it
					$_
				}
			} @tokens;
	}
	$self->{tokens} = \@tokens;
}

sub getTokens {
	my ($self) = @_;
	return wantarray ?
			@{$self->{tokens}}
			:
			$self->{tokens};
}

sub iterator {
    my ($self) = @_;
    # returns a copy of the array
    return String::Tokenizer::Iterator->new($self->{tokens});
}

package String::Tokenizer::Iterator;

use strict;
use warnings;

sub new {
    ((caller())[0] eq "String::Tokenizer")
        || die "Insufficient Access Priviledges : Only String::Tokenizer can create String::Tokenizer::Iterator instances";
    my ($_class, $tokens) = @_;
    my $class = ref($_class) || $_class;
    my $iterator = {
        tokens => $tokens,
        index => 0
        };
    bless($iterator, $class);
    return $iterator;
}

sub reset {
    my ($self) = @_;
    $self->{index} = 0;
}

sub hasNextToken {
    my ($self) = @_;
    return ($self->{index} < scalar @{$self->{tokens}}) ? 1 : 0;
}

sub hasPrevToken {
    my ($self) = @_;
    return ($self->{index} > 0);
}

sub nextToken {
    my ($self) = @_;
    return undef if ($self->{index} >= scalar @{$self->{tokens}});
    return $self->{tokens}->[$self->{index}++];
}

sub prevToken {
    my ($self) = @_;
    return undef if ($self->{index} <= 0);
    return $self->{tokens}->[--$self->{index}];
}

sub currentToken {
    my ($self) = @_;
    return $self->{tokens}->[$self->{index} - 1];
}

sub lookAheadToken {
    my ($self) = @_;
    return undef if (  $self->{index} <= 0
                    || $self->{index} >= scalar @{$self->{tokens}});
    return $self->{tokens}->[$self->{index}];
}

sub collectTokensUntil {
    my ($self, $token_to_match) = @_;
    # if this matches our current token ...
    # then we just return nothing as there
    # is nothing to accumulate
    if ($self->lookAheadToken() eq $token_to_match) {
        # then just advance it one
        $self->nextToken();
        # and return nothing
        return;
    }

    # if it doesnt match our current token then, ...
    my @collection;
    # store the index we start at
    my $old_index = $self->{index};
    my $matched;
    # loop through the tokens
    while ($self->hasNextToken()) {
        my $token = $self->nextToken();
        if ($token ne $token_to_match) {
            push @collection => $token;
        }
        else {
            $matched++;
            last;
        }
    }
    unless ($matched) {
        # reset back to where we started, and ...
        $self->{index} = $old_index;
        # and return nothing
        return;
    }
    # and return our collection
    return @collection;
}


sub skipTokensUntil {
    my ($self, $token_to_match) = @_;
    # if this matches our current token ...
    if ($self->lookAheadToken() eq $token_to_match) {
        # then just advance it one
        $self->nextToken();
        # and return success
        return 1;
    }
    # if it doesnt match our current token then, ...
    # store the index we start at
    my $old_index = $self->{index};
    # and loop through the tokens
    while ($self->hasNextToken()) {
        # return success if we match our token
        return 1 if ($self->nextToken() eq $token_to_match);
    }
    # otherwise we didnt match, and should
    # reset back to where we started, and ...
    $self->{index} = $old_index;
    # return failure
    return 0;
}

sub skipTokenIfWhitespace {
    my ($self) = @_;
    $self->{index}++ if $self->lookAheadToken() =~ /^\s+$/;
}

sub skipTokens {
    my ($self, $num_token_to_skip) = @_;
    $num_token_to_skip ||= 1;
    $self->{index} += $num_token_to_skip;
}

*skipToken = \&skipTokens;

1;

__END__

=head1 NAME

String::Tokenizer - A simple string tokenizer.

=head1 SYNOPSIS

  use String::Tokenizer;

  # create the tokenizer and tokenize input
  my $tokenizer = String::Tokenizer->new("((5+5) * 10)", '+*()');

  # create tokenizer
  my $tokenizer = String::Tokenizer->new();
  # ... then tokenize the string
  $tokenizer->tokenize("((5 + 5) - 10)", '()');

  # will print '(, (, 5, +, 5, ), -, 10, )'
  print join ", " => $tokenizer->getTokens();

  # create tokenizer which retains whitespace
  my $st = String::Tokenizer->new(
                'this is a test with,    (significant) whitespace',
                ',()',
                String::Tokenizer->RETAIN_WHITESPACE
                );

  # this will print:
  # 'this', ' ', 'is', ' ', 'a', ' ', 'test', ' ', 'with', '	', '(', 'significant', ')', ' ', 'whitespace'
  print "'" . (join "', '" => $tokenizer->getTokens()) . "'";

  # get a token iterator
  my $i = $tokenizer->iterator();
  while ($i->hasNextToken()) {
      my $next = $i->nextToken();
      # peek ahead at the next token
      my $look_ahead = $i->lookAheadToken();
      # ...
      # skip the next 2 tokens
      $i->skipTokens(2);
      # ...
      # then backtrack 1 token
      my $previous = $i->prevToken();
      # ...
      # get the current token
      my $current = $i->currentToken();
      # ...
  }

=head1 DESCRIPTION

A simple string tokenizer which takes a string and splits it on whitespace. It also optionally takes a string of characters to use as delimiters, and returns them with the token set as well. This allows for splitting the string in many different ways.

This is a very basic tokenizer, so more complex needs should be either addressed with a custom written tokenizer or post-processing of the output generated by this module. Basically, this will not fill everyone's needs, but it spans a gap between simple C<split / /, $string> and the other options that involve much larger and complex modules.

Also note that this is not a lexical analyser. Many people confuse tokenization with lexical analysis. A tokenizer merely splits its input into specific chunks, a lexical analyzer classifies those chunks. Sometimes these two steps are combined, but not here.

=head1 METHODS

=over 4

=item B<new ($string, $delimiters, $handle_whitespace)>

If you do not supply any parameters, nothing happens, the instance is just created. But if you do supply parameters, they are passed on to the C<tokenize> method and that method is run. For information about those arguments, see C<tokenize> below.

=item B<setDelimiter ($delimiter)>

This can be used to set the delimiter string, this is used by C<tokenize>.

=item B<handleWhitespace ($value)>

This can be used to set the whitespace handling. It accepts one of the two constant values C<RETAIN_WHITESPACE> or C<IGNORE_WHITESPACE>.

=item B<tokenize ($string, $delimiters, $handle_whitespace)>

Takes a C<$string> to tokenize, and optionally a set of C<$delimiter> characters to facilitate the tokenization and the type of whitespace handling with C<$handle_whitespace>. The C<$string> parameter and the C<$handle_whitespace> parameter are pretty obvious, the C<$delimiter> parameter is not as transparent. C<$delimiter> is a string of characters, these characters are then separated into individual characters and are used to split the C<$string> with. So given this string:

  (5 + (100 * (20 - 35)) + 4)

The C<tokenize> method without a C<$delimiter> parameter would return the following comma separated list of tokens:

  '(5', '+', '(100', '*', '(20', '-', '35))', '+', '4)'

However, if you were to pass the following set of delimiters C<(, )> to C<tokenize>, you would get the following comma separated list of tokens:

  '(', '5', '+', '(', '100', '*', '(', '20', '-', '35', ')', ')', '+', '4', ')'

We now can differentiate the parens from the numbers, and no globbing occurs. If you wanted to allow for optionally leaving out the whitespace in the expression, like this:

  (5+(100*(20-35))+4)

as some languages do. Then you would give this delimiter C<+*-()> to arrive at the same result.

If you decide that whitespace is significant in your string, then you need to specify that like this:

  my $st = String::Tokenizer->new(
                'this is a test with,    (significant) whitespace',
                ',()',
                String::Tokenizer->RETAIN_WHITESPACE
                );

A call to C<getTokens> on this instance would result in the following token set.

 'this', ' ', 'is', ' ', 'a', ' ', 'test', ' ', 'with', '	', '(', 'significant', ')', ' ', 'whitespace'

All running whitespace is grouped together into a single token, we make no attempt to split it into its individual parts.

=item B<getTokens>

Simply returns the array of tokens. It returns an array-ref in scalar context.

=item B<iterator>

Returns a B<String::Tokenizer::Iterator> instance, see below for more details.

=back

=head1 INNER CLASS

A B<String::Tokenizer::Iterator> instance is returned from the B<String::Tokenizer>'s C<iterator> method and serves as yet another means of iterating through an array of tokens. The simplest way would be to call C<getTokens> and just manipulate the array yourself, or push the array into another object. However, iterating through a set of tokens tends to get messy when done manually. So here I have provided the B<String::Tokenizer::Iterator> to address those common token processing idioms. It is basically a bi-directional iterator which can look ahead, skip and be reset to the beginning.

B<NOTE:>
B<String::Tokenizer::Iterator> is an inner class, which means that only B<String::Tokenizer> objects can create an instance of it. That said, if B<String::Tokenizer::Iterator>'s C<new> method is called from outside of the B<String::Tokenizer> package, an exception is thrown.

=over 4

=item B<new ($tokens_array_ref)>

This accepts an array reference of tokens and sets up the iterator. This method can only be called from within the B<String::Tokenizer> package, otherwise an exception will be thrown.

=item B<reset>

This will reset the internal counter,
bringing it back to the beginning of the token list.

=item B<hasNextToken>

This will return true (1) if there are more tokens to be iterated over,
and false (0) otherwise.

=item B<hasPrevToken>

This will return true (1) if the beginning of the token list has been reached, and false (0) otherwise.

=item B<nextToken>

This dispenses the next available token, and move the internal counter ahead by one.

=item B<prevToken>

This dispenses the previous token, and moves the internal counter back by one.

=item B<currentToken>

This returns the current token, which will match the last token retrieved by C<nextToken>.

=item B<lookAheadToken>

This peeks ahead one token to the next one in the list. This item will match the next item dispensed with C<nextToken>. This is a non-destructive look ahead, meaning it does not alter the position of the internal counter.

=item B<skipToken>

This will jump the internal counter ahead by 1.

=item B<skipTokens ($number_to_skip)>

This will jump the internal counter ahead by C<$number_to_skip>.

=item B<skipTokenIfWhitespace>

This will skip the next token if it is whitespace.

=item B<skipTokensUntil ($token_to_match)>

Given a string as a C<$token_to_match>, this will skip all tokens until it matches that string. If the C<$token_to_match> is never matched, then the iterator will return the internal pointer to its initial state.

=item B<collectTokensUntil ($token_to_match)>

Given a string as a C<$token_to_match>, this will collect all tokens until it matches that string, at which point the collected tokens will be returned. If the C<$token_to_match> is never matched, then the iterator will return the internal pointer to its initial state and no tokens will be returned.

=back

=head1 TO DO

=over 4

=item I<Inline token expansion>

The Java StringTokenizer class allows for a token to be tokenized further, therefore breaking it up more and including the results into the current token stream. I have never used this feature in this class, but I can see where it might be a useful one. This may be in the next release if it works out.

Possibly compliment this expansion with compression as well, so for instance double quoted strings could be compressed into a single token.

=item I<Token Bookmarks>

Allow for the creation of "token bookmarks". Meaning we could tag a specific token with a label, that index could be returned to from any point in the token stream. We could mix this with a memory stack as well, so that we would have an ordering to the bookmarks as well.

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it.

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module's test suite.

 ------------------------ ------ ------ ------ ------ ------ ------ ------
 File                       stmt branch   cond    sub    pod   time  total
 ------------------------ ------ ------ ------ ------ ------ ------ ------
 String/Tokenizer.pm       100.0  100.0   64.3  100.0  100.0  100.0   97.6
 ------------------------ ------ ------ ------ ------ ------ ------ ------
 Total                     100.0  100.0   64.3  100.0  100.0  100.0   97.6
 ------------------------ ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

The interface and workings of this module are based largely on the StringTokenizer class from the Java standard library.

Below is a short list of other modules that might be considered similar to this one. If this module does not suit your needs, you might look at one of these.

=over 4

=item L<String::Tokeniser>

Along with being a tokenizer,
it also provides a means of moving through the resulting tokens,
allowing for skipping of tokens and such.
It was last updated in 2011.

=item L<Parse::Tokens>

This one hasn't been touched since 2001,
although it did get up to version 0.27.
It looks to lean over more towards the parser side than a basic tokenizer.

=item L<Text::Tokenizer>

This is both a lexical analyzer and a tokenizer.
It also uses XS, where String::Tokenizer is pure perl.
This is something maybe to look into if you were to need a more beefy solution
than String::Tokenizer provides.

=back

=head1 THANKS

=over

=item Thanks to Stephan Tobias for finding bugs and suggestions on whitespace handling.

=back

=head1 AUTHOR

stevan little, E<lt>stevan@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2016 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

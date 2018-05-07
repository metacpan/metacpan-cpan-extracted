package Search::Tools::TokenListPP;
use Moo;
extends 'Search::Tools::Object';
use overload
    '""'     => sub { $_[0]->str; },
    'bool'   => sub { $_[0]->len; },
    fallback => 1;
use Carp;
with 'Search::Tools::TokenListUtils';

our $VERSION = '1.007';

has 'pos' => ( is => 'rw' );
has 'num' => ( is => 'rw' );

sub len {
    return scalar @{ $_[0]->{tokens} };
}

sub get_heat {
    return $_[0]->{heat};
}

sub next {
    my $self   = shift;
    my $tokens = $self->{tokens};
    my $len    = scalar(@$tokens) - 1;
    if ( $len == -1 ) {
        return;
    }
    elsif ( $self->{pos} > $len ) {
        return;
    }
    else {
        return $tokens->[ $self->{pos}++ ];
    }
}

sub prev {
    my $self   = shift;
    my $tokens = $self->{tokens};
    my $len    = scalar(@$tokens) - 1;
    if ( $len == -1 ) {
        return;
    }
    elsif ( $self->{pos} < 0 ) {
        return;
    }
    else {
        return $tokens->[ --$self->{pos} ];
    }
}

sub reset {
    $_[0]->{pos} = 0;
}

sub set_pos {
    $_[0]->{pos} = $_[1];
}

sub get_token {
    my $self = shift;
    my $len  = scalar( @{ $self->{tokens} } ) - 1;
    my $i    = shift;
    if ( !defined $i ) {
        croak "index position required";
    }
    if ( !defined $self->{tokens}->[$i] ) {
        return;
    }
    else {
        return $self->{tokens}->[$i];
    }
}

sub as_array {
    return $_[0]->{tokens};
}

sub matches {
    return [ grep { $_->{is_match} } @{ $_[0]->{tokens} } ];
}

sub num_matches {
    return scalar @{ shift->matches };
}

1;

__END__

=head1 NAME

Search::Tools::TokenListPP - a bunch of tokens from a Tokenizer

=head1 SYNOPSIS

 use Search::Tools::Tokenizer;
 my $tokenizer = Search::Tools::Tokenizer->new();
 my $tokens = $tokenizer->tokenize_pp('quick brown red dog');
 
 # use like an iterator
 while ( my $token = $tokens->next ) {
    # token isa Search::Tools::Token
 }
 # iterate the other way
 while ( my $token = $tokens->prev ) {
    # ...
 }
 
 # fetch a particular token
 my $token = $tokens->get_token( $position );
 
 # reset the iterator
 $tokens->reset;
 
 # get the current iterator position
 my $pos = $tokens->pos;
 
 # set the iterator position
 $tokens->set_pos( $pos + 1 );
 
 # how many tokens originally?
 my $num = $tokens->num;
 
 # treat like array
 push( @{ $tokens->as_array }, $new_token );
 
 # now how many tokens?
 my $len = $tokens->len;    # $len != $num
 
 # get all the hot tokens
 my $heat = $tokens->get_heat;
 
 # get all the matches to the regex in Tokenizer
 my $matches = $tokens->get_matches;
 
 # just the number of matches
 my $num_matches = $tokens->num_matches;
 
 
=head1 DESCRIPTION

A TokenListPP is a pure-Perl version of TokenList.
See the docs for TokenList for more details.

=head1 METHODS

See Search::Tools::TokenListUtils for other methods available on this class.

This class inherits from Search::Tools::Object. Only new or overridden
methods are documented here.

=head2 next

Get the next Token.

=head2 prev

Get the previous Token.

=head2 pos

Get the iterator position.

=head2 set_pos

Set the iterator position.

=head2 reset

Same as calling:

 $tokens->set_pos(0);

=head2 len

The number of Tokens in the TokenList.

=head2 num

The number of Tokens initially parsed by the Tokenizer. This is the same
value as len() unless you alter the TokenList via as_array().

=head2 as_array

Returns an array ref to the internal array of tokens. If you alter
the array, it will alter the len() value but not the num() value.

=head2 get_heat

Returns an array ref to the internal array of tokens with
is_hot() set by the original Tokenizer. This method will return an
empty list unless you have passed a heat_seeker to the tokenize_pp() method.
See Search::Tools::Tokenizer.

=head2 matches

Returns an array ref of all the Tokens with is_match() set. The
array is constructed at the time you call the method so if you alter the array
it will not affect the TokenListPP object, but if you alter a Token
in the array it will affect the Token in the TokenListPP object.

=head2 num_matches

Like calling:

 my $num = scalar @{ $tokens->matches };

=head2 get_token( I<position> )

Returns the Token at I<position>. If I<position> is invalid returns
undef.

=head1 AUTHOR

Peter Karman C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-tools at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Tools>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Tools


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Tools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Tools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Tools>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Tools/>

=back

=head1 COPYRIGHT

Copyright 2009 by Peter Karman.

This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

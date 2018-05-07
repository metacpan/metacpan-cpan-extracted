package Search::Tools::TokenList;
use Moo;
with 'Search::Tools::TokenListUtils';
use overload
    '""'     => sub { $_[0]->str; },
    'bool'   => sub { 1 }, # always true
    fallback => 1;

use Search::Tools;    # XS required
use Carp;

use namespace::autoclean;

our $VERSION = '1.007';

1;

__END__

=head1 NAME

Search::Tools::TokenList - a bunch of tokens from a Tokenizer

=head1 SYNOPSIS

 use Search::Tools::Tokenizer;
 my $tokenizer = Search::Tools::Tokenizer->new();
 my $tokens = $tokenizer->tokenize('quick brown red dog');
 
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

A TokenList is an object containing Tokens. You may treat it like an iterator
or an array, and call methods on it to get/set attributes.

=head1 METHODS

Most of Search::Tools::TokenList is written in C/XS so if you view the source of
this class you will not see much code. Look at the source for Tools.xs and
search-tools.c if you are interested in the internals, or look at
Search::Tools::TokenListPP.

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

The number of Tokens in the internal AV (array).

=head2 num

The number of Tokens initially parsed by the Tokenizer. This is the same
value as len() unless you alter the TokenList via as_array().

=head2 as_array

Returns an array ref to the internal AV (array) of tokens. If you alter
the array, it will alter the len() value but not the num() value.

=head2 dump

Prints internal XS attributes to stderr.

=head2 get_heat

Returns an array ref to the internal AV (array) of positions with
is_hot() set by the original Tokenizer. This method will return an
empty list unless you have passed a heat_seeker to the tokenize() method.
See Search::Tools::Tokenizer.

=head2 get_sentence_starts

Returns an array ref to the internal AV (array) of sentence start
positions for each position in get_heat().

=head2 matches

Returns an array ref of all the Tokens with is_match() set. The
array is constructed at the time you call the method so if you alter the array
it will not affect the TokenList object, but if you alter a Token
in the array it will affect the Token in the TokenList object.

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

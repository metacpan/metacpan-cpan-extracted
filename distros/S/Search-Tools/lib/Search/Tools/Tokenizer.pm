package Search::Tools::Tokenizer;
use Moo;
extends 'Search::Tools::Object';
use Search::Tools;    # XS package required
use Search::Tools::Token;
use Search::Tools::TokenList;
use Search::Tools::UTF8;
use Carp;

our $VERSION = '1.007';

has 're' => ( is => 'rw', default => sub {qr/\w+(?:[\'\-\.]\w+)*/} );

sub BUILD {
    my $self = shift;
    if ( $self->debug ) {
        $self->set_debug( $self->debug - 1 );    # XS debug a level higher
    }
    return $self;
}

sub tokenize_pp {
    require Search::Tools::TokenPP;
    require Search::Tools::TokenListPP;

    my $self = shift;
    if ( !defined $_[0] ) {
        croak "str required";
    }

    # XS modifies the original arg, so we do too.
    # this is same slight optimization XS does. ~5%
    if ( !is_ascii( $_[0] ) ) {
        $_[0] = to_utf8( $_[0] );
    }
    my $heat_seeker = $_[1];

    # match_num ($_[2]) not supported in PP

    my @heat   = ();
    my @tokens = ();
    my $i      = 0;
    my $re     = $self->{re};
    my $heat_seeker_is_coderef
        = ( defined $heat_seeker and ref($heat_seeker) eq 'CODE' ) ? 1 : 0;

    # TODO is_sentence_* logic
    for ( split( m/($re)/, $_[0] ) ) {
        next unless length($_);
        my $tok = bless(
            {   'pos'    => $i++,
                str      => $_,
                is_hot   => 0,
                is_match => 0,
                len      => byte_length($_),
                u8len    => length($_),
            },
            'Search::Tools::TokenPP'
        );
        if ( $_ =~ m/^$re$/ ) {
            $tok->{is_match} = 1;
            if ($heat_seeker_is_coderef) {
                $heat_seeker->($tok);
            }
            elsif ( defined $heat_seeker ) {
                $tok->{is_hot} = $_ =~ m/$heat_seeker/;
            }
        }
        push( @heat, $tok->{pos} ) if $tok->{is_hot};
        push @tokens, $tok;
    }
    return bless(
        {   tokens => \@tokens,
            num    => $i,
            'pos'  => 0,
            heat   => \@heat,
        },
        'Search::Tools::TokenListPP'
    );
}

1;

__END__

=head1 NAME

Search::Tools::Tokenizer - split a string into meaningful tokens

=head1 SYNOPSIS

 use Search::Tools::Tokenizer;
 my $tokenizer = Search::Tools::Tokenizer->new();
 my $tokens = $tokenizer->tokenize('quick brown red dog');
 while ( my $token = $tokens->next ) {
     # token isa Search::Tools::Token
     print "token = $token\n";
     printf("str: %s, len = %d, u8len = %d, pos = %d, is_match = %d, is_hot = %d\n",
        $token->str,
        $token->len, 
        $token->u8len, 
        $token->pos, 
        $token->is_match, 
        $token->is_hot
     );
 }

=head1 DESCRIPTION

A Tokenizer object splits a string into Tokens based on a regex.
Tokenizer is used primarily by the Snipper class.

=head1 METHODS

Most of Search::Tools::Tokenizer is written in C/XS 
so if you view the source of this class you will not see much code. 
Look at the source for Tools.xs and search-tools.c if you are 
interested in the internals.

This class inherits from Search::Tools::Object. Only new or overridden
methods are documented here.

=head2 BUILD

Called by new().

=head2 re([ I<regex> ])

Get/set the I<regex> used by tokenize() tokenize_pp(). Typically
you set this once in new(). The default value is:

 qr/\w+(?:'\w+)*/

which will match words and contractions (e.g., "do", "not" and "don't").

=head2 tokenize( I<string> [, I<heat_seeker>, I<match_num>] )

Returns a TokenList object representin the Tokens in I<string>.
I<string> is "split" according to the regex in re().

I<heat_seeker> can be either a CODE reference or a regex object (qr//)
to use for testing is_hot per token. An example CODE reference:

 my $tokens = $tokenizer->tokenize('foo bar', sub { 
    my ($token) = @_;
    # do something with token during initial iteration
 },);

I<match_num> is the parentheses number to consider the matching token
in the re() value. The default is 0 (the entire matching pattern).

=head2 tokenize_pp( I<string> )

Returns a TokenListPP object.

A pure-Perl implementation of tokenize(). Mostly written so you can
see what the XS algorithm does, if you are so inclined, and so the author
could benchmark the two implementations and thereby feel some satisfaction 
at having spent the time writing the XS/C version (2-3x faster than Perl).

=head2 get_offsets( I<string>, I<regex> )

Returns an array ref of pos() values for start offsets of I<regex> within
I<string>

=head2 set_debug( I<n> )

Sets the XS debugger on. By default, setting debug(1) (which is inherited
from Search::Tools::Object) is not sufficient to trigger the XS
debugging. Use set_debug() if you want lots of info on stderr.

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

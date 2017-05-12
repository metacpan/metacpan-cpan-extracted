package Search::MultiMatch;

use 5.010;
use strict;
use warnings;

=head1 NAME

=encoding utf8

Search::MultiMatch - An efficient, tree-based, 2D multimatcher.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

B<Search::MultiMatch> works by creating a multidimensional hash-table
with keys as 2D-arrays, which are stored as nodes.

It accepts matching the stored entries with a pattern, that is
also a 2D-array, identifying matches by walking the table from node to node.

    use Search::MultiMatch;

    # Create a SMM object
    my $smm = Search::MultiMatch->new();

    # Add an entry
    $smm->add($key, $value);                # key is a 2D-array

    # Search with a pattern
    my @matches = $smm->search($pattern);   # pattern is a 2D-array

=head1 METHODS

=head2 new

Creates and returns a new object.

    my $smm = Search::MultiMatch->new(%opt);

Where C<%opt> understands the following options:

=over 2

=item * table => {}

The value of the C<table> must be a multidimensional hash-like data structure.

=back

=cut

sub new {
    my ($class, %opt) = @_;
    bless {table => $opt{table} // {}}, $class;
}

=head2 add

Synopsis:

    $smm->add($key, $value);

The C<$key> must be a 2D-array, with groups in the first
dimension, and items in the second. The granularity of the items controls the matching.

Example:

    my $key   = [['f','o','o'],['b','a','r']];
    my $value = 'Foo Bar';
    $smm->add($key, $value);

=cut

sub add {
    my ($self, $key, $value) = @_;

    my $table = $self->{table};

    foreach my $group (@$key) {
        my $ref = $table;
        foreach my $item (@$group) {
            $ref = $ref->{$item} //= {};
            push @{$ref->{values}}, \$value;
        }
    }

    $self;
}

=head2 search

Synopsis:

    my @matches = $smm->search($pattern, %opt)

Searches and returns a list of matches, each match having a score
greater or equal to 1, which is the number of times it matched the pattern.

Each returned match has the following structure:

    {
        match => $value,
        score => $integer,
    }

Where C<$value> is the original value associated with the matched key.

The C<$pattern> must be a 2D-array, with groups in the first dimension
and items in the second dimension. The granularity of the items controls the matching.

Example:

    my $pattern = [['f','o'], ['b', 'a']];
    my @default = $smm->search($pattern);
    my @best    = $smm->search($pattern, keep => 'best');
    my @any     = $smm->search($pattern, keep => 'any');

The B<keep> option controls which matches to be returned.

=over 2

=item * keep => 'best'

Will filter the results to include only the matches with the highest score.

=item * keep => 'any'

Will keep any partial match, even when a certain group from the C<$pattern> do not match any of the returned matches.

=item * keep => 'default'

This is the default setting and it returns all the values that partially match, at least, one group in the C<$pattern>.

=back

In all cases, a given match is saved even when not all the pattern-items from a certain group match all the key-items of the match.

For example, let's consider:

    my $pattern = [['f', 'o']];
    my $key     = [['f', 'o', 'o']];

In the above scenario, the pattern will match the key, because C<'f'> and C<'o'> from the pattern will follow the path of the key.

However, in the following case:

    my $pattern = [['f', 'o']];
    my $key     = [['foo']];

the pattern will not match the key, because C<'foo'> is not stored on the C<'f'> node.

=cut

sub search {
    my ($self, $pattern, %opt) = @_;

    my $table = $self->{table};
    my $keep = $opt{keep} // '';

    my (@matches, %seen);

    foreach my $group (@$pattern) {

        my $ref = $table;
        foreach my $item (@$group) {
            if (exists $ref->{$item}) {
                $ref = $ref->{$item};
            }
            else {
                $ref = undef;
                last;
            }
        }

        if (defined($ref) and exists($ref->{values})) {
            foreach my $match (@{$ref->{values}}) {
                if (not exists $seen{$match}) {
                    $seen{$match} = 1;
                    push @matches, $match;
                }
                else {
                    ++$seen{$match};
                }
            }
        }
        elsif ($keep ne 'any') {
            @matches = ();
            last;
        }
    }

    if ($keep eq 'best') {
        require List::Util;
        my $max = List::Util::max(values %seen);
        @matches = grep { $seen{$_} == $max } @matches;
    }

    map { ; {match => $$_, score => $seen{$_}} } @matches;
}

=head1 EXAMPLE

This example illustrates how to add some key/value pairs to the table
and how to search the table with a given pattern at a later time:

    use Search::MultiMatch;
    use Data::Dump qw(pp);

    # Creates a SMM object
    my $smm = Search::MultiMatch->new();

    # Create a 2D-array key, by splitting the string
    # into words, then each word into characters.
    sub make_key {
        [map { [split //] } split(' ', lc($_[0]))];
    }

    my @movies = (
                  'My First Lover',
                  'A Lot Like Love',
                  'Funny Games (2007)',
                  'Cinderella Man (2005)',
                  'Pulp Fiction (1994)',
                  'Don\'t Say a Word (2001)',
                  'Secret Window (2004)',
                  'The Lookout (2007)',
                  '88 Minutes (2007)',
                  'The Mothman Prophecies',
                  'Love Actually (2003)',
                  'From Paris with Love (2010)',
                  'P.S. I Love You (2007)',
                 );

    # Add the entries
    foreach my $movie (@movies) {
        $smm->add(make_key($movie), $movie);
    }

    my $pattern = make_key('i love');        # make the search-pattern
    my @matches = $smm->search($pattern);    # search for the pattern

    pp \@matches;                            # dump the results

The results are:

    [
     {match => "P.S. I Love You (2007)",      score => 2},
     {match => "My First Lover",              score => 1},
     {match => "A Lot Like Love",             score => 1},
     {match => "Love Actually (2003)",        score => 1},
     {match => "From Paris with Love (2010)", score => 1},
    ]

=head1 AUTHOR

Daniel Șuteu, C<< <trizenx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/trizen/Search-MultiMatch>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::MultiMatch


You can also look for information at:

=over 4

=item * Github

L<https://github.com/trizen/Search-MultiMatch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-MultiMatch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-MultiMatch>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-MultiMatch/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Daniel Șuteu.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;    # End of Search::MultiMatch

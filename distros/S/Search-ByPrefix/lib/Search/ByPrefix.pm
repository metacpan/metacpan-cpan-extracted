package Search::ByPrefix;

use 5.010;
use strict;
use warnings;

=encoding utf8

=head1 NAME

Search::ByPrefix - An efficient, tree-based, multi-match prefix searcher.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

B<Search::ByPrefix> works by creating an internal table from a list of
key/value pairs, where each key is an array.

Then, this table can be efficiently searched with an array prefix-key,
which finds and returns all the values that have this certain prefix.

    use Search::ByPrefix;
    my $sbp = Search::ByPrefix->new;

    # Add an entry
    $sbp->add($key, $value);                 # where $key is an array

    # Search by a prefix
    my @matches = $sbp->search($prefix);     # where $prefix is an array

=head1 METHODS

=head2 new

Creates and returns a new object.

    my $sbp = Search::ByPrefix->new(%opt);

Where C<%opt> can have the following keys:

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

    $sbp->add($key, $value);

The C<$key> must be an array, where its granularity controls the matching.

    my $key   = ['f','o','o','-','b','a','r'];
    my $value = 'foo-bar';
    $sbp->add($key, $value);

or:

    my $key   = ['my', 'dir', 'path'];
    my $value = 'my/dir/path';
    $sbp->add($key, $value);

=cut

sub add {
    my ($self, $key, $value) = @_;

    my $vref = \$value;
    my $ref  = $self->{table};

    foreach my $item (@$key) {
        $ref = $ref->{$item} //= {};
        push @{$ref->{values}}, $vref;
    }

    $self;
}

=head2 search

    my @matches = $sbp->search($prefix);

Searches and returns a list of values that have a certain prefix,
where each value is the original value associated with the matched key.

The C<$prefix> must be an array, where its granularity controls the matching.

    my $prefix = ['f','o'];
    my @values = $sbp->search($prefix);       # finds: ('foo-bar')

or:

    my $prefix = ['my', 'dir'];
    my @values = $sbp->search($prefix);       # finds: ('my/dir/path')

=cut

sub search {
    my ($self, $prefix) = @_;

    my $ref = $self->{table};

    foreach my $item (@$prefix) {
        if (exists $ref->{$item}) {
            $ref = $ref->{$item};
        }
        else {
            return;
        }
    }

    map { $$_ } @{$ref->{values}};
}

=head1 EXAMPLE

This example illustrates how to add some key/value pairs to the table
and how to search the table with a given prefix:

    use 5.010;
    use Search::ByPrefix;
    my $obj = Search::ByPrefix->new;

    sub make_key {
        [split('/', $_[0])]
    }

    foreach my $dir (
                     qw(
                     /home/user1/tmp/coverage/test
                     /home/user1/tmp/covert/operator
                     /home/user1/tmp/coven/members
                     /home/user2/tmp/coven/members
                     /home/user1/tmp2/coven/members
                     )
      ) {
        $obj->add(make_key($dir), $dir);
    }

    # Finds the directories that have this common path
    say for $obj->search(make_key('/home/user1/tmp'));

The results are:

    "/home/user1/tmp/coverage/test"
    "/home/user1/tmp/covert/operator"
    "/home/user1/tmp/coven/members"

=head1 AUTHOR

Daniel Șuteu, C<< <trizenx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/trizen/Search-ByPrefix>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::ByPrefix


You can also look for information at:

=over 4

=item * Github

L<https://github.com/trizen/Search-ByPrefix>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-ByPrefix>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-ByPrefix>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-ByPrefix/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2017 Daniel Șuteu.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of Search::ByPrefix

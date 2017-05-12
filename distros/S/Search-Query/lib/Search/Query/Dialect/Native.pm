package Search::Query::Dialect::Native;
use Moo;
extends 'Search::Query::Dialect';
use Carp;
use Data::Dump qw( dump );

our $VERSION = '0.307';

=head1 NAME

Search::Query::Dialect::Native - the default query dialect

=head1 SYNOPSIS

 my $query = Search::Query->parser->parse('foo');
 print $query;

=head1 DESCRIPTION

Search::Query::Dialect::Native is the default query dialect for Query
objects returned by a Search::Query::Parser instance.

=head1 METHODS

This class is a subclass of Search::Query::Dialect. Only new or overridden
methods are documented here.

=head2 stringify

Returns the Query object as a normalized string.

=cut

sub stringify {
    my $self      = shift;
    my $tree      = shift || $self;
    my $no_prefix = shift || 0;

    my @q;
    foreach my $prefix ( '+', '', '-' ) {
        next unless exists $tree->{$prefix};
        for my $clause ( @{ $tree->{$prefix} } ) {
            push @q,
                ( $no_prefix ? '' : $prefix )
                . $self->stringify_clause($clause);
        }
    }

    return join " ", @q;
}

=head2 stringify_clause( I<leaf> )

Called by stringify() to handle each Clause in the Query tree.

=cut

sub stringify_clause {
    my $self   = shift;
    my $clause = shift;

    if ( $clause->{op} eq '()' ) {
        if ( $clause->has_children and $clause->has_children == 1 ) {
            return $self->stringify( $clause->{value}, 1 );
        }
        else {
            return "(" . $self->stringify( $clause->{value} ) . ")";
        }
    }

    my $quote     = $clause->quote || "";
    my $value     = $clause->value;
    my $proximity = $clause->proximity || '';
    if ($proximity) {
        $proximity = '~' . $proximity;
    }

    # ranges
    if ( ref $value eq 'ARRAY' ) {
        if ( $value->[0] =~ m/[a-z]/i or $value->[1] =~ m/[a-z]/i ) {
            $value = join( qq/$quote$clause->{op}$quote/,
                ( $value->[0], $value->[1] ) );
        }
        else {
            $value = join( qq/$quote $quote/, $value->[0] .. $value->[1] );
        }
        if ( $clause->{op} eq '!..' ) {
            return join( '',
                ( defined $clause->{field} ? $clause->{field} : "" ),
                '!=', '(', $quote, $value, $quote, ')' );
        }
        elsif ( $clause->{op} eq '..' ) {
            return join( '',
                ( defined $clause->{field} ? $clause->{field} : "" ),
                '=', '(', $quote, $value, $quote, ')' );
        }
    }

    # NULL query
    elsif ( defined $clause->{field} and !defined $value ) {
        return sprintf( "%s %s NULL",
            $clause->{field}, ( $clause->{op} eq '=' ? 'is' : 'is not' ) );
    }
    else {
        return join( '',
            ( defined $clause->{field} ? $clause->{field} : "" ),
            $clause->{op}, $quote, $value, $quote, $proximity );
    }
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-query at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Query>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Query


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Query>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Query>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Query>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Query/>

=back


=head1 ACKNOWLEDGEMENTS

This module started as a fork of Search::QueryParser by
Laurent Dami.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

package Search::Query::Dialect::KSx::WildcardQuery;
use strict;
use warnings;
use base qw( KinoSearch::Search::Query );
use Carp;
use Scalar::Util qw( blessed );
use Search::Query::Dialect::KSx::WildcardCompiler;

our $VERSION = '0.201';

=head1 NAME

Search::Query::Dialect::KSx::WildcardQuery - KinoSearch query extension

=head1 SYNOPSIS

 my $query = Search::Query->parser( dialect => 'KSx' )->parse('foo*');
 my $ks_query = $query->as_ks_query();
 # $ks_query isa WildcardQuery

=head1 DESCRIPTION

Search::Query::Dialect::KSx::WildcardQuery extends the 
KinoSearch::QueryParser syntax
to support wildcards. This code is similar to the sample PrefixQuery
code in the KinoSearch distribution and the KSx::Search::WildCardQuery
module on CPAN.

=head1 METHODS

This class is a subclass of KinoSearch::Search::Query. Only new or overridden
methods are documented here.

=cut

# Inside-out member vars
my %term;
my %field;
my %regex;
my %prefix;
my %suffix;

=head2 new( I<args> )

Create a new WildcardQuery object. I<args> must contain key/value pairs
for C<field> and C<term>.

=cut

sub new {
    my ( $class, %args ) = @_;
    my $term  = delete $args{term};
    my $field = delete $args{field};
    my $self  = $class->SUPER::new(%args);
    confess("'term' param is required")
        unless defined $term;
    confess("Invalid term: '$term'")
        unless $term =~ /[\*\?]/;
    confess("'field' param is required")
        unless defined $field;
    $term{$$self}  = $term;
    $field{$$self} = $field;
    $self->_build_regex($term);
    return $self;
}

sub _build_regex {
    my ( $self, $term ) = @_;
    $term = quotemeta($term);  # turn into a regexp that matches a literal str
    $term =~ s/\\\*/.*/g;          # convert wildcards into regex
    $term =~ s/\\\?/.?/g;          # convert wildcards into regex
    $term =~ s/(?:\.\*){2,}/.*/g;  # eliminate multiple consecutive wild cards
    $term =~ s/(?:\.\?){2,}/.?/g;  # eliminate multiple consecutive wild cards
    $term =~ s/^/^/;    # unless $term =~ s/^\.\*//;    # anchor the regexp to
    $term
        =~ s/\z/\\z/;  # unless $term =~ s/\.\*\z//;    # the ends of the term
    $regex{$$self} = qr/$term/;

    # get the literal prefix of the regexp, if any.
    if ($regex{$$self} =~ m<^
            (?:    # prefix for qr//'s, without allowing /i :
                \(\? ([a-hj-z]*) (?:-[a-z]*)?:
            )?
            (\\[GA]|\^) # anchor
            ([^#\$()*+.?[\]\\^]+) # literal pat (no metachars or comments)
        >x
        )
    {
        {
            my ( $mod, $anchor, $prefix ) = ( $1 || '', $2, $3 );
            $anchor eq '^' and $mod =~ /m/ and last;
            for ($prefix) {
                $mod =~ /x/ and s/\s+//g;
            }
            $prefix{$$self} = $prefix;
        }
    }

    if ( $term =~ m/\.[\?\*](\w+)/ ) {
        my $suffix = $1;
        $suffix{$$self} = $suffix;
    }

}

=head2 get_term

=head2 get_field

Retrieve the value set in new().

=head2 get_regex

Retrieve the qr// object representing I<term>.

=head2 get_prefix

Retrieve the literal string (if any) that precedes the wildcards
in I<term>.

=head2 get_suffix

Retrieve the literal string (if any) that follows the wildcards
in I<term>.

=cut

sub get_term   { my $self = shift; return $term{$$self} }
sub get_field  { my $self = shift; return $field{$$self} }
sub get_regex  { my $self = shift; return $regex{$$self} }
sub get_prefix { my $self = shift; return $prefix{$$self} }
sub get_suffix { my $self = shift; return $suffix{$$self} }

sub DESTROY {
    my $self = shift;
    delete $term{$$self};
    delete $field{$$self};
    delete $prefix{$$self};
    delete $suffix{$$self};
    delete $regex{$$self};
    $self->SUPER::DESTROY;
}

=head2 equals

Returns true (1) if the object represents the same kind of query
clause as another WildcardQuery.

NOTE: Currently a NOTWildcardQuery and a WildcardQuery object will
evaluate as equal if they have the same terma and field. This is a bug.

=cut

sub equals {
    my ( $self, $other ) = @_;
    return 0 unless blessed($other);
    return 0 unless $other->isa("Search::Query::Dialect::KSx::WildcardQuery");
    return 0 unless $field{$$self} eq $field{$$other};
    return 0 unless $term{$$self} eq $term{$$other};
    return 1;
}

=head2 to_string

Returns the query clause the object represents.

=cut

sub to_string {
    my $self = shift;
    return "$field{$$self}:$term{$$self}";
}

=head2 make_compiler

Returns a Search::Query::Dialect::KSx::WildcardCompiler object.

=cut

sub make_compiler {
    my $self = shift;
    my %args = @_;
    $args{parent}  = $self;
    $args{include} = 1;
    return Search::Query::Dialect::KSx::WildcardCompiler->new(%args);
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-query-dialect-ksx at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Query-Dialect-KSx>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Query::Dialect::KSx


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Query-Dialect-KSx>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Query-Dialect-KSx>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Query-Dialect-KSx>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Query-Dialect-KSx/>

=back

=head1 ACKNOWLEDGEMENTS

Based on the sample PrefixQuery code in the KinoSearch distribution.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

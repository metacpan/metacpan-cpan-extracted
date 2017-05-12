package SWISH::Prog::Native::Searcher;
use strict;
use warnings;
use Carp;
use base qw( SWISH::Prog::Searcher );
use SWISH::API::Object;
use SWISH::Prog::Native::InvIndex;
use SWISH::Prog::Native::Result;
use Search::Query;

__PACKAGE__->mk_accessors(qw( swish sao_opts result_class ));

our $VERSION = '0.75';

=head1 NAME

SWISH::Prog::Native::Searcher - wrapper for SWISH::API::Object

=head1 SYNOPSIS

 # see SWISH::Prog::Searcher

=head1 DESCRIPTION

The Native Searcher is a thin wrapper around SWISH::API::Object.

=head1 METHODS

=cut

=head2 init

Instantiates the SWISH::API::Object instance and stores it
in the swish() accessor.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->{swish} = SWISH::API::Object->new(
        indexes => [ map { $_->file } @{ $self->{invindex} } ],
        class => $self->{result_class} || 'SWISH::Prog::Native::Result',
        @{ $self->{sao_opts} || [] }
    );

    # add accessor methods to the Result class
    # to mimic what SWISH::API::Object does.
    my $resclass = $self->{swish}->{class};
    if ( $resclass->can('mk_accessors') ) {
        my @propnames = $self->{swish}->props;
        for my $name (@propnames) {
            if ( !$resclass->can($name) ) {
                $resclass->mk_accessors($name);
            }
        }
    }

    # load meta from the first invindex
    my $invindex = $self->invindex->[0];
    my $config   = $invindex->meta;

    # have to wrap MetaNames check in eval because
    # there may not be any explicitly defined in config.
    my $metanames;
    eval { $metanames = $config->MetaNames; };
    if ( $@ and $@ =~ m/^no such Meta key: MetaNames/ ) {
        $metanames = { swishdefault => {} };
    }
    my $field_names = [ keys %$metanames ];
    my %fieldtypes;
    for my $name (@$field_names) {

        # TODO check PropertyNames for string|int|date
        $fieldtypes{$name} = {};

        if ( exists $metanames->{$name}->{alias_for} ) {
            $fieldtypes{$name}->{alias_for}
                = $metanames->{$name}->{alias_for};
        }
    }

    # TODO could expose 'qp' as param to new().
    $self->{qp} ||= Search::Query::Parser->new(
        dialect          => 'SWISH',
        fields           => \%fieldtypes,
        query_class_opts => {
            default_field => $field_names,
            debug         => $self->debug,
        }
    );

    return $self;
}

=head2 sao_opts( I<array_ref> )

Options to pass to SWISH::API::Object in new().

=head2 result_class( I<class_name> )

Passed to SWISH::API::Object in new().

=head2 swish

The SWISH::API::Object instance.

=head2 search( I<query>, I<opts> )

Calls the query() method on the internal SWISH::API::Object.
Returns a SWISH::API::Object::Results object.

I<opts> is an optional hashref with the following supported
key/values:

=over

=item start

The starting position. Default is 0.

=item max

The ending position. Default is max_hits() as documented
in SWISH::Prog::Searcher.

=item order

Takes a SQL-like sort string in pattern I<field> I<direction>.
See the Swish-e docs for sort string details.

=item limit

Takes an arrayref of arrayrefs. Each child arrayref should
have three values: a field (PropertyName) value, a lower limit
and an upper limit.

=item rank_scheme

Takes an int, C<0> or C<1>. Default is C<1>.

=item default_boolop

The default boolean connector for parsing I<query>. Valid values
are B<AND> and B<OR>. The default is B<AND>.

=back

=cut

my %boolops = (
    'AND' => '+',
    'OR'  => '',
);

sub search {
    my $self        = shift;
    my $query       = shift or croak "query required";
    my $opts        = shift || {};
    my $start       = $opts->{start} || 0;
    my $max         = $opts->{max} || $self->max_hits;
    my $order       = $opts->{order};
    my $limits      = $opts->{limit} || [];
    my $rank_scheme = $opts->{rank_scheme};
    $rank_scheme = 1 unless defined $rank_scheme;
    my $boolop = $opts->{default_boolop} || 'AND';

    if ( !exists $boolops{ uc($boolop) } ) {
        croak "Unsupported default_boolop: $boolop (should be AND or OR)";
    }
    $self->{qp}->default_boolop( $boolops{$boolop} );
    my $parsed_query = $self->{qp}->parse($query)
        or croak "Query syntax error: " . $self->{qp}->error;

    my $swishdb = $self->{swish};

    # use idf ranking
    $swishdb->rank_scheme($rank_scheme);
    $swishdb->die_on_error('critical_error');

    my $searcher = $swishdb->new_search_object;

    for my $limit (@$limits) {
        if ( !ref $limit or ref($limit) ne 'ARRAY' or @$limit != 3 ) {
            croak
                "poorly-formed limit ($limit). should be an array ref of 3 values.";
        }
        $searcher->set_search_limit(@$limit);
    }
    if ($order) {
        $searcher->set_sort($order);
        $swishdb->die_on_error;
    }

    my $results = $searcher->execute("$parsed_query");
    $results->{swish_query}
        = join( ' ', $results->parsed_words( $swishdb->indexes->[0] ) );
    $results->{query} = $parsed_query;
    $swishdb->die_on_error;
    $results->seek_result($start);
    return $results;
}

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://swish-e.org/>

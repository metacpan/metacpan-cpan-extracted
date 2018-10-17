package OData::QueryParams::DBIC;

# ABSTRACT: parse OData style query params and provide info for DBIC queries.

use v5.20;

use strict;
use warnings;

use feature 'signatures';
no warnings 'experimental::signatures';

use parent 'Exporter';

use Mojo::URL;

our @EXPORT = qw(params_to_dbic);

our $VERSION = '0.01';

sub params_to_dbic ( $query_string ) {
    my $query  = Mojo::URL->new->query( $query_string );
    my $params = $query->query->to_hash;

    my %opts;
    for my $param_key ( keys %{ $params || {} } ) {
        my $sub = __PACKAGE__->can( '_parse_' . $param_key );
        if ( $sub ) {
            my %key_opts = $sub->( $params->{$param_key} );
            %opts = (%opts, %key_opts);
        }
    }

    return \%opts;
}

sub _parse_top ( $top_data ) {
    return if $top_data !~ m{\A[0-9]+\z};
    return ( rows => $top_data );
}

sub _parse_skip ( $skip_data ) {
    return if $skip_data !~ m{\A[0-9]+\z};
    return ( page => $skip_data + 1 );
}

sub _parse_filter ( $filter_data ) {
    use Data::Dumper;
    print STDERR Dumper( $filter_data );
}

sub _parse_orderby ( $orderby_data ) {
    my @order_bys = split /\s*,\s*/, $orderby_data;

    my @dbic_order_by;

    for my $order_by ( @order_bys ) {
        my $direction;
        $order_by =~ s{\s+((?:de|a)sc)\z}{$1 && ( $direction = $1 ); ''}e;

        $direction //= 'asc';

        push @dbic_order_by, { -$direction => $order_by };
    }

    return order_by => \@dbic_order_by;
}

sub _parse_select ( $select_data ) {
    return columns => [ split /\s*,\s*/, $select_data ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OData::QueryParams::DBIC - parse OData style query params and provide info for DBIC queries.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use OData::QueryParams::DBIC;
    
    my $query_string = 'orderby=username asc, userid';
    my $opts         = params_to_dbic( $query_string );
    
    # { order_by => [ {-asc => 'username'}, {-asc => 'userid'} ] }
    # can be used in
    # $schema->resultset('users')->search( undef, $opts );

=head1 DESCRIPTION

The L<OData|https://www.odata.org> protocol defines the behaviour of
L<Query String Options|https://www.odata.org/documentation/odata-version-2-0/uri-conventions/#QueryStringOptions>.
This module aims to help you when you want to use the OData query string options with an application
that uses L<DBIx::Class|https://metacpan.org/pod/DBIx::Class>.

It parses the query parameters and creates a hash of DBIx::Class options that can be used
in the I<search> method.

=head1 EXPORTED FUNCTION

=head2 params_to_dbic

This function returns a hash reference of options that can be used as options for the I<search> method in
DBIx::Class.

    use OData::QueryParams::DBIC;
    
    my $query_string = 'orderby=username asc, userid';
    my $opts         = params_to_dbic( $query_string );

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

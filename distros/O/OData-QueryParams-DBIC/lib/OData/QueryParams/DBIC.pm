package OData::QueryParams::DBIC;

# ABSTRACT: parse OData style query params and provide info for DBIC queries.

use v5.20;

use strict;
use warnings;

use feature 'signatures';
no warnings 'experimental::signatures';

use parent 'Exporter';

use Carp qw(croak);
use Mojo::Parameters;
use OData::QueryParams::DBIC::FilterUtils qw(parser);
use List::Util qw(any);
use Scalar::Util qw(blessed);

our @EXPORT = qw(params_to_dbic);

our $VERSION = '0.03';

sub params_to_dbic ( $query_string, %opts ) {
    my $query;

    if ( blessed $query_string ) {
        if ( $query_string->isa('Mojo::Parameters') ) {
            $query = $query_string
        }
        else {
            croak 'Invalid object';
        }
    }
    else {
        $query = Mojo::Parameters->new( $query_string );
    }

    my $params = $query->to_hash || {};

    my $filter_key = $opts{strict} ? '$filter' : 'filter';
    my %filter = _parse_filter( delete $params->{$filter_key} );

    my %dbic_opts;
    for my $param_key ( keys %{ $params || {} } ) {
        $param_key =~ s{\A\$}{} if !$opts{strict};

        my $sub = __PACKAGE__->can( '_parse_' . $param_key );
        if ( $sub ) {
            my %key_opts = $sub->( $params->{$param_key} );
            %dbic_opts = (%dbic_opts, %key_opts);
        }
    }

    return \%filter, \%dbic_opts;
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
    return if !defined $filter_data;
    return if $filter_data eq '';

    my $obj    = parser->( $filter_data );
    my %filter = _flatten_filter( $obj );

    return %filter;
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

sub _flatten_filter ($obj) {
    my %map = (
        'lt'  => '<',
        'le'  => '<=',
        'gt'  => '>',
        'ge'  => '>=',
        'eq'  => '==',
        'ne'  => '!=',
        'and' => \&_build_bool,
        'or'  => \&_build_bool,
    );

    my $op = $obj->{operator};

    croak 'Unknown op' if !defined $op;

    my %filter;

    if ( !exists $map{$op} ) {
        croak 'Unsupported op: ' . $op;
    }
    else {
        my $rule    = $map{$op};
        my $subject = $obj->{subject};
        my $value   = $obj->{value};

        if ( !defined $subject ) {
            croak 'Unsupported expression';
        }
        elsif ( ref $rule ) {
            my ($filter_key, $filter_value) = $rule->($obj);
            $filter{$filter_key}            = $filter_value;
        }
        else {
            if ( ref $subject ) {
                croak 'Complex expressions on the left side are not supported (yet)';
            }

            if ( $value =~ m{\A'(.*)'\z} ) {
                $value = $1;
            }

            $subject =~ s{\A\w+\K/}{.};

            $filter{ $subject } = {
                $rule => $value,
            };
        }
    }

    return %filter;
}

sub _build_bool ($obj ) {
    my $op      = $obj->{operator};
    my $subject = $obj->{subject};
    my $value   = $obj->{value};

    return "-$op" => [
        { _flatten_filter( $subject ) },
        { _flatten_filter( $value ) },
    ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OData::QueryParams::DBIC - parse OData style query params and provide info for DBIC queries.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use OData::QueryParams::DBIC;
    
    my $query_string  = 'orderby=username asc, userid';
    my ($where,$opts) = params_to_dbic( $query_string );
    
    # $where = {}
    # $opts  = { order_by => [ {-asc => 'username'}, {-asc => 'userid'} ] }
    # can be used in
    # $schema->resultset('users')->search( $where, $opts );

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
    
    my $query_string  = 'orderby=username asc, userid';
    my ($where,$opts) = params_to_dbic( $query_string );

More examples:

    my $query_string  = 'filter=Price eq 5&orderby=username asc, userid';
    my ($where,$opts) = params_to_dbic( $query_string );
    
    # $where = { Price => 5 }
    # $opts  = { order_by => [ {-asc => 'username'}, {-asc => 'userid'} ] }

    my $query_string  = 'select=Price&orderby=username asc, userid';
    my ($where,$opts) = params_to_dbic( $query_string );
    
    # $where = {}
    # $opts  = { columns => ['Price'], order_by => [ {-asc => 'username'}, {-asc => 'userid'} ] }

    my $query_string  = 'orderby=username asc, userid';
    my ($where,$opts) = params_to_dbic( $query_string );
    
    # $where = {}
    # $opts  = { order_by => [ {-asc => 'username'}, {-asc => 'userid'} ] }

=head1 SUPPORTED QUERY PARAMS

=head2 filter

This lists the top I<number> of entries.

    my $query_string   = 'filter=Price le 100';
    my ($where, $opts) = paras_to_dbic( $query_string );
    
    # $where = { Price => { '<=' => 100 } }

Currently only simple filters are supported:

    "filter=Price le 3.5 or Price gt 200"
        => { -or => [ { Price => { '<=' => 3.5 } }, { Price => { '>' => 200 } } ] } },
    
    "filter=Price le 200 and Price gt 3.5"
        => { -and => [ { Price => { '<=' => 200 } }, { Price => { '>' => 3.5 } } ] },
    
    "filter=Price le 100"
        => { Price => { '<=' => 100 } },
    
    "filter=Price lt 20"
        => { Price => { '<' => 20 } },
    
    "filter=Price ge 10"
        => { Price => { '>=' => 10 } },
    
    "filter=Price gt 20"
        => { Price => { '>' => 20 } },
    
    "filter=Address/City ne 'London'"
        => { 'Address.City' => { '!=' => 'London' } },
    
    "filter=Address/City eq 'Redmond'"
        => { 'Address.City' => 'Redmond' },

=head2 orderby

This orders the list of entries by the given column.

A simple query string:

    my $query_string = 'orderby=username';
    my $opts = paras_to_dbic( $query_string );
    
    # $opts = { order_by => [ {-asc => 'username'} ] };

A more complex one:

    my $query_string = 'orderby=username asc, userid asc';
    my $opts = paras_to_dbic( $query_string );
    
    # $opts = { order_by => [ {-asc => 'username'}, {-asc => 'userid'} ] };

=head2 skip

In combination with C<top>, this can be used for pageination.

    my $query_string = 'skip=5';
    my $opts = paras_to_dbic( $query_string );
    
    # $opts = { page => 5 }

=head2 top

This lists the top I<number> of entries.

    my $query_string = 'top=5';
    my $opts = paras_to_dbic( $query_string );
    
    # $opts = { rows => 5 }

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

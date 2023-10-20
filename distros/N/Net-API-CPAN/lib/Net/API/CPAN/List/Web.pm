##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/List/Web.pm
## Version v0.1.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/09/23
## Modified 2023/09/23
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::CPAN::List::Web;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::CPAN::List );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    # We capture the options passed, and we remove 'hits' that is treated specially
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{data} = { hits => delete( $opts->{hits} ) };
    $self->{container} = 'hits';
    # The elements will be instantiated as Net::API::CPAN::List::Web::Element objects
    $self->{type} = 'Net::API::CPAN::List::Web::Element';
    $self->{_init_strict_use_sub} = 1;
    # We want the property 'total' to be processed first, so it can be overriden if necessary
    $self->{_init_params_order} = [qw( distribution total data )];
    $self->SUPER::init( %$opts) || return( $self->pass_error );
    $self->message( 4, "Instantiating ", ref( $self ), " object for distribution '", $opts->{distribution}, "' with total ", $self->total );
    return( $self );
}

sub load_data
{
    my $self = shift( @_ );
    my $data = CORE::shift( @_ ) ||
        return( $self->error( "No data was provided to load." ) );
    return( $self->error( "Data provided is not an hash reference." ) ) if( ref( $data ) ne 'HASH' );
    if( !exists( $data->{hits} ) )
    {
        return( $self->error( "No property 'hits' in the data provided." ) );
    }
    $self->message( 4, "Loading data received with ", scalar( keys( %$data ) ), " properties: ", join( ', ', sort( keys( %$data ) ) ) );
    $self->distribution( $data->{hits}->[0]->{distribution} ) if( !$self->distribution );
    $self->SUPER::load_data( $data ) || return( $self->pass_error );
    # We cannot trust the property 'total' unfortunately
    $self->message( 4, "Setting total to '", $self->items->length, "'" );
    $self->total( $self->items->length );
    return( $self );
}

sub distribution { return( shift->_set_get_scalar_as_object( 'distribution', @_ ) ); }

# NOTE: Net::API::CPAN::List::Web::Element class
package
    Net::API::CPAN::List::Web::Element;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::CPAN::Module );
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{favorites} = undef unless( exists( $self->{favorites} ) );
    $self->{score} = undef unless( exists( $self->{score} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw(
        abstract author authorized date description distribution documentation favorites
        id indexed path pod_lines release score status
    )];
    return( $self );
}

sub favorites { return( shift->_set_get_number( { field => 'favorites', undef_ok => 1 }, @_ ) ); }

sub score { return( shift->_set_get_number( { field => 'score', undef_ok => 1 }, @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::List::Web - Web Search Result List Object Class

=head1 SYNOPSIS

    use Net::API::CPAN::List::Web;
    my $list = Net::API::CPAN::List::Web->new(
        {
            distribution => "Folklore-Japan",
            hits => [
                {
                    abstract => "Japan Folklore Object Class",
                    author => "MOMOTARO",
                    authorized => 1,
                    date => "2023-07-17T09:43:41",
                    description => "Folklore::Japan is a totally fictious perl 5 module designed to serve as an example for the MetaCPAN API.",
                    distribution => "Folklore-Japan",
                    documentation => "Folklore::Japan",
                    favorites => 1,
                    id => "abcd1234edfgh56789",
                    indexed => 1,
                    module => [
                        {
                            associated_pod => "MOMOTARO/Folklore-Japan-v0.1.0/lib/Folklore/Japan.pm",
                            authorized => 1,
                            indexed => 1,
                            name => "Folklore::Japan",
                            version => 'v0.1.0',,
                            version_numified => 0.001000,
                        },
                    ],
                    path => "lib/Folklore/Japan.pm",
                    pod_lines => [12, 320],
                    release => "Folklore-Japan-v0.1.0",
                    score => 0.031563006,
                    status => "latest",
                },
            ],
            total => 1,
        }
    ) || die( Net::API::CPAN::List::Web->error );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This object class is used to represent web search result. It inherits from L<Net::API::CPAN::List>, because this result set is basically a result set within a result set.

This class object type C<list_web> is used when instantiating a new L<Net::API::CPAN::List> object, so that each of the data array elements are instantiated as an object of this class.

So the overall structure would look like this:

    Net::API::CPAN::List object = [
        Net::API::CPAN::List::Web object,
        Net::API::CPAN::List::Web object,
        Net::API::CPAN::List::Web object,
        # etc..
    ]

=head1 METHODS

For all other methods, please refer to this class parent L<Net::API::CPAN::List>

=head2 distribution

String. This represents the distribution name for this sub-result set.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Net::API::CPAN::List>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

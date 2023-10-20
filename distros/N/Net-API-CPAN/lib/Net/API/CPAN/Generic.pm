##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Generic.pm
## Version v0.1.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/07/26
## Modified 2023/07/26
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::CPAN::Generic;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{api} = undef unless( CORE::exists( $self->{api} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub api { return( shift->_set_get_object( 'api', 'Net::API::CPAN', @_ ) ); }

sub apply
{
    my $self = shift( @_ );
    my $hash = $self->_get_args_as_hash( @_ );
    return( $self ) if( !scalar( keys( %$hash ) ) );
    if( CORE::exists( $self->{_init_preprocess} ) &&
        ref( $self->{_init_preprocess} ) eq 'CODE' )
    {
        $hash = $self->{_init_preprocess}->( $hash );
    }
    
    foreach my $k ( keys( %$hash ) )
    {
        my $code;
        # if( !CORE::exists( $dict->{ $k } ) )
        if( !( $code = $self->can( $k ) ) )
        {
            warn( "No method \"$k\" found in class ", ( ref( $self ) || $self ), " when applying data to this object. Skipping it." ) if( $self->_is_warnings_enabled );
            next;
        }
        $code->( $self, $hash->{ $k } );
    }
    return( $self );
}

# sub as_hash
# {
#     my $self = shift( @_ );
#     my $hash = {};
#     my $fields;
#     if( !$self->can( 'fields' ) )
#     {
#         warn( "Method fields is not implemented in this class '", ( ref( $self ) || $self ), "'." );
#         $fields = $self->new_array( [grep( !/^(_|debug|verbose|error|version)/, keys( %$self ) )] );
#     }
#     else
#     {
#         $fields = $self->fields;
#     }
#     $self->fields->foreach(sub
#     {
#         $hash->{ $_ } = $self->$_();
#     });
#     return( $hash );
# }

sub fields { return( shift->_set_get_array_as_object( 'fields', @_ ) ); }

# Takes an hash of data retrieved from the remote REST API, and fill all the class properties with it
sub populate
{
    my $self = shift( @_ );
    my $ref  = shift( @_ ) || return( $self->error( "No hash to populate was provided." ) );
    return( $self->error( "Hash provided is not an hash reference." ) ) if( ref( $ref ) ne 'HASH' );

    if( CORE::exists( $self->{_init_preprocess} ) &&
        ref( $self->{_init_preprocess} ) eq 'CODE' )
    {
        $ref = $self->{_init_preprocess}->( $ref );
    }
    
    my $keys;
    my $dubious = 0;
    if( scalar( @_ ) == 1 && $self->_is_array( $_[0] ) )
    {
        $dubious++;
        $keys = $self->new_array( @{$_[0]} );
    }
    elsif( $self->can( 'fields' ) )
    {
        $keys = $self->fields->clone;
    }
    else
    {
        $dubious++;
        $keys = [keys( %$ref )];
    }
    
    foreach my $this ( @$keys )
    {
        my $meth = $this;
        $meth =~ tr/-/_/;
        if( $dubious && !$self->can( $meth ) )
        {
            warn( "No method found for \"$meth\" in class ", ( ref( $self ) || $self ), " when populating data. Skipping it." );
            next;
        }
        $self->$meth( $ref->{ $this } );
    }
    return( $self );
}

sub _object_type_to_class { return( shift->api->_object_type_to_class( @_ ) ); }

sub TO_JSON
{
    my $self = shift( @_ );
    my $hash = {};
    if( $self->can( 'fields' ) )
    {
        my $keys = $self->fields;
        foreach my $f ( @$keys )
        {
            $hash->{ $f } = $self->$f();
        }
    }
    else
    {
        # my $hash = $self->as_hash;
        # return( $hash );
        my $class = ref( $self );
        no strict 'refs';
        my @methods = grep( !/^(?:new|init|TO_JSON|FREEZE|THAW|AUTOLOAD|DESTROY)$/, grep{ defined &{"${class}::$_"} } keys( %{"${class}::"} ) );
        foreach my $meth ( sort( @methods ) )
        {
            next if( substr( $meth, 0, 1 ) eq '_' );
            local $@;
            my $rv = eval{ $self->$meth };
            if( $@ )
            {
                warn( "An error occured while accessing method $meth: $@\n" );
                next;
            }
            $hash->{ $meth } = $rv;
        }
    }
    return( $hash );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Generic - Meta CPAN API Generic Class

=head1 SYNOPSIS

    use Net::API::CPAN::Generic;
    package Net::API::CPAN::Author;
    use parent qw( Net::API::CPAN::Generic );
    # ...

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

C<Net::API::CPAN::Generic> contains some standard methods to inherit from.

=head1 METHODS

=head2 init

Initialise some default properties and return the current object.

This C<init> method is called by L<Module::Generic/new>

=head2 api

Sets or gets the C<Net::API::CPAN> API object.

In scalar context, this would return C<undef> if none is defined yet, but in object context, this would automatically instantiate a new C<Net::API::CPAN> object. For example:

    my $api = $obj->api; # undef
    my $resp = $api->ua->get( $somewhere ); # HTTP::Promise::Response

=head2 apply

    $obj->apply( key1 => $val1, key2 => $val2 );
    $obj->apply({ key1 => $val1, key2 => $val2 });

This takes an hash or an hash reference of key-value pairs, and this will call the corresponding method if they exist in the object class, and set the associated value.

It returns the current object.

=head2 as_hash

    my $hash_ref = $obj->as_hash;

This returns an hash reference of key-value pairs corresponding to all the object class methods.

=head2 fields

Sets or gets an L<array object|Module::Generic::Array> of the package methods.

=head2 populate

This is a variation of L<apply|/apply>. It takes an hash reference, and an optional array reference of associated properties to set their values. If no array reference is specified, it will use the object C<fields> methods to get the object class known properties if the C<fields> method is supported, otherwise, it will use all they hash reference keys as a default array reference of properties to set.

It returns the current object upon success, or, upon error, sets an L<error|Net::API::CPAN::Exception> and returns C<undef> in scalar context, or an empty list in list context.

=for Pod::Coverage _object_type_to_class

=head1 ERRORS

This module does not die or croak, but instead set an L<error object|Net::API::CPAN::Exception> using L<Module::Generic/error> and returns C<undef> in scalar context, or an empty list in list context.

You can retrieve the latest error object set by calling L<error|Module::Generic/error> inherited from L<Module::Generic>

Errors issued by this distributions are all instances of class L<Net::API::CPAN::Exception>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

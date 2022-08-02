##----------------------------------------------------------------------------
## Storable Improved with Bug Fixes - ~/lib/Storable/Improved.pm
## Version v0.1.3
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/07/23
## Modified 2022/07/25
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Storable::Improved;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use Storable ();
    use parent -norequire, qw( Storable );
    use vars qw(
        $VERSION @EXPORT_OK @EXPORT @CARP_NOT
        $accept_future_minor $canonical $flags $downgrade_restricted $forgive_me 
        $recursion_limit $recursion_limit_hash );
    use Scalar::Util ();
    @EXPORT = @Storable::EXPORT;
    @EXPORT_OK = @Storable::EXPORT_OK;
    *accept_future_minor = \$Storable::accept_future_minor;
    *canonical = \$Storable::canonical;
    *downgrade_restricted = \$Storable::downgrade_restricted;
    *drop_utf8 = \$Storable::drop_utf8;
    *flags = \$Storable::flags;
    *forgive_me = \$Storable::forgive_me;
    *recursion_limit = \$Storable::recursion_limit;
    *recursion_limit_hash = \$Storable::recursion_limit_hash;
    *Deparse = \$Storable::Deparse;
    *Eval = \$Storable::Eval;
    *DEBUGME = \$Storable::DEBUGME;
    $VERSION = 'v0.1.3';
};

use strict;
use warnings;

{
    no warnings 'once';
    *CLONE = \&Storable::CLONE;
    *BLESS_OK = \&Storable::BLESS_OK;
    *TIE_OK = \&Storable::TIE_OK;
    *FLAGS_COMPAT = \&Storable::FLAGS_COMPAT;
    *BIN_MAJOR = \&Storable::BIN_MAJOR;
    *BIN_VERSION_NV = \&Storable::BIN_VERSION_NV;
    *BIN_WRITE_MINOR = \&Storable::BIN_WRITE_MINOR;
    *BIN_WRITE_VERSION_NV = \&Storable::BIN_WRITE_VERSION_NV;
    *dclone = \&Storable::dclone;
    *fd_retrieve = \&Storable::fd_retrieve;
    *file_magic = \&Storable::file_magic;
    *is_retrieving = \&Storable::is_retrieving;
    *is_storing = \&Storable::is_storing;
    *last_op_in_netorder = \&Storable::last_op_in_netorder;
    *lock_nstore = \&Storable::lock_nstore;
    *lock_retrieve = \&Storable::lock_retrieve;
    *lock_store = \&Storable::lock_store;
    *mretrieve = \&Storable::mretrieve;
    *nfreeze = \&Storable::nfreeze;
    *nstore = \&Storable::nstore;
    *nstore_fd = \&Storable::nstore_fd;
    *pretrieve = \&Storable::pretrieve;
    *read_magic = \&Storable::read_magic;
    *retrieve = \&Storable::retrieve;
    *retrieve_fd = \&Storable::retrieve_fd;
    *show_file_magic = \&Storable::show_file_magic;
    *stack_depth = \&Storable::stack_depth;
    *stack_depth_hash = \&Storable::stack_depth_hash;
    *store = \&Storable::store;
    *store_fd = \&Storable::store_fd;
    *_freeze = \&Storable::_freeze;
    *_make_re = \&Storable::_make_re;
    *_regexp_pattern = \&Storable::_regexp_pattern;
    *_retrieve = \&Storable::_retrieve;
    *_store = \&Storable::_store;
    *_store_fd = \&Storable::_store_fd;
}

sub freeze
{
    my $obj = shift( @_ );
    if( defined( $obj ) && 
        ref( $obj ) && 
        Scalar::Util::blessed( $obj ) &&
        $obj->can( 'STORABLE_freeze_pre_processing' ) )
    {
        $obj = $obj->STORABLE_freeze_pre_processing;
    }
    return( Storable::freeze( $obj ) );
}

sub thaw
{
    my( $frozen, $flags ) = @_;
    my $obj = Storable::thaw( @_ );
    if( defined( $obj ) && 
        ref( $obj ) &&
        Scalar::Util::blessed( $obj ) &&
        $obj->can( 'STORABLE_thaw_post_processing' ) )
    {
        return( $obj->STORABLE_thaw_post_processing );
    }
    return( $obj );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Storable::Improved - Storable improved with core flaws mitigated

=head1 SYNOPSIS

    use Storable::Improved;
    store \%table, 'file';
    $hashref = retrieve('file');

    use Storable::Improved qw(nstore store_fd nstore_fd freeze thaw dclone);

    # Network order
    nstore \%table, 'file';
    $hashref = retrieve('file');	# There is NO nretrieve()

    # Storing to and retrieving from an already opened file
    store_fd \@array, \*STDOUT;
    nstore_fd \%table, \*STDOUT;
    $aryref = fd_retrieve(\*SOCKET);
    $hashref = fd_retrieve(\*SOCKET);

    # Serializing to memory
    $serialized = freeze \%table;
    %table_clone = %{ thaw($serialized) };

    # Deep (recursive) cloning
    $cloneref = dclone($ref);

    # Advisory locking
    use Storable qw(lock_store lock_nstore lock_retrieve)
    lock_store \%table, 'file';
    lock_nstore \%table, 'file';
    $hashref = lock_retrieve('file');

=head1 VERSION

    v0.1.3

=head1 DESCRIPTION

L<Storable::Improved> is a drop-in replacement for L<Storable>. It is a thin module inheriting from L<Storable> and mitigating some of L<Storable> core flaws that have been pointed out to the development team (See L</"SEE ALSO">), but not addressed mostly due their unwillingness to do so. Hence, this module offers the implementation initially suggested.

As L<Storable> documentation states, "the L<Storable> package brings persistence to your Perl data structures containing C<SCALAR>, C<ARRAY>, C<HASH> or C<REF> objects, i.e. anything that can be conveniently stored to disk and retrieved at a later time."

L<Storable::Improved> provides an opportunity to support C<GLOB>-based objects as well and correct other issues.

What issues does it address?

=over 4

=item 1. Fail processing of GLOB-based objects

L<Storable> would fail. For example:

    use IO::File;
    use Storable ();
    my $io = IO::File->new( __FILE__, 'r' );
    my $serialised = Storable::freeze( $io );

would yield the fatal error:

    Can't store GLOB items

and if you set C<$Storable::forgive_me> to a true value, as pointed out in L<Storable> documentation, this would yield:

    Can't store item GLOB(0x563f92a2cc48)

And if you implemented a C<STORABLE_freeze> in the hope you could return an acceptable value to C<Storable::freeze> upon freezing your glob-object, you are in for a disappointment. L<Storable> would trigger the following fatal error. For example:

    use IO::File;
    use Storable ();
    sub IO::File::STORABLE_freeze {};
    $Storable::forgive_me = 1;
    my $io = IO::File->new( __FILE__, 'r' );
    my $serialised = Storable::freeze( $io );

would yield:

    Unexpected object type (8) in store_hook()

Completely obscure and unhelpful error and undocumented too. Whether C<STORABLE_freeze> returns anything makes no difference.

=item 2. Fail processing of XS module objects

For example:

    use v5.36;
    use strict;
    use warnings;
    use HTTP::XSHeaders;
    use Storable ();

    my $h = HTTP::XSHeaders->new(
        Content_Type => 'text/html; charset=utf8',
    );
    say "Content-Type: ", $h->header( 'Content-Type' );
    say "Serialising.";
    my $serial = Storable::freeze( $h );
    my $h2 = Storable::thaw( $serial );
    say "Is $h2 an object of HTTP::XSHeaders? ", ( $h2->isa( 'HTTP::XSHeaders' ) ? 'yes' : 'no' );
    say "Can $h2 do header? ", ( $h2->can( 'header' ) ? 'yes' : 'no' );
    say "Content-Type: ", $h2->header( 'Content-Type' );
    # Exception occurs here: "hl is not an instance of HTTP::XSHeaders"

would result in a fatal error C<hl is not an instance of HTTP::XSHeaders> even though C<< $h2->isa('HTTP::XSHeaders') >> returns true. This is because the object is created by L<Storable> and not by the XS module and is incompatible. Thus, you would think L<Storable> has successfully deserialised the data when it actually did not.

=item 3. Output from C<STORABLE_thaw> is discarded

For example:

    use v5.36;
    use strict;
    use warnings;
    use HTTP::XSHeaders;
    use Storable ();

    sub HTTP::XSHeaders::STORABLE_freeze
    {
        my( $self, $cloning ) = @_;
        return if( $cloning );
        my $class = ref( $self ) || $self;
        my $h = {};
        my $headers = [];
        my $order = [];
        $self->scan(sub
        {
            my( $f, $val ) = @_;
            if( exists( $h->{ $f } ) )
            {
                $headers->{ $f } = [ $h->{ $f } ] unless( ref( $h->{ $f } ) eq 'ARRAY' );
                push( @{$h->{ $f }}, $val );
            }
            else
            {
                $h->{ $f } = $val;
                push( @$order, $f );
            }
        });
        foreach my $f ( @$order )
        {
            push( @$headers, $f, $h->{ $f } );
        }
        my %hash  = %$self;
        $hash{_headers_to_restore} = $headers;
        return( $class, \%hash );
    }

    sub HTTP::XSHeaders::STORABLE_thaw
    {
        my( $self, undef, $class, $hash ) = @_;
        $class //= ref( $self ) || $self;
        $hash //= {};
        my $headers = ref( $hash->{_headers_to_restore} ) eq 'ARRAY'
            ? delete( $hash->{_headers_to_restore} )
            : [];
        my $new = $class->new( @$headers );
        foreach( keys( %$hash ) )
        {
            $new->{ $_ } = delete( $hash->{ $_ } );
        }
        # Unfortunately, Storable ignores $new !
        # So this would never work...
        return( $new );
    }

    my $h = HTTP::XSHeaders->new(
        Content_Type => 'text/html; charset=utf8',
    );
    say "Content-Type: ", $h->header( 'Content-Type' );
    say "Serialising.";
    my $serial = Storable::freeze( $h );
    my $h2 = Storable::thaw( $serial );
    say "Is $h2 an object of HTTP::XSHeaders? ", ( $h2->isa( 'HTTP::XSHeaders' ) ? 'yes' : 'no' );
    say "Can $h2 do header? ", ( $h2->can( 'header' ) ? 'yes' : 'no' );
    say "Content-Type: ", $h2->header( 'Content-Type' );
    # Exception occurs here: "hl is not an instance of HTTP::XSHeaders"

This would still yield the fatal error: C<hl is not an instance of HTTP::XSHeaders>, and that is because L<Storable> discard the value returned by C<STORABLE_thaw>. If it did accept it, the resulting object would work perfectly. L<CBOR::XS> and L<Sereal::Decoder> do exactly that with the special subroutine C<THAW>, and it works well.

=back

To address those issues, L<Storable::Improved> provides a modified version of L</freeze> and L</thaw> and leaves the rest unchanged. This puts it more in line with other serialisers such as L<CBOR::XS> and L<Sereal>

=head1 CLASS FUNCTIONS

=head2 freeze

Provided with some data to freeze, and this checks whether the data provided is a blessed object, and if it has the method C<STORABLE_freeze_pre_processing>. If it has, it calls it and pass the returned value to C<Storable::freeze>, thus giving you a chance to prepare your module object before it gets serialised.

In most case, this is not needed and whatever your C<STORABLE_freeze> returns, L<Storable> would use. However, in cases where your module produces glob-based objects, C<Storable::freeze> would ignore what C<STORABLE_freeze> produces and trigger an error, rendering it useless. This gives you a chance for those scenario, to prepare your module objects, before they are passed to C<Storable::freeze>

It returns the resulting serialised data created by C<Storable::freeze>

=head2 thaw

=head1 HOOKS

"Any class may define hooks that will be called during the serialization and deserialization process on objects that are instances of that class. Those hooks can redefine the way serialization is performed (and therefore,
how the symmetrical deserialization should be conducted)." (quote from the L<Storable> documentation.)

=head2 C<STORABLE_freeze> I<obj>, I<cloning>

No change. See L<Storable> documentation for more information.

Example:

    sub STORABLE_freeze
    {
        my( $self, $cloning ) = @_;
        return if( $cloning );
        my $class = ref( $self ) || $self;
        my %hash  = %$self;
        return( $class, \%hash );
    }

=head2 C<STORABLE_thaw> I<obj>, I<cloning>, I<serialized>, ...

No change. See L<Storable> documentation for more information.

A word of caution here. What the original L<Storable> documentation does not tell you is that:

=over 4

=item 1. You can only modify the object that is passed by L<Storable>, but L<Storable> disregards any returned value from C<STORABLE_thaw>

=item 2. The object created by L<Storable> is mostly incompatible with XS modules. For example:

    use v5.36;
    use strict;
    use warnings;
    use HTTP::XSHeaders;
    use Storable ();

    my $h = HTTP::XSHeaders->new(
        Content_Type => 'text/html; charset=utf8',
    );
    say "Content-Type: ", $h->header( 'Content-Type' );
    say "Serialising.";
    my $serial = Storable::freeze( $h );
    my $h2 = Storable::thaw( $serial );
    say "Is $h2 an object of HTTP::XSHeaders? ", ( $h2->isa( 'HTTP::XSHeaders' ) ? 'yes' : 'no' );
    say "Can $h2 do header? ", ( $h2->can( 'header' ) ? 'yes' : 'no' );
    say "Content-Type: ", $h2->header( 'Content-Type' );
    # Exception occurs here: "hl is not an instance of HTTP::XSHeaders"

would produce:

    Content-Type: text/html; charset=utf8
    Serialising.
    Is My::Headers=HASH(0x555a5c06f198) an object of HTTP::XSHeaders? yes
    Can My::Headers=HASH(0x555a5c06f198) do header? yes
    hl is not an instance of HTTP::XSHeaders

This is because, although the C<HTTP::XSHeaders> object in this example created by L<Storable> itself, is a blessed reference of L<HTTP::XSHeaders>, that object cannot successfully call its own methods! This is because that object is not a native XS module object. L<Storable> created that replica, but it is not working, and L<Storable> could have taken from the best practices as implemented in the API of L<CBOR::XS> or L<Sereal> by taking and using the return value from L<STORABLE_thaw> like L<CBOR::XS> and L<Sereal> do with the C<THAW> hook, but nope.

It would have made sense, since each module knows better than L<Storable> what needs to be done ultimately to make their object work.

=back

=head2 STORABLE_freeze_pre_processing

B<New>

If the data passed to L</freeze> is a blessed reference and that C<STORABLE_freeze_pre_processing> is implemented in the object's module, this is called by L</freeze> B<before> the object is serialised by L<Storable>, giving it a chance to make it in a way that is acceptable to L<Storable> without dying.

Consider the following:

    use IO::File;
    my $io = IO::File->new( __FILE__, 'r' );
    my $serial = Storable::freeze( $io );

would throw a fatal error that Storable does not accept glob, but if you did:

    use IO::File;
    local $Storable::forgive_me = 1;
    sub IO::File::STORABLE_freeze_pre_processing
    {
        my $self = shift( @_ );
        my $class = ref( $self ) || $self;
        my $args = [ __FILE__, 'r' ];
        # We change the glob object into a regular hash-based one to be Storable-friendly
        my $this = bless( { args => $args, class => $class } => $class );
        return( $this );
    }

    sub IO::File::STORABLE_thaw_post_processing
    {
        my $self = shift( @_ );
        my $args = $self->{args};
        my $class = $self->{class};
        # We restore our glob object. Geez that was hard. Not.
        my $obj = $class->new( @$args );
        return( $obj );
    }
    my $io = IO::File->new( __FILE__, 'r' );
    my $serial = Storable::Improved::freeze( $io );
    my $io2 = Storable::Improved::thaw( $serial );

And here you go, C<$io2> would be equivalent to your initial glob, opened with the same arguments as the first one.

=head2 STORABLE_thaw_post_processing

B<New>

If the data passed to L</freeze> is a blessed reference and that C<STORABLE_thaw_post_processing> is implemented in the object's module, this is called by L</thaw> B<after> L<Storable> has deserialised the data, giving you an opportunity to make final adjustments to make the module object a working one.

Consider the following:

    use HTTP::XSHeaders;
    use Storable::Improved;
    
    sub HTTP::XSHeaders::STORABLE_freeze
    {
        my( $self, $cloning ) = @_;
        return if( $cloning );
        my $class = ref( $self ) || $self;
        my $h = {};
        my $headers = [];
        my $order = [];
        # Get all headers field and values in their original order
        $self->scan(sub
        {
            my( $f, $val ) = @_;
            if( exists( $h->{ $f } ) )
            {
                $h->{ $f } = [ $h->{ $f } ] unless( ref( $h->{ $f } ) eq 'ARRAY' );
                push( @{$h->{ $f }}, $val );
            }
            else
            {
                $h->{ $f } = $val;
                push( @$order, $f );
            }
        });
        foreach my $f ( @$order )
        {
            push( @$headers, $f, $h->{ $f } );
        }
        my %hash  = %$self;
        $hash{_headers_to_restore} = $headers;
        return( $class, \%hash );
    }

    sub HTTP::XSHeaders::STORABLE_thaw
    {
        my( $self, undef, $class, $hash ) = @_;
        $class //= ref( $self ) || $self;
        $hash //= {};
        $hash->{_class} = $class;
        $self->{_deserialisation_params} = $hash;
        # Useles to do more in STORABLE_thaw, because Storable anyway ignores the value returned
        # so we just store our hash of parameters for STORABLE_thaw_post_processing to do its actual job
        return( $self );
    }

    sub HTTP::XSHeaders::STORABLE_thaw_post_processing
    {
        my $obj = shift( @_ );
        my $hash = ( exists( $obj->{_deserialisation_params} ) && ref( $obj->{_deserialisation_params} ) eq 'HASH' )
            ? delete( $obj->{_deserialisation_params} )
            : {};
        my $class = delete( $hash->{_class} ) || ref( $obj ) || $obj;
        my $headers = ref( $hash->{_headers_to_restore} ) eq 'ARRAY'
            ? delete( $hash->{_headers_to_restore} )
            : [];
        my $new = $class->new( @$headers );
        foreach( keys( %$hash ) )
        {
            $new->{ $_ } = delete( $hash->{ $_ } );
        }
        return( $new );
    }

    my $h = HTTP::XSHeaders->new(
        Content_Type => 'text/html; charset=utf8',
    );
    my $serial = Storable::Improved::freeze( $h );
    my $h2 = Storable::Improved::thaw( $serial );
    # $h2 is an instance from HTTP::XSHeaders
    # Calling a method using this XS method object works! Example:
    # $h2->header( 'Content-Type' );
    # produces: 'text/html; charset=utf8'

=head1 SEE ALSO

L<Storable>, L<CBOR::XS>, L<Sereal>

L<Storable issue #19964|https://github.com/Perl/perl5/issues/19964>

L<Storable issue #19984|https://github.com/Perl/perl5/issues/19984>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

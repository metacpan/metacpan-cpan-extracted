##----------------------------------------------------------------------------
## Person Name Format - ~/lib/PersonName/Format/Exception.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/07/17
## Modified 2026/07/17
## All rights reserved
##
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package PersonName::Format::Exception;
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    if( $] < 5.013 )
    {
        no strict 'refs';
        unless( defined( &warnings::register_categories ) )
        {
            *warnings::_mkMask = sub
            {
                my $bit  = shift( @_ );
                my $mask = "";
                vec( $mask, $bit, 1 ) = 1;
                return( $mask );
            };

            *warnings::register_categories = sub
            {
                my @names = @_;
                foreach my $name ( @names )
                {
                    if( !defined( $warnings::Bits{ $name } ) )
                    {
                        $warnings::Offsets{ $name }  = $warnings::LAST_BIT;
                        $warnings::Bits{ $name }     = warnings::_mkMask( $warnings::LAST_BIT++ );
                        $warnings::DeadBits{ $name } = warnings::_mkMask( $warnings::LAST_BIT++ );
                        if( length( $warnings::Bits{ $name } ) > length( $warnings::Bits{all} ) )
                        {
                            $warnings::Bits{all}     .= "\x55";
                            $warnings::DeadBits{all} .= "\xaa";
                        }
                    }
                }
            };
        }
    }
    warnings::register_categories( 'PersonName::Format' );
    use vars qw( $VERSION );
    use overload (
        '""'     => \&as_string,
        bool     => sub{1},
        fallback => 1,
    );
    use Scalar::Util ();
    our( $VERSION ) = 'v0.1.0';
};

use strict;
use warnings;

sub new
{
    my $this  = shift( @_ );
    my $class = ref( $this ) || $this;
    my $self  = bless( {}, $class );
    my @info  = caller;
    @$self{ qw( package file line ) } = @info[0..2];

    if( @_ == 1 && ref( $_[0] ) eq 'HASH' )
    {
        my $args = shift( @_ );
        if( $args->{skip_frames} )
        {
            @info = caller( int( $args->{skip_frames} ) );
            @$self{ qw( package file line ) } = @info[0..2];
        }
        foreach my $key ( qw( package file line message code type retry_after ) )
        {
            if( exists( $args->{ $key } ) )
            {
                $self->{ $key } = $args->{ $key };
            }
        }
        $self->{message} = '' if( !defined( $self->{message} ) );
    }
    elsif( @_ == 1 &&
           Scalar::Util::blessed( $_[0] ) &&
           $_[0]->isa( __PACKAGE__ ) )
    {
        my $exception = shift( @_ );
        foreach my $key ( qw( package file line message code type retry_after ) )
        {
            if( exists( $exception->{ $key } ) )
            {
                $self->{ $key } = $exception->{ $key };
            }
        }
    }
    else
    {
        $self->{message} = join( '', map( ref( $_ ) eq 'CODE' ? $_->() : $_, @_ ) );
    }

    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    if( defined( $self->{_cache_value} ) && !$self->{_reset} )
    {
        return( $self->{_cache_value} );
    }

    my $message = defined( $self->{message} ) ? $self->{message} : '';
    $message = "$message";
    $message =~ s/\r?\n$//g;
    $message .= sprintf(
        " within package %s at line %s in file %s\n",
        defined( $self->{package} ) ? $self->{package} : 'undef',
        defined( $self->{line} ) ? $self->{line} : 'undef',
        defined( $self->{file} ) ? $self->{file} : 'undef',
    );
    $self->{_cache_value} = $message;
    delete( $self->{_reset} );
    return( $message );
}

sub clone
{
    my $self = shift( @_ );
    return( ref( $self )->new( $self ) );
}

sub code        { return( shift->_set_get_property( 'code', @_ ) ); }
sub file        { return( shift->_set_get_property( 'file', @_ ) ); }
sub line        { return( shift->_set_get_property( 'line', @_ ) ); }
sub message     { return( shift->_set_get_property( 'message', @_ ) ); }
sub package     { return( shift->_set_get_property( 'package', @_ ) ); }
sub retry_after { return( shift->_set_get_property( 'retry_after', @_ ) ); }
sub type        { return( shift->_set_get_property( 'type', @_ ) ); }

sub PROPAGATE
{
    my( $self, $file, $line ) = @_;
    return( $self ) if( !defined( $file ) || !defined( $line ) );
    my $clone = $self->clone;
    $clone->file( $file );
    $clone->line( $line );
    return( $clone );
}

sub rethrow
{
    my $self = shift( @_ );
    die( $self );
}

sub throw
{
    my $self = shift( @_ );
    my $exception = @_ ? ref( $self )->new({
        skip_frames => 1,
        message     => join( '', @_ ),
    }) : $self;
    die( $exception );
}

sub _set_get_property
{
    my $self = shift( @_ );
    my $property = shift( @_ );
    die( "No exception property was provided." )
        if( !defined( $property ) || !length( $property ) );
    if( @_ )
    {
        $self->{ $property } = shift( @_ );
        $self->{_reset} = 1;
    }
    return( $self->{ $property } );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

PersonName::Format::Exception - Exception object for PersonName::Format

=head1 SYNOPSIS

    use PersonName::Format;

    # Exceptions are created automatically by the error() method in various modules

    # Exception object propagates through method chains
    # When a method fails, it returns a PersonName::Format::NullObject in chaining
    # (object) context so the chain does not die with "Can't call method on undef":

    # pass_error: forwarding an existing exception
    sub my_helper
    {
        my $self = shift( @_ );
        my $fmt = PersonName::Format->new( $faulty_args ) ||
            return( $self->pass_error );  # re-raise PersonName::Format's error
        return( $fmt );
    }

    my $obj = My::Class->new->my_helper ||
        die( My::Class->error );

    # Fatal mode: turn warnings into exceptions
    my $fmt2 = PersonName::Format->new( $some_args );
    $fmt2->fatal(1);  # any subsequent error will die() instead of warn()

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

C<PersonName::Format::Exception> is a lightweight exception class used internally by L<PersonName::Format>. It is created automatically by the C<error()> method and stored both on the object and in a package-level C<$ERROR> variable.

L<PersonName::Format> never calls C<die> directly (except via C<throw()>). Instead, error conditions set the exception and return C<undef> in scalar context, or an empty list in list context.

=head1 CONSTRUCTOR

=head2 new( %args | $message )

Constructor. Accepts either a plain string message or a hash with the following keys:

=over 4

=item C<message>

The human-readable error message.

=item C<file>

Source file where the error originated (auto-populated if omitted).

=item C<line>

Line number (auto-populated if omitted).

=item C<package>

Package name (auto-populated if omitted).

=item C<skip_frames>

Number of additional call-stack frames to skip when auto-detecting location.

Default: C<0>.

=back

=head1 METHODS

=head2 as_string

Returns the stringified form of the exception, including file and line information. This method is also invoked by the C<""> overload.

=head2 file

Returns the source file associated with the exception.

=head2 line

Returns the line number associated with the exception.

=head2 message

Returns the error message string.

=head2 package

Returns the package name associated with the exception.

=head2 throw( %args | $message )

Creates a new exception object and immediately calls C<die()> with it.

=head1 SEE ALSO

L<PersonName::Format>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

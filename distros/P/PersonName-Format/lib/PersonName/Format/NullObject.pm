##----------------------------------------------------------------------------
## Person Name Format - ~/lib/PersonName/Format/NullObject.pm
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
package PersonName::Format::NullObject;
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
    use overload (
        '""'     => sub{ '' },
        '0+'     => sub{0},
        bool     => sub{0},
        fallback => 1,
    );
    use Wanted;
    our( $VERSION ) = 'v0.1.0';
};

use strict;
use warnings;

our $AUTOLOAD;

sub new
{
    my $this = shift( @_ );
    return( bless( {} => ( ref( $this ) || $this ) ) );
}

sub AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    my $self = shift( @_ );
    if( want( 'OBJECT' ) )
    {
        rreturn( $self );
    }
    # Otherwise, we return undef; Empty return returns undef in scalar context and empty list in list context
    return;
};

sub DESTROY { }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

PersonName::Format::NullObject - Null Value Chaining Object Class

=head1 SYNOPSIS

    # In your code:
    my $fmt = PersonName::Format->new( $faulty_args )->format( ... ) ||
        die( PersonName::Format->error );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Without this mechanism, a failing constructor call in a method chain would set C<$obj> to C<undef> and the subsequent C<< ->format() >> call would immediately die with C<< Can't call method "format" on an undefined value >>. Because L<PersonName::Format/error> returns a L<PersonName::Format::NullObject> object instead of C<undef>, the chain can continue gracefully: any method called on a C<NullObject> returns the object itself in chaining context, C<undef> in scalar context, or an empty list in list context, so the error is surfaced at the end of the chain rather than mid-expression.

L<PersonName::Format::NullObject> uses C<AUTOLOAD> to accept any method call. It retains the original exception within its object so it can be retrieved later.

=head1 METHODS

This module exposes a single public method. C<AUTOLOAD> makes every other method call a no-op that propagates the null state through the chain.

=head2 new

This takes no argument, and returns a new L<PersonName::Format::NullObject> object.

=head2 CREDITS

Based on an original idea from L<Brian D. Foy|https://stackoverflow.com/users/2766176/brian-d-foy> discussed on L<StackOverflow|https://stackoverflow.com/a/7068271/4814971> and also on L<Perl Monks|https://www.perlmonks.org/?node_id=265214>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

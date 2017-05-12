package SWISH::API::Object::Results;
use strict;
use warnings;
use base qw( SWISH::API::More::Results );
use Carp;
use YAML::Syck ();
use JSON::Syck ();

our $VERSION = '0.14';

*next = \&next_result;

sub next_result {
    my $self = shift;
    my $r    = $self->SUPER::next_result(@_);
    if ( $self->base->filter ) {
        my $func = $self->base->filter;
        while ( $r && !&$func( $self->base, $r ) ) {
            $r = $self->SUPER::next_result(@_);
        }
    }
    return undef unless defined $r;
    return $self->_make_object($r);
}

sub _make_object {
    my ( $self, $result ) = @_;
    my $sao   = $self->base;
    my $class = $sao->class;

    my %propvals = ( swish_result => $result );

    for my $p ( $sao->props ) {
        my $m   = $sao->properties->{$p};
        my $v   = $result->property($p);
        my $key = $class->can($m) ? $m : $p;
        $propvals{$key}
            = defined($v)
            ? $self->deserialize( $sao->serial_format, $v )
            : '';

    }

    if ( defined $sao->stash ) {
        $propvals{$_} = $sao->stash->{$_} for keys %{ $sao->stash };
    }

    return $class->new( \%propvals );
}

sub deserialize {
    my $self = shift;
    my $f    = shift;
    my $v    = shift;

    if ( $f eq 'yaml' && $v =~ m/^---/o )    # would substr() be faster?
    {
        my $s;
        eval { $s = YAML::Syck::Load($v); };
        if ($@) {
            croak "$@\ncan't deserialize\n$v";
        }
        return $s;
    }
    elsif ( $f eq 'json' && $v =~ m/^[\{\[\"]/o ) {
        my $s;
        eval { $s = JSON::Syck::Load($v); };
        if ($@) {
            croak "$@\ncan't deserialize\n$v";
        }
        return $s;
    }
    else {
        return $v;
    }
}

1;

__END__

=head1 NAME

SWISH::API::Object::Results - objectify SWISH::API::Results

=head1 SYNOPSIS

  # see  SWISH::API::Object;

=head1 DESCRIPTION

SWISH::API::Object::Results is used internally by SWISH::API::Object.

=head1 REQUIREMENTS

L<SWISH::API::Object>

=head1 METHODS

=head2 next_result

The internal SWISH::API::Object::Results class is used to extend the SWISH::API
next_result() method with a next_result_after() method. See SWISH::API::More for
documentation about how the *_after() methods work.

=head2 next

Aliased to next_result.

=head2 deserialize( I<format>, I<prop_val> )

Called for each property value. The I<format> deserialize() expects is based
on C<serial_format> in SWISH::API::Object->new().


=head1 SEE ALSO

L<SWISH::API>, L<SWISH::API::More>

=head1 AUTHOR

Peter Karman, E<lt>karman@cpan.orgE<gt>

Thanks to L<Atomic Learning|http://www.atomiclearning.com/> for supporting some
of the development of this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

package Perl::Critic::Policy::Bangs::ProhibitRefProtoOrProto;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = '1.14';

sub supported_parameters { return ()                     }
sub default_severity     { return $SEVERITY_HIGH         }
sub default_themes       { return qw( bangs complexity ) }
sub applies_to           { return 'PPI::Token::Word'     }


sub violates {
    my ( $self, $elem, $doc ) = @_;

    return if $elem ne 'ref';
    return if is_method_call($elem);
    return if is_hash_key($elem);
    return if is_subroutine_name($elem);

    my $suspectproto = $elem->snext_sibling();
    if ( $suspectproto && $suspectproto->isa( 'PPI::Token::Symbol' ) ) {
        # $suspectproto is the thing I'm calling ref on. Let's see if there's a || after that.
        if ( $suspectproto->snext_sibling()
                && $suspectproto->snext_sibling->isa( 'PPI::Token::Operator' )
                && $suspectproto->snext_sibling() eq q{||} ) {
            my $or = $suspectproto->snext_sibling;
            # this is where I test to see if the thing after the || is the same as the thing before the ref
            if ( $or->snext_sibling() eq $suspectproto->content() ) {
                # here it looks like we have ref $proto || $proto
                my $desc = q{"ref $proto || $proto" construct found}; ## no critic (RequireInterpolationOfMetachars)
                my $expl = q{Probably cut-and-pasted example code};
                return $self->violation( $desc, $expl, $elem );
            }
        }
    }

    return;
}

1;

__END__
=head1 NAME

Perl::Critic::Policy::Bangs::ProhibitRefProtoOrProto - Create a clone() method if you need copies of objects.

=head1 AFFILIATION

This Policy is part of the L<Perl::Critic::Bangs> distribution.

=head1 DESCRIPTION

Many times you'll see code for object constructors that's been
cut-and-pasted from somewhere else, and it looks like this:

    sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = bless {}, $class;
        ...
    }

The C<$class> is derived from the first parameter, whether it's the
class name, or an existing object.  This lets you do this:

    my $fido = Dog->new();

which is very common, and the less likely

    my $rover = $fido->new();

Now, why would you want to instantiate an object based on the type
of another object?  If you want to make C<$rover> a clone of C<$fido>,
then Dog should have a C<clone()> method, instead of overloading
the meaning of C<new()>.

That's all the C<ref($proto) || $proto> does for you.  If you don't
need that dubious functionality, then write your constructors like
this:

    sub new {
        my $class = shift;
        my $self = bless {}, $class;
    }

See also Randal Schwartz's take on it at
L<http://www.stonehenge.com/merlyn/UnixReview/col52.html>.

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head1 AUTHOR

Andrew Moore <amoore@mooresystems.com>

=head1 ACKNOWLEDGMENTS

Adapted from policies by Jeffrey Ryan Thalhammer <thaljef@cpan.org>,
and work done by Andrew Moore <amoore@mooresystems.com>.

=head1 COPYRIGHT

Copyright (C) 2006-2013 Andy Lester

This library is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut

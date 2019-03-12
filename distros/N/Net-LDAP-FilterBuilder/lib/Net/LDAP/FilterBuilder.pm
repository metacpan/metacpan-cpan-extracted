package Net::LDAP::FilterBuilder;
BEGIN {
  $Net::LDAP::FilterBuilder::VERSION = '1.200002';
}

use strict;
use warnings FATAL => 'all';

use overload '""' => \&as_str;

sub escape {
    my $class = shift;
    my $value = shift;
    for ( $value ) {
        s{\\}{\\}g;
        s{\*}{\\*}g;
        s{\(}{\\(}g;
        s{\)}{\\)}g;
        s{\0}{\\0}g;
    }
    return $value;
}

sub new {
    my $proto = shift;
    my $class = ref( $proto ) || $proto;

    my $filter;

    if ( @_ == 0 ) {
        $filter = '(objectclass=*)';
    }
    elsif ( @_ == 1 ) {
        $filter = shift;
    }
    else {
        my $op = @_ % 2 ? shift : '=';
        my @parts;
        while ( my ( $attr, $val ) = splice( @_, 0, 2 ) ) {
            if ( ref( $val ) eq 'ARRAY' ) {
                push @parts, sprintf( '(|%s)', join( q{}, map $class->new( $op, $attr, $_ ), @{ $val } ) );
            }
            elsif ( ref( $val ) eq 'SCALAR' ) {
                push @parts, sprintf( '(%s%s%s)', $attr, $op, ${ $val } );
            }
            else {
                push @parts, sprintf( '(%s%s%s)', $attr, $op, $class->escape( $val ) );
            }
        }
        if ( @parts > 1 ) {
            $filter = sprintf( '(&%s)', join( q{}, @parts ) );
        }
        else {
            $filter = shift @parts;
        }
    }

    bless( \$filter, $class );
}

sub or {
    my $self = shift;

    ${ $self } = sprintf( '(|%s%s)', $self, $self->new( @_ ) );

    return $self;
}

sub and {
    my $self = shift;

    ${ $self } = sprintf( '(&%s%s)', $self, $self->new( @_ ) );

    return $self;
}

sub not {
    my $self = shift;

    ${ $self } = sprintf( '(!%s)', $self );

    return $self;
}

sub as_str {
    ${ $_[0] };
}

1;

# ABSTRACT: Build LDAP filter statements


__END__
=pod

=head1 NAME

Net::LDAP::FilterBuilder - Build LDAP filter statements

=head1 VERSION

version 1.200002

=head1 SYNOPSIS

 use Net::LDAP::FilterBuilder;

 my $filter1 = Net::LDAP::FilterBuilder->new( sn => 'Jones' );
 # now $filter1 eq '(sn=Jones)'

Basic logic operations such as C<and>, C<or> and C<not>:

 $filter1->and( givenName => 'David' );
 # (&(sn=Jones)(givenName=David))
 
 my $filter2 = Net::LDAP::FilterBuilder->new( sn => [ 'Jones', 'Edwards', 'Lewis' ] );
 # (|(sn=Jones)(sn=Edwards)(sn=Lewis))
 
 my $filter3 = Net::LDAP::FilterBuilder->new( givenName => 'David' )->not;
 # (!(givenName=David))

Build up filters incrementally from other FilterBuidler objects:

 my $filter4 = Net::LDAP::FilterBuilder->new( sn => ['Jones', 'Edwards'] )->and( $filter3 );
 # (&(|(sn=Jones)(sn=Edwards))(!(givenName=David)))

Special characters to LDAP will be escaped:

 my $filter5 = Net::LDAP::FilterBuilder->new( sn => 'foo*bar' );
 # (sn=foo\*bar)

To disable escaping, pass a Scalar reference:

 my $filter6 = Net::LDAP::FilterBuilder->new( sn => \'foo*bar' );
 # (sn=foo*bar)

Alternate operators are available through the three-argument constructor form:

 my $filter7 = Net::LDAP::FilterBuilder->new( '>=', dateOfBirth => '19700101000000Z' );
 # (dateOfBirth>=19700101000000Z)

=head1 DESCRIPTION

This is a convenience module which greatly simplifies the construction of LDAP
query filter statements, which are described in RFC 4515 and also the
L<Net::LDAP::Filter> manual page. 

=head1 PURPOSE

Use this module to construct LDAP filter statements which are compliant with
the RFC 4515 syntax and also safely escape special characters. Filter
statements can be built incrementally using simple logic operations.

=head1 USAGE

To make any filter, call the constructor C<new> with the attribute and value
to match:

 my $filter = Net::LDAP::FilterBuilder->new( sn => 'Jones' );

The value returned is an object, but stringifies to the current query:

 print "success" if $filter eq '(sn=Jones)';
 # prints "success"

However you can refine the filter statement using three additional methods for
the logical operations C<and>, C<or> and C<not>, as shown in the L<"SYNOPSIS">
section, above, and the L<"METHODS"> section below.

There are two ways to refine a filter. Either call the logic method with a new
attribute and value, or call a logic method and pass another
Net::LDAP::FilterBuilder object. These two practices are also shown in the
L<"SYNOPSIS"> section, above.

=head2 Comparison Operators

By default the module uses an equal operator between the attribute and value.
To select an alternate operator, use the three agurment form of the
constructor:

 my $filter = Net::LDAP::FilterBuilder->new( '>=', dateOfBirth => '19700101000000Z' );
 # (dateOfBirth>=19700101000000Z)

Note that this module is not aware of the list of valid operators, it simply
takes the first argument to be the operator, whatever it might be.

=head2 Special Character Escaping

If you happen to include one of the small set of characters which are of
special significance to LDAP filter statements in your value argument, then
those characters will be escaped. The list of characters is:

 ( ) * \ NUL 

To avoid this pass in a scalar reference as the value argument. For example to
enable a wildcard (substring) match on a value:

 my $filter = Net::LDAP::FilterBuilder->new( sn => \'foo*bar' );
 # (sn=foo*bar)

=head1 METHODS

=over 4

=item B<as_str>

Returns the string representation of the LDAP filter.  Note that the
object will stringify to this value in string context, too.

=item B<and>(FILTERSPEC)

Logically conjoins this filter with the one specified by FILTERSPEC.
FILTERSPEC may be a L<Net::LDAP::FilterBuilder> object, or a
hash representation of the filter as taken by L<B<new>>.

Returns the newly-conjoined L<Net::LDAP::FilterBuilder>.

=item B<or>(FILTERSPEC)

Logically disjoins this filter with the one specified by FILTERSPEC.
FILTERSPEC may be a L<Net::LDAP::FilterBuilder> object, or a
hash representation of the filter as taken by L<B<new>>.

Returns the newly-disjoined L<Net::LDAP::FilterBuilder>.

=item B<not>

Logically complements this filter.

Returns the newly-negated L<Net::LDAP::FilterBuilder>.

=back

=head1 MAINTAINER

Oliver Gorwits C<< <oliver.gorwits@oucs.ox.ac.uk> >>

=head1 AUTHOR

Originally written by Ray Miller.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


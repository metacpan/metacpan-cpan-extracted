package Scalar::Util::Reftype;
$Scalar::Util::Reftype::VERSION = '0.46';
use 5.010;
use strict;
use warnings;

use constant RESET_COUNTER  => -1;
# being kept for backwards compatibility, 5.10 and later have it
use constant HAS_FORMAT_REF =>  1;
use constant PRIMITIVES     => qw(
    ARRAY
    CODE
    FORMAT
    GLOB
    HASH
    IO
    LVALUE
    REF
    Regexp
    SCALAR
);
use subs qw(
    blessed
    class
    container
    object
    reftype
    type
);
use overload bool     => '_bool',
             fallback => 1,
            ;
use re           ();
use Scalar::Util ();
use base qw( Exporter );

our @EXPORT    = qw( reftype  );
our @EXPORT_OK = qw( type  HAS_FORMAT_REF );

my $OID;
BEGIN {
    $OID = RESET_COUNTER;
    foreach my $type ( PRIMITIVES ) {
        constant->import( 'TYPE_' . $type,             ++$OID );
        constant->import( 'TYPE_' . $type . '_OBJECT', ++$OID );
    }
}

use constant CONTAINER => ++$OID;
use constant BLESSED   => ++$OID;
use constant OVERRIDE  => ++$OID;
use constant MAXID     =>   $OID;

BEGIN {
    *class  = \*container;
    *type   = \*reftype;
    *object = \*blessed;
    my(@types, @obj_idx);
    no strict 'refs';
    foreach my $sym ( keys %{ __PACKAGE__ . q{::} } ) {
        if ( $sym =~ m{ \A TYPE_ (.+?) \z }xms ) {
            push @types, $1;
            push @obj_idx, $sym;
        }
    }

    foreach my $meth ( @types ) {
        *{ lc $meth } = sub {
            my $self = shift;
            my $id   = 'TYPE_' . $meth;
            return $self->[ $self->$id() ];
        }
    }

    *_dump = sub {
        my $self = shift;
        my %type = map { $self->$_() => $_          } @obj_idx;
        my %val  = map { $type{$_}   => $self->[$_] } 0..$#obj_idx;
        my $max  = ( sort { $b <=> $a } map { length $_ } keys %val)[0];
        my $rm   = 'TYPE_';
        $max -= length $rm;
        for my $name ( sort { lc $a cmp lc $b } keys %val) {
            (my $display = $name) =~ s{ \A $rm }{}xms;
            printf "% ${max}s: %s\n", $display, $val{ $name } ? 'true' : '';
        }
    };
}

sub reftype {
    my @args = @_;
    my $o    = __PACKAGE__->_new;
    return $o->_analyze( @args )
}

sub _new {
    my $class = shift;
    my $self  = [ map { 0 } 0..MAXID ];
    $self->[CONTAINER] = q{};
    bless  $self, $class;
    return $self;
}

sub _analyze {
    my $self  = shift;
    my $thing = shift || return $self;
    my $ref   = CORE::ref($thing) || return $self;

    foreach my $type ( PRIMITIVES ) {
        my $id = $ref eq $type                 ? sprintf( 'TYPE_%s',        $type )
               : $self->_object($thing, $type) ? sprintf( 'TYPE_%s_OBJECT', $type )
               :                                 undef
               ;
        if ( $id ) {
            $self->[ $self->$id() ] = 1 if ! $self->[OVERRIDE];
            # IO refs are always objects
            $self->[TYPE_IO]        = 1 if $id eq 'TYPE_IO_OBJECT';
            $self->[CONTAINER]      = $ref if $self->[BLESSED];
            last;
        }
    }

    return $self;
}

sub container { return shift->[CONTAINER] }
sub blessed   { return shift->[BLESSED]   }

sub _object {
    my($self, $object, $type)= @_;
    my $blessed = Scalar::Util::blessed( $object ) || return;
    my $rt      = Scalar::Util::reftype( $object );

    # new perl (5.24+ ?) messes the detection
    if (   $rt
        && $blessed
        #            new               5.10
        && ( $rt eq 'REGEXP' || $rt eq 'SCALAR')
        && $blessed eq 'Regexp'
    ) {
        return;
    }

    $self->[BLESSED] = 1;

    if ( $rt eq 'IO' ) { # special case: IO
        $self->[TYPE_IO_OBJECT] = 1;
        $self->[TYPE_IO]        = 1;
        $self->[OVERRIDE]       = 1;
        return 1;
    }

    if ( re::is_regexp( $object ) ) { # special case: Regexp
        $self->[TYPE_Regexp_OBJECT] = 1;
        $self->[OVERRIDE]           = 1;
        return 1;
    }

    return if $rt ne $type; #  || ! ( $blessed eq 'IO' && $blessed eq $type );
    return 1;
}

sub _bool {
    require Carp;
    Carp::croak(
         'reftype() objects can not be used in boolean contexts. '
        .'Please call one of the test methods on the return value instead. '
        .'Example: `print 42 if reftype( \$thing )->array;`'
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Scalar::Util::Reftype

=head1 VERSION

version 0.46

=head1 SYNOPSIS

    use Scalar::Util::Reftype;
    
    foo() if reftype( "string" )->hash;   # foo() will never be called
    bar() if reftype( \$var    )->scalar; # bar() will be called
    baz() if reftype( []       )->array;  # baz() will be called
    xyz() if reftype( sub {}   )->array;  # xyz() will never be called
    
    $obj  = bless {}, "Foo";
    my $rt = reftype( $obj );
    $rt->hash;        # false
    $rt->hash_object; # true
    $rt->class;       # "Foo"

=head1 DESCRIPTION

This module is B<DEPRECATED>. Please use L<Ref::Util> instead.

This is an alternate interface to C<Scalar::Util>'s C<reftype> function.
Instead of manual type checking you can just call methods on the result
to see if matches the desired type.

=head1 DEPRECATION NOTICE

This module is B<DEPRECATED>. Please use L<Ref::Util> instead.

=head1 NAME

Scalar::Util::Reftype - Alternate reftype() interface

=head1 FUNCTIONS

=head2 reftype EXPR

Exported by default. C<EXPR> can be any value (even C<undef>).

Returns an object with which you can call various test methods. Unless
specified otherwise, all of the test methods return either zero (false)
or one (true) based on the C<EXPR> you have specified.

Return values of reftype() can not be used in boolean contexts. If you do,
it'll die with a verbose error message.

   my $r = reftype( $foo ) || 'something'; # dies
   bar() if reftype( $foo );               # dies

Always call the test methods on the return value:

   bar() if reftype( $foo )->array;

Or, if you want to have multiple tests, without executing C<reftype> multiple
times:

   my $r = reftype( $foo );
   bar() if $r->array;
   baz() if $r->array_object;
   die "ooooh! scaaaary..." if $r->format_object;

The available test methods are listed below.

=head3 scalar

Tests if C<EXPR> is a SCALAR reference or not.

=head3 array

Tests if C<EXPR> is an ARRAY reference or not.

=head3 hash

Tests if C<EXPR> is a HASH reference or not.

=head3 code

Tests if C<EXPR> is a CODE reference or not.

=head3 glob

Tests if C<EXPR> is a GLOB reference or not.

=head3 lvalue

Tests if C<EXPR> is a LVALUE reference or not.

=head3 format

Tests if C<EXPR> is a FORMAT reference or not.

=head3 ref

Tests if C<EXPR> is a reference to a reference or not.

=head3 io

Tests if C<EXPR> is a IO reference or not.

B<CAVEAT>: C<< reftype(EXPR)->io_object >> is also true since there is no way to
distinguish them (i.e.: IO refs are already implemented as objects).

=head3 regexp

Tests if C<EXPR> is a Regexp reference or not.

=head3 scalar_object

Tests if C<EXPR> is a SCALAR reference based object or not.

=head3 array_object

Tests if C<EXPR> is an ARRAY reference based object or not.

=head3 hash_object

Tests if C<EXPR> is a HASH reference based object or not.

=head3 code_object

Tests if C<EXPR> is a CODE reference based object or not.

=head3 glob_object

Tests if C<EXPR> is a GLOB reference based object or not.

=head3 lvalue_object

Tests if C<EXPR> is a LVALUE reference based object or not.

=head3 format_object

Tests if C<EXPR> is a FORMAT reference based object or not.

=head3 ref_object

Tests if C<EXPR> is a reference to a reference based object or not.

=head3 io_object

Tests if C<EXPR> is a IO reference based object or not.

B<CAVEAT>: C<< reftype(EXPR)->io >> is also true since there is no way to
distinguish them (i.e.: IO refs are already implemented as objects).

=head3 regexp_object

Tests if C<EXPR> is a Regexp reference based object or not.

=head3 class

Returns the name of the class the object based on if C<EXPR> is an object.
Returns an empty string otherwise.

=head1 CAVEATS

=over 4

=item *

perl versions 5.10 and newer includes the function C<re::is_regexp> to detect
if a reference is a regex or not. While it is possible to detect normal regexen
in older perls, there is no simple way to detect C<bless>ed regexen. Blessing
a regex hides it from normal probes. If you are under perl C<5.8.x> or older,
you'll need to install (in fact, it's in the prerequisities list so any
automated tool --like cpan shell-- will install it automatically)
C<Data::Dump::Streamer> which provides the C<regex> function similar to
C<re::is_regexp>.

=item *

IO refs are already implemented as objects, so both C<< reftype(EXPR)->io >>
and C<< reftype(EXPR)->io_object >> will return true if C<EXPR> is either
an IO reference or an IO reference based object.

=item *

C<VSTRING> references are not supported and not implemented.

=item *

C<FORMAT> references can be detected under perl 5.8 and newer. Under older
perls, even the accessors are not defined for C<FORMAT>.

=back

=head1 SEE ALSO

=over 4

=item *

C<reftype> in L<Scalar::Util>

=item *

L<Data::Dump::Streamer>

=item *

L<re>

=item *

L<http://perlmonks.org/?node_id=665339>

=item *

C<t/op/ref.t> in perl source

=item *

C<ref> in L<perlfunc>.

=back

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

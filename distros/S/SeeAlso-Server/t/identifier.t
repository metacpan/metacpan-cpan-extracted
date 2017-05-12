#!perl -Tw

use strict;
use Test::More qw(no_plan);

# TODO: allow URIs in 'value', 'parse', and 'new'

use_ok('SeeAlso::Identifier');

my $id = new SeeAlso::Identifier;
ok( ! $id, 'empty identifier (1)' );
ok( ! $id->valid, 'empty identifier (2)' );
is( $id, '', 'empty identifier (3)' );
is( $id->value, '', 'empty identifier (4)' );
is( $id->canonical, '', 'empty identifier (5)' );
is( $id->hash, '', 'empty identifier (6)' );

$id = SeeAlso::Identifier->new("0");
ok( $id->normalized eq "0" && $id->indexed eq "0" && $id->value eq "0" && $id->valid, "identifier = '0'" );
if ( $id ) { ok(1, "0 is an id"); } else { ok(0, "0 should be an id"); }

$id = SeeAlso::Identifier->new("xy");
is( $id->normalized, "xy", 'normalized()' );
ok( $id, 'bool' );
ok( $id->valid, 'valid()' );
is( $id->canonical, 'xy', 'canonical()' );
is( $id->indexed, 'xy', 'indexed()' );
is( $id->hash, 'xy', 'hash()' );
is( "$id", 'xy', '"" (overload)' );

my $undef;
$id->value( $undef );
is( $id->value, '', 'set to undef' );
$id->value( [1,2,3] ); # will be stringified
like( $id, qr/^ARRAY/, 'set value' );
ok( $id, 'non-string identifier' );

ok( SeeAlso::Identifier->new('A') == SeeAlso::Identifier->new('A'), '== (overload)' );
ok( SeeAlso::Identifier->new('A') eq SeeAlso::Identifier->new('A'), 'eq (overload)' );
ok( SeeAlso::Identifier->new('A') != SeeAlso::Identifier->new('B'), '!= (overload)' );
ok( SeeAlso::Identifier->new('A') ne SeeAlso::Identifier->new('B'), 'ne (overload)' );

is( SeeAlso::Identifier::parse('xyz'), 'xyz', 'parse as function' );
is( SeeAlso::Identifier::parse( undef ), '', 'parse as function (with undef)' );

### Example of a derived class

{
    package GVKPPN;

    use base qw(SeeAlso::Identifier);

    sub parse {
        my $value = shift;
        return $value =~ /^(gvk:ppn:)?([0-9]*[0-9x])$/i ? lc($2) : '';
    }

    sub hash {
        my $self = shift;
        return '' unless $self->valid;
        return substr($self->value,0,length($self->value)-1);
    }

    sub canonical {
        my $self = shift;
        return '' unless $self->valid;
        return 'gvk:ppn:' . $self->value;
    }

    1;
}

my %ppns = (
    'gvk:ppn:355634236' => '355634236', 
    'gvk:PPN:593861493' => '593861493',
    'ppnx' => undef,
);
 
foreach my $s (keys %ppns) {
    my $ppn = GVKPPN->new($s);
    if ( defined $ppns{$s} ) {
        is( $ppn->value, $ppns{$s}, 'derived class' );
        my $v = lc($s); $v =~ s/x/X/;
        is( $ppn->canonical, $v, 'derived class - canonical' );
        $v = substr($ppn->value,0,length($ppn->value)-1);
        is( $ppn->hash, $v, 'derived class - hash' );
    } else {
        is( $ppn, '', 'derived class - value (undef)' );
        is( $ppn->canonical, '', 'derived class - canonical (undef)' );
        is( $ppn->hash, '', 'derived class - hash (undef)');
    }
}


__END__
##### ISSN

package Identifier::ISSN;

urn:issn

sub parse 
is_valid_checksum( $string )

=item indexed 

The form that is used for indexing. This could be '0002936X'
or '0002936' because hyphen and check digit do not contain
information. You could also store the ISSN in the 32 bit
integer number '2996' instead of a string.

### Example: VIAF-ID
package SeeAlso::Identifier::VIAF;

use base qw(SeeAlso::Identifier);

sub parse {
    my $value = shift;
    return '' unless $value =~ /^\s*(http:\/\/viaf.org\/)?([0-9]+)\s*$/;
    return "http://viaf.org/$2";
}

# return local id only
sub hash {
    return $_[0] eq '' ? substr( $_[0], 16 ) : '';
}

    prefix => 'http://viaf.org/'
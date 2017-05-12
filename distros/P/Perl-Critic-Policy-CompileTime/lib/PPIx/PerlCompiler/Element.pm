# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package PPIx::PerlCompiler::Element;

use strict;
use warnings;

BEGIN {
    require PPI::Element;

    push @PPI::Element::ISA, __PACKAGE__;
}

sub non_whitespace_child {
    my ( $self, $index ) = @_;

    my $child;
    my $count = 0;

    foreach my $child ( @{ $self->{'children'} } ) {
        next if $child->isa('PPI::Token::Whitespace');

        if ( $count++ == $index ) {
            return $child;
        }
    }

    return;
}

sub matches {
    my ( $self, $type, $expected ) = @_;

    return 0 unless $self->isa($type);

    if ($expected) {
        my $content = $self->{'content'};

        if ( ref($expected) eq 'Regexp' ) {
            return 0 unless $content =~ $expected;
        }
        else {
            return 0 unless $content eq $expected;
        }
    }

    return 1;
}

sub isa_prerun_block {
    my ($self) = @_;

    return $self->isa('PPI::Statement::Scheduled')
      && $self->non_whitespace_child(0)->matches( 'PPI::Token::Word' => qr/^(BEGIN|UNITCHECK|CHECK)$/ );
}

1;

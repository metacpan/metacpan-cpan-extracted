package Punk::Response;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.20';

1;

__END__

=head1 NAME

Punk::Response - a response builder

=head1 SYNOPSIS

    $c->status(201);
    $c->header('X-Request-Id' => $rid);
    return { id => $id };            # builder state folds into the JSON

    return Punk::Response->new(
        status => 201, body => { id => $id });   # or explicitly

=head1 DESCRIPTION

The mutable half of the response path. Most handlers never touch it -
they return data, a finished triplet, or use the L<Punk::Context>
builders - but C<< $c->res >> gives full control when needed, and a
returned Punk::Response is finalized by the dispatcher.

The object is a plain blessed array with an all-C implementation;
reference bodies JSON-encode through File::Raw::JSON's C ABI at
finalize. Load through L<Punk>, which loads the compiled core first.

=head1 METHODS

=head2 new(%args)

C<status>, C<headers> (arrayref of pairs, kept live), C<body>,
C<type>. Unknown options croak.

=head2 status

=head2 type

=head2 body

Get/set; setters chain.

=head2 header

C<< header(Name => $value) >> appends and chains;
C<< header('Name') >> reads (case-insensitive, first match).

=head2 headers

The live header pair arrayref.

=head2 finalize

The PSGI triplet: a reference body is JSON-encoded
(C<application/json>) through the File::Raw::JSON C ABI, a string is
C<text/html> unless L</type> says otherwise, no body is a
C<text/plain> empty 200; Content-Length always set.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

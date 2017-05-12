#
# This file is part of Net-HTTP-Spore-Middleware-Header
#
# This software is copyright (c) 2014 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Net::HTTP::Spore::Middleware::Header;

# ABSTRACT: Spore Middleware to add header on each request
use strict;
use warnings;
our $VERSION = '0.03';    # VERSION

use Moose;
extends 'Net::HTTP::Spore::Middleware';

has 'header_name'  => ( isa => 'Str', is => 'rw', required => 1 );
has 'header_value' => ( isa => 'Str', is => 'rw', required => 1 );

sub call {
    my ( $self, $req ) = @_;

    return $req->header( $self->header_name, $self->header_value );
}
1;

__END__

=pod

=head1 NAME

Net::HTTP::Spore::Middleware::Header - Spore Middleware to add header on each request

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    my $client = Net::HTTP::Spore->new_from_spec('api.json');
    $client->enable(
        header_name  => 'Content-Type',
        header_value => 'application/json'
    );

=head1 DESCRIPTION

This module is a middleware that add header on each request. You can specify for exemple a Content-Type to pass.

=head1 METHODS

=head2 call

This method will add header_name:header_value in the header of each request

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/Net-HTTP-Spore-Middleware-Header/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

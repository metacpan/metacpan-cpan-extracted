use 5.10.0;
use strict;
use warnings;

package OpenGbg::Service::Bridge::GetIsCurrentlyOpen;

# ABSTRACT: Is the bridge currently open?
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1404';

use XML::Rabbit::Root;
use DateTime::Format::HTTP;
use MooseX::AttributeShortcuts;
use Types::Standard qw/Str Bool/;

has xml => (
    is => 'ro',
    isa => Str,
    required => 1,
);

add_xpath_namespace 'x' => 'TK.DevServer.Services.BridgeService';

has_xpath_value _is_open => '/x:BridgeOpen/x:Value';

has is_open => (
    is => 'ro',
    isa => Bool,
    lazy => 1,
    builder => 1,
);

sub _build_is_open {
    return shift->_is_open eq 'true';
}

finalize_class();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

OpenGbg::Service::Bridge::GetIsCurrentlyOpen - Is the bridge currently open?

=head1 VERSION

Version 0.1404, released 2018-05-19.

=head1 SYNOPSIS

    my $bridge = OpenGbg->new->bridge;
    my $get_ico = $bridge->get_is_currently_open;

    print $get_ico->is_open ? 'It is open' : 'It is closed';

=head1 METHODS

=head2 is_open

Returns a true value if the bridge is open, false if not.

=head1 SOURCE

L<https://github.com/Csson/p5-OpenGbg>

=head1 HOMEPAGE

L<https://metacpan.org/release/OpenGbg>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

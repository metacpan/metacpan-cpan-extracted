package Regru::API::Role::UserAgent;

# ABSTRACT: something that can act as user-agent

use strict;
use warnings;
use Moo::Role;
use LWP::UserAgent;
use Carp;
use namespace::autoclean;

our $VERSION = '0.046'; # VERSION
our $AUTHORITY = 'cpan:IMAGO'; # AUTHORITY

has useragent => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not a LWP::UserAgent instance" unless ref $_[0] eq 'LWP::UserAgent' },
    lazy    => 1,
    default => sub { LWP::UserAgent->new },
);

1;  # End of Regru::API::Role::UserAgent

__END__

=pod

=encoding UTF-8

=head1 NAME

Regru::API::Role::UserAgent - something that can act as user-agent

=head1 VERSION

version 0.046

=head1 SYNOPSIS

    package Regru::API::Client;
    ...
    with 'Regru::API::Role::UserAgent';
    ...
    $resp = $self->useragent->get('http://example.com/');

    if ($resp->is_success) {
        print $resp->decoded_content;
    }
    else {
        die $resp->status_line;
    }

=head1 DESCRIPTION

Any class or role that consumes this one will able to dispatch HTTP requests.

=head1 ATTRIBUTES

=head2 useragent

Returns an L<LWP::UserAgent> instance.

=head1 SEE ALSO

L<Regru::API>

L<Regru::API::Role::Client>

L<LWP::UserAgent>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/regru/regru-api-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Polina Shubina <shubina@reg.ru>

=item *

Anton Gerasimov <a.gerasimov@reg.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by REG.RU LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Net::Google::CivicInformation;

our $VERSION = '1.03';

use strict;
use warnings;
use v5.10;

use Carp 'croak';
use HTTP::Tiny;
use Types::Common::String 'NonEmptyStr';
use Moo;
use namespace::clean;

##
has api_key => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
    default  => sub { $ENV{GOOGLE_API_KEY} },
);

##
has _api_url => (
    is       => 'lazy',
    builder  => sub { croak 'this method must be overriden in a subclass' },
    init_arg => undef,
    coerce   => sub { 'https://www.googleapis.com/civicinfo/v2/' . $_[0] },
);

##
has _client => (
    is       => 'lazy',
    init_arg => undef,
    builder  => sub {
        state $ua = HTTP::Tiny->new;
        return $ua;
    },
);

1; # return true

__END__

=pod

=head1 VERSION

version 1.03

=encoding utf8

=head1 NAME

Net::Google::CivicInformation - client for the Google Civic Information API

=head1 DESCRIPTION

Civic information (elected representatives, their contact information,
jurisdictions, etc) for US addresses, provided via the Google Civic
Information API.

You must obtain an API key (free) from Google to use this package. See
L<https://developers.google.com/civic-information>.

Do not use this module directly. Use one of the subclasses.

=head1 SEE ALSO

L<Net::Google::CivicInformation::Representatives>

=head1 AUTHOR

Nick Tonkin <tonkin@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Nick Tonkin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

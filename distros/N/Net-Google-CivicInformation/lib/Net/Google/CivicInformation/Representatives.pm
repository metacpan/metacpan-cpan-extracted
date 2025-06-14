package Net::Google::CivicInformation::Representatives;

our $VERSION = '1.03';

use strict;
use warnings;
use v5.10;

use Carp 'croak';
use Function::Parameters;
use JSON::MaybeXS;
use Try::Tiny;

use Types::Common::String 'NonEmptyStr';
use Moo;
use namespace::clean;

extends 'Net::Google::CivicInformation';

BEGIN {
    warn 'Net::Google::CivicInformation::Representatives is deprecated (Google terminated the API) and should no longer be used';
}

##
sub _build__api_url {
    return 'representatives';
}

##
method representatives_for_address (NonEmptyStr $address) {
    my $uri = URI->new( $self->_api_url );
    $uri->query_form(
        address => $address,
        key => $self->api_key,
    );

    my $call = $self->_client->get( $uri );

    my $response;
    try {
        if ( ! $call->{success} ) {
            my $resp = decode_json( $call->{content} );
            $response = $resp;
        }
        else {
            my $data = decode_json( $call->{content} );

            my @result;

            my @officials = @{ $data->{officials} };

            for my $job ( @{ $data->{offices} } ) {

                for my $person ( @officials[ @{ $job->{officialIndices} } ] ) {
                    push( @result, {
                        title         => $job->{name},
                        name          => $person->{name},
                        party         => $person->{party},
                        addresses     => $person->{address},
                        phone_numbers => $person->{phones},
                        emails        => $person->{emails},
                        websites      => $person->{urls},
                        social_media  => $person->{channels},
                    });

                }
            }

            $response = { officials => \@result };
        }
    }
    catch {
        $response = {
            error => {
                message => 'Caught fatal error trying to call Google API',
            },
        };
    };

    return $response;
}

1; # return true

__END__

=pod

=head1 VERSION

version 1.03

=encoding utf8

=head1 NAME

DEPRECATED: Net::Google::CivicInformation::Representatives - All elected representatives for US addresses

=head1 DESCRIPTION

  DEPRECATED: In April 2025 Google discontinued the API that this module depended on. 
  The module should no longer be used, and cannot return any data.

=head1 SYNOPSIS

  my $client = Net::Google::CivicInformation::Representatives->new( api_key => '***' );

  my $res = $client->representatives_for_address('123 Main St Springfield MO 12345');

  if ( $res->error ) {
      # handle the error returned (JSON obj, see below)
  }
  else {
      # MORE DOC NEEDED HERE
  }

=head1 METHODS

=over

=item B<representatives_for_address>

Requires an address string as the only argument. Returns an object providing methods
to access the reponse data, or else a method C<error> containing MORE DOC NEEDED HERE.

=head1 AUTHOR

Nick Tonkin <tonkin@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Nick Tonkin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

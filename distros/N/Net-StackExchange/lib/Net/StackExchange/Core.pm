package Net::StackExchange::Core;
BEGIN {
  $Net::StackExchange::Core::VERSION = '0.102740';
}

# ABSTRACT: Subroutines for internal use

use strict;
use warnings;

use JSON;
use LWP::UserAgent;
use Scalar::Util qw{ blessed };
use URI::Escape;

# transform hash keys and corresponding values to query string and return it
sub _get_query_string {
    my $parametres = shift;
    my @query_string;

    while ( my ( $key, $value ) = each %{$parametres} ) {
        $key   = uri_escape($key  );
        $value = uri_escape($value);

        next unless defined $value;

        push @query_string, "$key=$value";
    }

    return join '&', @query_string;
}

# prepare a hash with attributes and their values, and return it
sub _get_parametres {
    my $self       = shift;
    my @attributes = $self->_get_request_attributes();

    my $parametres;
    for my $attribute (@attributes) {
        $parametres->{$attribute} = $self->$attribute();
    }

    return $parametres;
}

sub _execute {
    my $self    = shift;
    my $se      = $self->_NSE();
    my $network = $se->network();
    my $version = $se->version();
    my $id      = $self->id();

    my $route =  blessed($self);
    $route    =~ s/^Net::StackExchange::|::Request$//g;
    $route    =  lc $route;

    my $url = "http://api.$network/$version/$route/$id";

    my $ua           = LWP::UserAgent->new( 'agent' => 'Mozilla' );
    my $parametres   = _get_parametres($self);
    my $query_string = _get_query_string($parametres);
    $url             = "$url?$query_string";
    my $ua_response  = $ua->get($url);

    return $ua_response->decoded_content();
}

1;

__END__
=pod

=head1 NAME

Net::StackExchange::Core - Subroutines for internal use

=head1 VERSION

version 0.102740

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


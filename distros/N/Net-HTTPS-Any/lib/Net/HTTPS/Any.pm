package Net::HTTPS::Any;

use warnings;
use strict;
use base qw( Exporter );
use vars qw( @EXPORT_OK );
use URI::Escape;
use Tie::IxHash;
use Net::SSLeay 1.30, qw( get_https post_https make_headers make_form );

@EXPORT_OK = qw( https_get https_post );

=head1 NAME

Net::HTTPS::Any - Simple HTTPS client

=cut

our $VERSION = '0.12';

=head1 SYNOPSIS

  use Net::HTTPS::Any qw(https_get https_post);
  
  ( $page, $response, %reply_headers )
      = https_get(
                   { 'host' => 'www.fortify.net',
                     'port' => 443,
                     'path' => '/sslcheck.html',
                     'args' => { 'field' => 'value' },
                     #'args' => [ 'field'=>'value' ], #order preserved
                   },
                 );

  ( $page, $response, %reply_headers )
      = https_post(
                    'host' => 'www.google.com',
                    'port' => 443,
                    'path' => '/accounts/ServiceLoginAuth',
                    'args' => { 'field' => 'value' },
                    #'args' => [ 'field'=>'value' ], #order preserved
                  );
  
  #...

=head1 DESCRIPTION

This is a wrapper around Net::SSLeay providing a simple interface for the use
of Business::OnlinePayment.

It used to allow switching between Net::SSLeay and Crypt::SSLeay
implementations, but that was obsoleted.  If you need to do that, use LWP
instead.  You can set $Net::HTTPS::SSL_SOCKET_CLASS = "Net::SSL" for
Crypt::SSLeay instead of the default Net::SSLeay (since 6.02).

=head1 FUNCTIONS

=head2 https_get HASHREF | FIELD => VALUE, ...

Accepts parameters as either a hashref or a list of fields and values.

Parameters are:

=over 4

=item host

=item port

=item path

=item headers (hashref)

For example: { 'X-Header1' => 'value', ... }

=cut

# =item Content-Type
# 
# Defaults to "application/x-www-form-urlencoded" if not specified.

=item args

CGI arguments, either as a hashref or a listref.  In the latter case, ordering
is preserved (see L<Tie::IxHash> to do so when passing a hashref).

=item debug

Set true to enable debugging.

=back

Returns a list consisting of the page content as a string, the HTTP
response code and message (i.e. "200 OK" or "404 Not Found"), and a list of
key/value pairs representing the HTTP response headers.

=cut

sub https_get {
    my $opts = ref($_[0]) ? shift : { @_ }; #hashref or list

    # accept a hashref or a list (keep it ordered)
    my $post_data = {}; # technically get_data, pedant
    if (      exists($opts->{'args'}) && ref($opts->{'args'}) eq 'HASH'  ) {
        $post_data = $opts->{'args'};
    } elsif ( exists($opts->{'args'}) && ref($opts->{'args'}) eq 'ARRAY' ) {
        tie my %hash, 'Tie::IxHash', @{ $opts->{'args'} };
        $post_data = \%hash;
    }

    $opts->{'port'} ||= 443;
    #$opts->{"Content-Type"} ||= "application/x-www-form-urlencoded";

    ### XXX referer!!!
    my %headers = ();
    if ( ref( $opts->{headers} ) eq "HASH" ) {
        %headers = %{ $opts->{headers} };
    }
    $headers{'Host'} ||= $opts->{'host'};

    my $path = $opts->{'path'};
    if ( keys %$post_data ) {
        $path .= '?'
          . join( ';',
            map { uri_escape($_) . '=' . uri_escape( $post_data->{$_} ) }
              keys %$post_data );
    }

    my $headers = make_headers(%headers);

    $Net::SSLeay::trace = $opts->{'debug'}
      if exists $opts->{'debug'} && $opts->{'debug'};

    my( $res_page, $res_code, @res_headers ) =
      get_https( $opts->{'host'},
                 $opts->{'port'},
                 $path,
                 $headers,
                 #"",
                 #$opts->{"Content-Type"},
               );

    $res_code =~ /^(HTTP\S+ )?(.*)/ and $res_code = $2;

    return ( $res_page, $res_code, @res_headers );

}

=head2 https_post HASHREF | FIELD => VALUE, ...

Accepts parameters as either a hashref or a list of fields and values.

Parameters are:

=over 4

=item host

=item port

=item path

=item headers (hashref)

For example: { 'X-Header1' => 'value', ... }

=item Content-Type

Defaults to "application/x-www-form-urlencoded" if not specified.

=item args

CGI arguments, either as a hashref or a listref.  In the latter case, ordering
is preserved (see L<Tie::IxHash> to do so when passing a hashref).

=item content

Raw content (overrides args).  A simple scalar containing the raw content.

=item debug

Set true to enable debugging in the underlying SSL module.

=back

Returns a list consisting of the page content as a string, the HTTP
response code and message (i.e. "200 OK" or "404 Not Found"), and a list of
key/value pairs representing the HTTP response headers.

=cut

sub https_post {
    my $opts = ref($_[0]) ? shift : { @_ }; #hashref or list

    # accept a hashref or a list (keep it ordered).  or a scalar of content.
    my $post_data = '';
    if (      exists($opts->{'args'}) && ref($opts->{'args'}) eq 'HASH'  ) {
        $post_data = $opts->{'args'};
    } elsif ( exists($opts->{'args'}) && ref($opts->{'args'}) eq 'ARRAY' ) {
        tie my %hash, 'Tie::IxHash', @{ $opts->{'args'} };
        $post_data = \%hash;
    }
    if ( exists $opts->{'content'} ) {
        $post_data = $opts->{'content'};
    }

    $opts->{'port'} ||= 443;
    $opts->{"Content-Type"} ||= "application/x-www-form-urlencoded";

    ### XXX referer!!!
    my %headers;
    if ( ref( $opts->{headers} ) eq "HASH" ) {
        %headers = %{ $opts->{headers} };
    }
    $headers{'Host'} ||= $opts->{'host'};

    my $headers = make_headers(%headers);

    $Net::SSLeay::trace = $opts->{'debug'}
      if exists $opts->{'debug'} && $opts->{'debug'};

    my $raw_data = ref($post_data) ? make_form(%$post_data) : $post_data;

    $Net::SSLeay::trace = $opts->{'debug'}
      if exists $opts->{'debug'} && $opts->{'debug'};

    my( $res_page, $res_code, @res_headers ) =
      post_https( $opts->{'host'},
                  $opts->{'port'},
                  $opts->{'path'},
                  $headers,
                  $raw_data,
                  $opts->{"Content-Type"},
                );

    $res_code =~ /^(HTTP\S+ )?(.*)/ and $res_code = $2;

    return ( $res_page, $res_code, @res_headers );

}

=head1 AUTHOR

Ivan Kohler, C<< <ivan-net-https-any at freeside.biz> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-https-any at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-HTTPS-Any>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::HTTPS::Any

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-HTTPS-Any>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-HTTPS-Any>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-HTTPS-Any>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-HTTPS-Any>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008-2016 Freeside Internet Services, Inc. (http://freeside.biz/)
All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

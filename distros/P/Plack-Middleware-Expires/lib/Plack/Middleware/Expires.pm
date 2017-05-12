package Plack::Middleware::Expires;

use strict;
use warnings;
use parent qw/Plack::Middleware/;

use Plack::Util;
use Plack::Util::Accessor qw( content_type expires );
use HTTP::Status qw//;
use HTTP::Date;

our $VERSION = '0.06';

sub calc_expires {
    my ( $expires, $modified, $access ) = @_;
    $access = time if ! defined $access;

    my %term = (
        year => 60*60*24*365,
        month => 60*60*24*31,
        week => 60*60*24*7,
        day => 60*60*24,
        hour => 60*60,
        minute => 60,
        second => 1
    );

    my $expires_sec;
    if ( $expires && $expires =~ m!^(A|M)(\d+)$! ) {
        my $base = ( $1 eq 'M' ) ? $modified : $access;
        return if ! defined $base;
        $expires_sec = $base + $2;
    }
    elsif (  $expires && $expires =~ m!^(access|now|modification)\s(?:plus)\s(.+)$! ) {
        my $base = ( $1 eq 'modification' ) ? $modified : $access;
        return if ! defined $base;
        my @datetime = split /\s+/,$2;
        $expires_sec = $base;
        while ( my ($num, $type) = splice( @datetime, 0, 2) ) {
            my $term_sec;
            (my $sigular_type = lc $type) =~ s/s$//;
            $type = '' if ! defined $type;
            Carp::croak "missing type '$type' in '$expires'" if ! exists $term{$sigular_type};

            if ( $num !~ m!^\d! ) {
                Carp::croak "numeric value expected '$num' in '$expires'";
            }
            no warnings 'numeric';
            $num = int( $num + 0 );		

            $expires_sec += $term{$sigular_type} * $num;
        }
    }
    else {
        Carp::croak("unkown expires format: '$expires'");
    }
    $expires_sec = 2147483647 if $expires_sec > 2147483647; #year 2039
    return $expires_sec;
}

sub prepare_app {
    my $self = shift;
    if ( my $expires = $self->expires ) {
        # test run for configuration check
        calc_expires( $expires, time, time );
    }
}

sub call {
    my($self, $env) = @_;
    my $req_time = time;

    my $res = $self->app->($env);

    $self->response_cb($res, sub {
        my $res = shift;

        return if ! $self->expires;
        my $type_match = $self->content_type;
        return if ! defined $type_match;
        my @type_match = (ref $type_match && ref $type_match eq 'ARRAY') ? @{$type_match} : ($type_match);

        # expires works only for successful response
        return if HTTP::Status::is_error( $res->[0] );

        # if already exists Expires header, do no override
        return if Plack::Util::header_exists($res->[1], 'Expires');

        #content_type check
        my $type = Plack::Util::header_get($res->[1], 'Content-Type');
        return if ! defined $type;
        my $type_check;
        for ( @type_match ) {
            if (my $ref = ref $_) {
                if ($ref eq 'Regexp' && $type =~ m!$_!) {
                    $type_check = 1;
                    last;
                }
                elsif ($ref eq 'CODE') {
                    $type_check = $_->($env);
                    last;
                }
            }
            else {
                if ( lc $type eq lc $_ ) {
                    $type_check = 1;
                    last;
                }
            }
        }
        return if ! $type_check;

        my $last_modified;
        if ( $last_modified = Plack::Util::header_get($res->[1], 'Last-Modified') ) {
            $last_modified = HTTP::Date::str2time( $last_modified );
        }
        
        # calurate
        my $expires_sec = calc_expires( $self->expires, $last_modified, $req_time );
        Plack::Util::header_set( $res->[1], 'Expires', HTTP::Date::time2str( $expires_sec ) );
        if ( my $cc = Plack::Util::header_get($res->[1], 'Cache-Control') ) {
            $cc .= sprintf "max-age=%d", $expires_sec - $req_time; 
        }
        else {
            Plack::Util::header_set( $res->[1], 'Cache-Control', sprintf("max-age=%d", $expires_sec - $req_time) );
        }
    });

}


1;
__END__

=head1 NAME

Plack::Middleware::Expires - mod_expires for plack

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
      enable 'Expires',
        content_type => qr!^image/!i,
        expires => 'access plus 3 months';
      $app;
  }


=head1 DESCRIPTION

Plack::Middleware::Expires is Apache's mod_expires for Plack.
This middleware controls the setting of Expires HTTP header and the max-age directive of the Cache-Control HTTP header in server responses.

B<Note>:

=over

=item * Expires works only for successful response,

=item * If an Expires HTTP header exists already, it will not be overridden by this middleware.

=back

=head1 CONFIGURATIONS

=over 4

=item content_type

  content_type => qr!^image!,
  content_type => 'text/css',
  content_type => [ 'text/css', 'application/javascript', qr!^image/! ]

Content-Type header to apply Expires

also C<content_type> accept CodeRef

  content_type => sub { my $env = shift; return 1 if $env->{..} }


=item Expires

Same format as the Apache mod_expires

  expires => 'M3600' # last_modified + 1 hour
  expires => 'A86400' # access + 1 day
  expires => 'modification plus 3 years 3 month 3 day'
  expires => 'access plus 3 days'

=back

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

L<http://httpd.apache.org/docs/2.2/en/mod/mod_expires.html>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

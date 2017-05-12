package Plack::Builder::Conditionals;

use strict;
use warnings;
use Net::CIDR::Lite;
use List::MoreUtils qw//;
use Plack::Util;
use Plack::Middleware::Conditional;

our $VERSION = '0.05';

sub import {
    my $class = shift;
    my $caller = caller;
    my %args = @_;

    my @EXPORT = qw/match_if addr path method header browser any all/;

    no strict 'refs';
    my $i=0;
    for my $sub (@EXPORT) {
        my $sub_name = $args{'-prefix'} ? $args{'-prefix'} . '_' . $sub : $sub;
        *{"$caller\::$sub_name"} = \&$sub;
    }
}

sub match_if {
    my $condition = shift;
    my ( $mw, @args ) = @_;
    
    if (ref $mw ne 'CODE') {
        my $mw_class = Plack::Util::load_class($mw, 'Plack::Middleware');
        $mw = sub { $mw_class->wrap($_[0], @args) };
    }

    return sub {
        Plack::Middleware::Conditional->wrap(
            $_[0],
            condition => $condition,
            builder => $mw
        );
    }
}

sub addr {
    my $not;
    my $ip;
    if ( @_ == 1 ) {
        $ip = $_[0];
    }
    else {
        $not = $_[0];
        $ip = $_[1];
    }

    my @ip = ref $ip ? @$ip : ($ip);
    my $cidr4 = Net::CIDR::Lite->new();
    my $cidr6 = Net::CIDR::Lite->new();
    for my $ip ( @ip ) {
        if ( $ip =~ m!:! ) {
            $cidr6->add_any($ip);
        }
        else {
            $cidr4->add_any($ip);
        }
    }

    return sub {
        my $env = shift;
        my $find_ip;
        if ( $env->{REMOTE_ADDR} =~ m!:! ) {
            $find_ip = $cidr6->find($env->{REMOTE_ADDR});
        }
        else {
            $find_ip = $cidr4->find($env->{REMOTE_ADDR});
        }
        return (defined $not && $not eq '!')  ? !$find_ip : $find_ip;
    };
}

sub _match {
    my $key = shift;
    my $not;
    my $val;
    if ( @_ == 1 ) {
        $val = $_[0];
    }
    else {
        $not = $_[0];
        $val = $_[1];
    }

    return sub {
        my $env = shift;
        my $ret;
        if ( ref $val && ref $val eq 'Regexp' ) {
            $ret = exists $env->{$key} && $env->{$key} =~ m!$val!;
        }
        elsif ( defined $val ) {
            $ret = exists $env->{$key} && $env->{$key} eq $val;
        }
        else {
            $ret = exists $env->{$key};
        }
        return ( defined $not && $not eq '!' ) ? !$ret : $ret;
    };
}

sub path {
    _match( 'PATH_INFO', @_ );
}

sub method {
    my $not;
    my $method;
    if ( defined $_[0] && $_[0] eq '!' ) {
        $not = shift;
    }
    return sub { 1 } unless @_;
    if ( @_ == 1 ) {
        $method = $_[0];
    }
    else {
        my $alternatives = join '|', map { quotemeta($_) } @_;
        $method = qr/^(?:$alternatives)$/i;
    }
    if ( defined $method && ! ref $method )  {
        $method = uc $method;
    }
    _match( 'REQUEST_METHOD', grep { defined } $not, $method );
}

sub header {
    my $header = shift;
    $header =~ s/-/_/g;
    $header = 'HTTP_' . uc($header);
    _match( $header, @_ );
}

sub browser {
    _match( "HTTP_USER_AGENT", @_ );
}

sub any {
    my @match = @_;
    return sub {
        my $env = shift;
        List::MoreUtils::any { $_->($env) } @match;
    };
}

sub all {
    my @match = @_;
    return sub {
        my $env = shift;
        List::MoreUtils::all { $_->($env) } @match;
    };
}


1;
__END__

=head1 NAME

Plack::Builder::Conditionals - Plack::Builder extension

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Builder::Conditionals;
  # exports "match_if, addr, path, method, header, browser, any, all"

  builder {
      enable match_if addr(['192.168.0.0/24','127.0.0.1']),
          "Plack::Middleware::ReverseProxy";

      enable match_if all( path(qr!^/private!), addr( '!', [qw!127.0.0.1 ::1!] ) ),
          "Plack::Middleware::Auth::Basic", authenticator => \&authen_cb;

      enable match_if sub { my $env = shift; $env->{HTTP_X_ENABLE_FRAMEWORK} },
          "Plack::Middleware::XFramework", framework => 'Test';

      $app;
  };

  use Plack::Builder::Conditionals -prefx => 'c';
  # exports "c_match_if, c_addr, c_path, c_method, c_header, c_any, c_all"


=head1 DESCRIPTION

Plack::Builder::Conditionals is..

=head1 FUNCTIONS

=over 4

=item match_if

  enable match_if addr('127.0.0.1'), "Plack::Middleware::ReverseProxy";
  enable match_if sub { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' }, "Plack::Middleware::ReverseProxy";

As like Plack::Builder's enable_if enable middleware if given conditions return true

=item addr

  addr('127.0.0.1');
  addr([qw!192.168.0.0/24 127.0.0.1 ::1!]);
  addr('!','127.0.0.1');

return true if REMOTE_ADDR is found in the CIDR range. If first argument is '!', return the opposite result.
This function supports IPv6 addresses

=item path

  path('/')
  path(qr!^/(\w+)/!)
  path('!', qr!^/private!)

matching PATH_INFO

=item method

  method('GET')
  method(qr/^(get|head)$/i)
  method(qw(GET HEAD))
  method('!','GET')
  method('!', qr/^(post|put)$/i)
  method('!', qw(POST PUT))

=item header

  header('User-Agent',qr/iphone/)
  header('If-Modified-Since') #exists check
  header('!', 'User-Agent',qr/MSIE/)

=item browser

  browser(qr/\bMSIE (7|8)/)
  browser('!',qr!^Mozilla/4!);

Shortcut for header('User-Agent')

=item all

  all( method('GET'), path(qr!^/static!) )

return true if all conditions are return true

=item any

  any( path(qr!^/static!), path('/favicon.ico') )

return true if any condition return true

=back

=head1 EXPORT

  use Plack::Builder::Conditionals -prefx => 'c';
  # exports "c_match_if, c_addr, c_path, c_method, c_header, c_any, c_all"
  
you can add selected prefix to export functions

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

L<Plack::Builder>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package Plient;

use warnings;
use strict;
use Carp;
our $VERSION = '0.03';
use File::Spec::Functions;
use base 'Exporter';
our @EXPORT = 'plient';
our @EXPORT_OK = 'plient_support';
our $bundle_mode = $ENV{PLIENT_BUNDLE_MODE};

sub plient {
    my ( $method, $uri, $args ) = @_;
    if ( $args && ref $args ne 'HASH' ) {
        warn 'invalid args: should be a hashref';
        return;
    }
    $args ||= {};
    return unless $uri;
    $uri =~ s/^\s+//;

    # XXX TODO move this $uri tweak thing to HTTP part
    # http://localhost:5000 => http://localhost:5000/
    $uri .= '/' if $uri =~ m{^https?://[^/]+$};

    # generate both body_hash and body_array to make handlers' life easier
    if ( $args->{body} ) {
        if ( ref $args->{body} eq 'HASH' ) {
            $args->{body_hash}  = $args->{body};
            $args->{body_array} = [];
            for my $k ( keys %{ $args->{body} } ) {
                if ( ref $args->{body}{$k} eq 'ARRAY' ) {
                    push @{ $args->{body_array} }, $k, $_
                      for @{ $args->{body}{$k} };
                }
                else {
                    push @{ $args->{body_array} }, $k, $args->{body}{$k};
                }
            }
        }
        elsif ( ref $args->{body} eq 'ARRAY' ) {
            $args->{body_array} = $args->{body};
            $args->{body_hash}  = {};
            for ( my $i = 0 ; $i < $#{ $args->{body} } ; $i += 2 ) {
                my $key = $args->{body}[$i];
                my $value =
                  defined $args->{body}[ $i + 1 ]
                  ? $args->{body}[ $i + 1 ]
                  : '';
                if ( exists $args->{body_hash}{$key} ) {
                    if ( ref $args->{body_hash}{$key} eq 'ARRAY' ) {
                        push @{ $args->{body_hash}{$key} }, $value;
                    }
                    else {
                        $args->{body_hash}{$key} =
                          [ $args->{body_hash}{$key}, $value ];
                    }
                }
            }
        }
        else {
            die 'invalid body args, should be either hashref or arrayref';
        }
    }

    my $sub = dispatch( $method, $uri, $args );
    if ( $sub ) {
        if ( $args->{output_file} ) {
            open my $fh, '>', $args->{output_file} or die $!;
            print $fh $sub->();
            close $fh;
            return 1;
        }
        else {
            return $sub->();
        }
    }
    else {
        warn "failed to $method on $uri"; 
        return;
    }

}

sub _extract_protocol {
    shift if $_[0] && $_[0] eq __PACKAGE__;
    my $uri = shift;
    return unless $uri;
    if ( $uri =~ /^http:/i ) {
        return 'http';
    }
    elsif ( $uri =~ /^https:/i ) {
        return 'https';
    }
    elsif ( $uri =~ /^file:/i ) {
        return 'file';
    }
    else {
        warn "unsupported uri: $uri";
        return;
    }
}

sub _dispatch_protocol {
    shift if $_[0] && $_[0] eq __PACKAGE__;
    my $protocol = shift;
    return unless $protocol;
    if ( $protocol eq 'file' ) {
        require Plient::Protocol::File unless $bundle_mode;
        return 'Plient::Protocol::File';
    }
    elsif ( $protocol eq 'http' ) {
        require Plient::Protocol::HTTP unless $bundle_mode;
        return 'Plient::Protocol::HTTP';
    }
    elsif ( $protocol eq 'https' ) {
        require Plient::Protocol::HTTPS unless $bundle_mode;
        return 'Plient::Protocol::HTTPS';
    }
    else {
        warn "unsupported protocol: $protocol";
        return;
    }
}


sub plient_support {
    shift if $_[0] && $_[0] eq __PACKAGE__;
    my ( $protocol, $method, $args ) = @_;
    return unless $protocol;
    $method ||= 'get';
    $args   ||= {};
    my $class = _dispatch_protocol( lc $protocol );
    return unless $class;
    return $class->support_method( $method, { %$args, check_only => 1 } );
}

sub dispatch {
    my ( $method, $uri, $args ) = @_;
    $method = lc $method;
    $method ||= 'get';    # people use get most of the time.
    my $class = _dispatch_protocol( _extract_protocol($uri) );
    return unless $class;

    if ( my $sub = $class->support_method( $method, $args ) ) {
        return sub { $sub->( $uri, $args ) };
    }
    else {
        warn "unsupported method: $method";
        return;
    }
}

my %all_handlers;
my $found_handlers;
sub all_handlers {
    return keys %all_handlers if $found_handlers;
    @all_handlers{keys %all_handlers, find_handlers()} = ();
    keys %all_handlers;
}

# to include handlers not in @INC.
sub _add_handlers {
    shift if $_[0] && $_[0] eq __PACKAGE__;
    for my $handler (@_) {
        next unless $handler;
        if ( $handler->can('support_protocol')
            && $handler->can('support_method') )
        {
            $all_handlers{$handler} = ();
        }
        else {
            warn "$handler is not a valid Plient handler";
        }
    }

    return keys %all_handlers;
}

sub handlers {
    shift if $_[0] && $_[0] eq __PACKAGE__;
    if ( my $protocol = lc shift ) {
        my %map =
          map { $_ => 1 }
          grep { $_->may_support_protocol($protocol) } all_handlers();
        my @handlers;
        my $preference = handler_preference($protocol);
        if ($preference) {
            @handlers =
              map { /^Plient::Handler::/ ? $_ : "Plient::Handler::$_" }
              grep {
                $_ =~ /::/
                  ? delete $map{$_}
                  : delete $map{"Plient::Handler::$_"}
              } @$preference;
        }
        push @handlers, keys %map unless $ENV{PLIENT_HANDLER_PREFERENCE_STRICT};
        return @handlers;
    }
    else {
        # fallback to return all the handlers
        return keys %all_handlers;
    }
}

sub find_handlers {
    $found_handlers = 1;
    return if $bundle_mode;
    my @hd;
    for my $inc (@INC) {
        my $handler_dir = catdir( $inc, 'Plient', 'Handler' );
        if ( -e $handler_dir ) {
            if ( opendir my $dh, $handler_dir ) {
                push @hd,
                  map { /(\w+)\.pm/ ? "Plient::Handler::$1" : () } readdir $dh;
            }
            else {
                warn "can't read $handler_dir";
            }
        }
    }

    @hd = grep { eval "require $_" or warn "failed to require $_" and 0 } @hd;

    @hd;
}

my %handler_preference = (
    http  => [qw/curl wget HTTPTiny HTTPLite LWP/],
    https => [qw/curl wget HTTPTiny LWP/],
);
if ( my $env = $ENV{PLIENT_HANDLER_PREFERENCE} ) {
    my %entry = map { split /:/, $_, 2 } split /;/, $env;
    %entry = map { $_ => [ split /,/, $entry{$_} || '' ] } keys %entry;
    for my $p ( keys %entry ) {
        $handler_preference{$p} = $entry{$p};
    }
}

sub handler_preference {
    shift if $_[0] && $_[0] eq __PACKAGE__;
    my ( $protocol, $handlers ) = @_;
    $protocol = lc $protocol;
    if ($handlers) {
        if ( ref $handlers eq 'ARRAY' ) {
            return $handler_preference{ $protocol } = $handlers;
        }
        else {
            warn "handlers shold be an arrayref";
            return;
        }
    }
    else {
        return $handler_preference{ $protocol };
    }
}


1;

__END__

=head1 NAME

Plient - the uniform way to use curl, wget, LWP, HTTP::Lite, etc.

=head1 SYNOPSIS

    use Plient qw/plient plient_support/;
    my $content = plient( 'get', 'http://cpan.org' );      # get http://cpan.org

    if ( plient_support( 'http', 'post' ) ) {
        my $content = plient(
            'post',
            'http://foo.com',
            {
                body => {
                    title => 'foo',
                    body  => 'bar',
                }
            }
        );
    }

# or 
    if ( my $http_post = plient_support( 'http', 'post' ) ) {
        my $content = $http_post->(
            'http://foo.com',
            {
                body => {
                    title => 'foo',
                    body  => 'bar',
                }
            }
        );
    }

=head1 DESCRIPTION

C<Plient> is a wrapper to clients like C<curl>, C<wget>, C<LWP> and
C<HTTP::Lite>, aiming to supply a uniform way for users.

It's intended to use in situations where you don't want to bind your applications
to one specific client. e.g. forcing users to install C<curl> even when some of
them already have C<wget> installed.

C<Plient> will try its best to use clients available.

C<Plient> is a very young project, only a subset of HTTP functionality is
implemented currently.

=head1 INTERFACE

=head2 plient( $method, $uri, $args )

accessing $uri with the specified $method and $args.

return the content server returns unless $args->{output_file} is set,
in which case return 1 to indicate success.

$method: for HTTP(S), can be 'get', 'post', 'head', etc.

$uri: e.g. http://cpan.org

$args: hashref, useful keys are:

=over 4

=item output_file

the file path returned content from server will be written to.
if this option is set, plient() will return 1 if with success.

=item user and password

for HTTP(S), these will be used to set Authorization header

=item auth_method

currently, only 'Basic' is supported, default is 'Basic'

=item content_type

for HTTP(S), specify the Contnet-Type of post data.
  availables are 'urlencoded' and 'form-data'.
  default is 'urlencoded'.
    
=item headers

hashref, this will be sent as HTTP(S) headers. e.g.
  { 'User-Agent' => 'plient/0.01' }

=item body

hashref or arrayref, this will be sent as HTTP(S) post data. e.g.
  {
    title => 'foo',
    body    => 'bar',
    foo     => [ 'bar', 'baz' ],
    file1    => { file => '/path/to/file' },
  }

  if one value is hashref with file key, it's interpreted as a file upload

=back

=head2 plient_support( $protocol, $method, $args )

test if we have $protocol's $method support in current environment.
returns the subroutine that can be called like a currying plient(),
e.g. the following 2 ways of 'GET' http://cpan.org are equivalent:

    my $content = plient('get', 'http://cpan.org');
    # ditto using plient_support
    my $http_get = plient_support('http', 'get');
    if ($http_get) {
        my $content = $http_get->('http://cpan.org');
    }

currently $args is not used, we may use it later, e.g. to test if support 
Digest Authentication.

=head1 ENV FOR USERS

=over 4

=item PLIENT_DEBUG

show more debug info if this it true.

=item PLIENT_CURL

curl's path, if not specified, use the one `which curl` returns

=item PLIENT_CURL_CONFIG

curl-config's path, if not specified, use the one `which curl-config`
returns

=item PLIENT_WGET

wget's path, if not specified, use the one `which wget` returns

=item PLIENT_HANDLER_PREFERENCE

preference of handlers, format is:

PROTOCOL1:HANDLER1,HANDLER2;PROTOCOL2:HANDLER3,...  

e.g.
    http:HTTPLite,curl,wget;https:curl,wget

default is equal to(not set in this env actually):

    http:curl,wget,HTTPLite,LWP;https:curl,wget,LWP


C<Plient> will try the listed one by one to get the first competent one to
handle the ongoing request.
but if none was found, it will try the other handlers not listed.

=back

=head1 ENV FOR DEVELOPERS

=over 4

=item PLIENT_HANDLER_PREFERENCE_STRICT

C<Plient> will try other handlers that are not listed in 
C<PLIENT_HANDLER_PREFERENCE> if all the listed ones can't handle
the ongoing request.

if this is true, C<Plient> won't try in this situation, instead,
it will die directly.

used in C<Plient>'s tests.

=item PLIENT_TEST_PLACKUP_WAIT

seconds we wait after starting plackup in tests. by default it's 1 second.
it can be decimal, e.g. 0.3

this waiting time is to make sure plack is really started.

=item PLIENT_BUNDLE_MODE

used in plient-make-bundle only, end users shouldn't touch this.

=back

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2010-2011 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


package Plient::Handler::wget;
use strict;
use warnings;

require Plient::Handler unless $Plient::bundle_mode;
our @ISA = 'Plient::Handler';

require Plient::Util unless $Plient::bundle_mode;
Plient::Util->import;

my ( $wget, %protocol, %all_protocol, %method );

sub all_protocol { return \%all_protocol }

@all_protocol{qw/http https ftp/} = ();

sub protocol { return \%protocol }
sub method { return \%method }

sub support_method {
    my $class = shift;
    my ( $method, $args ) = @_;
    if (   $args
        && $args->{content_type}
        && $args->{content_type} =~ 'form-data' )
    {
        return;
    }

    return $class->SUPER::support_method(@_);
}

my $inited;
sub init {
    return if $inited;
    $inited = 1;

    $wget = $ENV{PLIENT_WGET} || which('wget');
    return unless $wget;

    @protocol{qw/http https ftp/} = ();

    {
        local $ENV{LC_ALL} = 'en_US';
        my $message = `$wget https:// 2>&1`;
        if ( $message && $message =~ /HTTPS support not compiled in/i ) {
            delete $protocol{https};
        }
    }

    $method{http_get} = sub {
        my ( $uri, $args ) = @_;
        my $headers = translate_headers( $args );
        my $auth    = translate_auth($args);
        if ( open my $fh, "$wget -q -O - $headers $auth '$uri' |" ) {
            local $/;
            <$fh>;
        }
        else {
            warn "failed to get $uri with wget: $!";
            return;
        }
    };

    $method{http_post} = sub {
        my ( $uri, $args ) = @_;
        my $headers = translate_headers( $args );
        my $auth    = translate_auth($args);

        my $data = '';
        if ( $args->{body_array} ) {
            my $body = $args->{body_array};

            for ( my $i = 0 ; $i < $#$body ; $i += 2 ) {
                my $key = $body->[$i];
                my $value = defined $body->[ $i + 1 ] ? $body->[ $i + 1 ] : '';
                $data .= " --post-data $key=$value";
            }
        }

        if ( open my $fh, "$wget -q -O - $data $headers $auth '$uri' |" ) {
            local $/;
            <$fh>;
        }
        else {
            warn "failed to post $uri with curl: $!";
            return;
        }
    };

    $method{http_head} = sub {
        my ( $uri, $args ) = @_;
        # we can't use -q here, or some version may not show the header
        my $headers = translate_headers( $args );
        my $auth    = translate_auth($args);
        if ( open my $fh, "$wget -S --spider $headers $auth '$uri' 2>&1 |" ) {
            my $head = '';
            my $flag;
            while ( my $line = <$fh>) {
                # yeah, the head output has 2 spaces as indents
                if ( $line =~ m{^\s{2}HTTP} ) {
                    $flag = 1;
                }

                if ($flag) {
                    if ($line =~ s/^\s{2}(?=\S)//) {
                        $head .= $line;
                    }
                    else {
                        undef $flag;
                        last;
                    }
                }
            }
            return $head;
        }
        else {
            warn "failed to get head of $uri with wget: $!";
            return;
        }
    };

    if ( exists $protocol{https} ) {
        for my $m (qw/get post head put/) {
            $method{"https_$m"} = $method{"http_$m"}
              if exists $method{"http_$m"};
        }
    }

    return 1;
}

sub translate_headers {
    my $args = shift || {};
    my $headers = $args->{headers};
    return '' unless $headers;
    my $str;
    for my $k ( keys %$headers ) {
        $str .= " --header '$k:$headers->{$k}'";
    }
    return $str;
}

sub translate_auth {
    my $args = shift || {};
    my $auth = '';
    if ( $args->{user} && defined $args->{password} ) {
        my $method = lc $args->{auth_method} || 'basic';
        if ( $method eq 'basic' ) {
            $auth =
              " --user '$args->{user}' --password '$args->{password}'";
        }
        else {
            die "aborting: unsupported auth method: $method";
        }
    }
    return $auth;
}

__PACKAGE__->_add_to_plient if $Plient::bundle_mode;

1;

__END__

=head1 NAME

Plient::Handler::wget - 


=head1 SYNOPSIS

    use Plient::Handler::wget;

=head1 DESCRIPTION


=head1 INTERFACE

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2010-2011 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


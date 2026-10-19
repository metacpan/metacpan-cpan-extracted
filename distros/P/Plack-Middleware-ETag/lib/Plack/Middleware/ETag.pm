package Plack::Middleware::ETag;

# ABSTRACT: Adds automatically an ETag header.

use v5.14;
use warnings;

use Digest::SHA 5.96;
use Plack::Util;
use Plack::Util::Accessor
    qw( file_etag cache_control check_last_modified_header);

use parent qw/Plack::Middleware/;

our $VERSION = '0.06';

sub call {
    my $self = shift;
    my $res  = $self->app->(@_);

    $self->response_cb(
        $res,
        sub {
            my $res     = shift;
            my $headers = $res->[1];
            return if ( !defined $res->[2] );
            return if ( Plack::Util::header_exists( $headers, 'ETag' ) );
            return
                if ( $self->check_last_modified_header()
                && Plack::Util::header_exists( $headers, 'Last-Modified' ) );

            my $etag;

            if ( Plack::Util::is_real_fh( $res->[2] ) ) {

                my $file_attr = $self->file_etag || [qw/mtime size/];
                my @stats = stat $res->[2];
                if ( $stats[9] == time - 1 ) {
                    # if the file was modified less than one second before the request
                    # it may be modified in a near future, so we return a weak etag
                    $etag = "W/";
                }
                if ( grep {/inode/} @$file_attr ) {
                    $etag .= ( sprintf "%x", $stats[1] );
                }
                if ( grep {/mtime/} @$file_attr ) {
                    $etag .= "-" if ( $etag && $etag !~ /-$/ );
                    $etag .= ( sprintf "%x", $stats[9] );
                }
                if ( grep {/size/} @$file_attr ) {
                    $etag .= "-" if ( $etag && $etag !~ /-$/ );
                    $etag .= ( sprintf "%x", $stats[7] );
                }
            } else {
                my $sha = Digest::SHA->new;
                $sha->add( @{ $res->[2] } );
                $etag = $sha->hexdigest;
            }
            Plack::Util::header_set( $headers, 'ETag', $etag );
            $self->_set_cache_control($headers);
            return;
        }
    );
}

sub _set_cache_control {
    my ( $self, $headers ) = @_;
    return unless $self->cache_control;

    if ( ref $self->cache_control && ref $self->cache_control eq 'ARRAY' ) {
        Plack::Util::header_set( $headers, 'Cache-Control',
            join( ', ', @{ $self->cache_control } ) );
    } else {
        Plack::Util::header_set( $headers, 'Cache-Control',
            'must-revalidate' );
    }
}

1;

__END__

=pod

=encoding UTF-8

=for stopwords Rothenberg revalidate

=head1 NAME

Plack::Middleware::ETag - Adds automatically an ETag header.

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use Plack::Builder;

  my $app = builder {
    enable "Plack::Middleware::ETag", file_etag => [qw/mtime size/];
    sub {['200', ['Content-Type' => 'text/html'}, ['hello world']]};
  };

=head1 DESCRIPTION

Plack::Middleware::ETag adds automatically an ETag header. You may want to use it with C<Plack::Middleware::ConditionalGET>.

  my $app = builder {
    enable "Plack::Middleware::ConditionalGET";
    enable "Plack::Middleware::ETag", file_etag => [qw/mtime size/];
    sub {['200', ['Content-Type' => 'text/html'}, ['hello world']]};
  };

=head1 CONFIGURATION OPTIONS

=head2 file_etag

If the content is a file handle, the ETag will be set using the modified time and the file size.
You can select which attributes of the file will be used to set the ETag:

    enable "Plack::Middleware::ETag", file_etag => [qw/size/];

Supported attributes are

=over

=item mtime

This is the file modification time.

=item size

This is the file size.

=item inode

This includes the inode number.

It is no longer included by default since version 0.06, and is considered a potential security issue.

=back

=head2 cache_control

It's possible to add 'Cache-Control' header.

    enable "Plack::Middleware::ETag", cache_control => 1;

Will add "Cache-Control: must-revalidate" to the headers.

    enable "Plack::Middleware::ETag", cache_control => [ 'must-revalidate', 'max-age=3600' ];

Will add "Cache-Control: must-revalidate, max-age=3600" to the headers.

=head2 check_last_modified_header

Will not add an ETag if there is already a Last-Modified header.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Plack-Middleware-ETag>
and may be cloned from L<https://github.com/robrwo/perl-Plack-Middleware-ETag.git>

=head1 SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.14 or later.
Future releases may only support Perl versions released in the last ten (10) years.

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Plack-Middleware-ETag/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head2 Reporting Security Vulnerabilities

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see F<SECURITY.md> for instructions how to report security vulnerabilities.

=head1 AUTHORS

=over 4

=item *

Franck Cuny <franckcuny@gmail.com>

=item *

Robert Rothenberg <perl@rhizomnic.com>

=back

=head1 CONTRIBUTOR

=for stopwords Leo Lapworth

Leo Lapworth <leo@cuckoo.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015, 2026 by Franck Cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

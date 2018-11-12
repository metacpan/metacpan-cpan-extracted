package Mojolicious::Command::export;
our $VERSION = '0.004';
# ABSTRACT: Export a Mojolicious website to static files

#pod =head1 SYNOPSIS
#pod
#pod   Usage: APPLICATION export [OPTIONS] [PAGES]
#pod
#pod     ./myapp.pl export
#pod     ./myapp.pl export /perldoc --to /var/www/html
#pod     ./myapp.pl export /perldoc --base /url
#pod
#pod   Options:
#pod     -h, --help        Show this summary of available options
#pod         --to <path>   Path to store the static pages. Defaults to '.'.
#pod         --base <url>  Rewrite internal absolute links to prepend base
#pod     -q, --quiet       Silence report of dirs/files modified
#pod
#pod =head1 DESCRIPTION
#pod
#pod Export a Mojolicious webapp to static files.
#pod
#pod =head2 Configuration
#pod
#pod Default values for the command's options can be specified in the
#pod configuration using one of Mojolicious's configuration plugins.
#pod
#pod     # myapp.conf
#pod     {
#pod         export => {
#pod             # Configure the default paths to export
#pod             paths => [ '/', '/hidden' ],
#pod             # The directory to export to
#pod             to => '/var/www/html',
#pod             # Rewrite URLs to include base directory
#pod             base => '/',
#pod         }
#pod     }
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Mojolicious>, L<Mojolicious::Commands>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Command';
use Mojo::File qw( path );
use Mojo::Util qw( getopt encode decode );

has description => 'Export site to static files';
has usage => sub { shift->extract_usage };

sub run {
    my ( $self, @args ) = @_;
    my $app = $self->app;
    my $config = $app->can( 'config' ) ? $app->config->{export} : {};
    my %opt = (
        to => $config->{to} // '.',
        base => $config->{base} // '',
    );
    getopt( \@args, \%opt,
        'to=s',
        'base=s',
        'quiet|q' => sub { $self->quiet( 1 ) },
    );

    if ( $opt{base} =~ m{^[^/]} ) {
        $opt{base} = '/' . $opt{base};
    }

    my $root = path( $opt{ to } );
    my @pages
        = @args ? map { m{^/} ? $_ : "/$_" } @args
        : $config->{pages} ? @{ $config->{pages} }
        : ( '/' );

    my $ua = Mojo::UserAgent->new;
    $ua->server->app( $self->app );

    # A hash of path => knowledge about the path
    #   link_from => a hash of path -> array of DOM elements linking to original path
    #   res => The response from the request for this page
    #   redirect_to => The redirect location, if it was a redirect
    my %history;

    while ( my $page = shift @pages ) {
        next if $history{ $page }{ res };
        my $tx = $ua->get( $page );
        my $res = $history{ $page }{ res } = $tx->res;

        # Do not try to write error messages
        if ( $res->is_error ) {
            if ( !$self->quiet ) {
                say sprintf "  [ERROR] %s - %s %s",
                    $page, $res->code, $res->message;
            }
            next;
        }

        # Rewrite links to redirects
        if ( $res->is_redirect ) {
            my $loc = $history{ $page }{ redirect_to } = $res->headers->location;
            say "  [redir] Found redirect. Fixing links to this page"
                unless $self->quiet;
            for my $link_from ( keys %{ $history{ $page }{ link_from } } ) {
                for my $el ( @{ $history{ $page }{ link_from }{ $link_from } } ) {
                    $el->attr( href => $loc );
                }
                my $content = $history{ $link_from }{ res }->dom;
                $self->_write( $root, $link_from, $content );
            }
            next;
        }

        my $type = $res->headers->content_type;
        my $content = $tx->res->body;
        if ( $type and $type =~ m{^text/html} and my $dom = $res->dom ) {
            my $dir = path( $page )->dirname;
            for my $attr ( qw( href src ) ) {
                for my $el ( $dom->find( "[$attr]" )->each ) {
                    my $url = $el->attr( $attr );

                    # Don't analyze full URLs
                    next if $url =~ m{^(?:[a-zA-Z]+:)?//};
                    # Don't analyze in-page fragments
                    next if $url =~ m{^#};

                    # Fix relative paths
                    my $path = $url =~ m{^/} ? $url : $dir->child( $url )."";
                    # Remove fragment
                    $path =~ s/#.+//;

                    if ( my $loc = $history{ $path }{ redirect_to } ) {
                        $el->attr( $attr => $loc );
                        next;
                    }
                    else {
                        push @{ $history{ $path }{ link_from }{ $page } }, $el;
                    }

                    if ( !$history{ $path }{ res } ) {
                        push @pages, $path;
                    }

                    # Rewrite absolute paths
                    if ( $opt{base} && $url =~ m{^/} ) {
                        my $base_url = $url eq '/' ? $opt{base} : $opt{base} . $url;
                        $el->attr( $attr => $base_url );
                    }
                }
            }
            $content = $dom;
        }

        $self->_write( $root, $page, $content );
    }
}

sub _write {
    my ( $self, $root, $page, $content ) = @_;
    if ( ref $content eq 'Mojo::DOM' ) {
        # Mojolicious automatically decodes using the response content
        # type, so all we need to do is encode it into the file content
        # type that we want
        # TODO: Allow configuring the destination encoding
        # TODO: Ensure all text/* MIME types use the destination
        # encoding
        $content = encode 'utf8', $content;
    }
    my $to = $root->child( $page );
    if ( $to !~ m{[.][^/.]+$} ) {
        $to = $to->child( 'index.html' );
    }
    if ( -e $to ) {
        say "  [delet] $to" unless $self->quiet;
        unlink $to;
    }
    $self->write_file( $to, $content );
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Command::export - Export a Mojolicious website to static files

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  Usage: APPLICATION export [OPTIONS] [PAGES]

    ./myapp.pl export
    ./myapp.pl export /perldoc --to /var/www/html
    ./myapp.pl export /perldoc --base /url

  Options:
    -h, --help        Show this summary of available options
        --to <path>   Path to store the static pages. Defaults to '.'.
        --base <url>  Rewrite internal absolute links to prepend base
    -q, --quiet       Silence report of dirs/files modified

=head1 DESCRIPTION

Export a Mojolicious webapp to static files.

=head2 Configuration

Default values for the command's options can be specified in the
configuration using one of Mojolicious's configuration plugins.

    # myapp.conf
    {
        export => {
            # Configure the default paths to export
            paths => [ '/', '/hidden' ],
            # The directory to export to
            to => '/var/www/html',
            # Rewrite URLs to include base directory
            base => '/',
        }
    }

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Commands>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

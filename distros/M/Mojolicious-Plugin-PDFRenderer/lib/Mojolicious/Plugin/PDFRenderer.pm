package Mojolicious::Plugin::PDFRenderer;
use Mojo::Base 'Mojolicious::Plugin';
use PDF::WebKit;
use List::AllUtils qw/uniq/;

sub register {
    my ( $self, $app, $opts ) = @_;
    $opts->{ '-args-override' } //= 1 unless exists $opts->{ '-args-override' };
    $opts->{ '-conf-override' } //= 1 unless exists $opts->{ '-conf-override' };
    my $args_override = delete $opts->{ '-args-override' };
    my $conf_override = delete $opts->{ '-conf-override' };
    my @opts = `wkhtmltopdf --extended-help`;
       @opts = map { my $opt = $_; $opt =~ s/.*--([^ =,]+).*/$1/g; $opt =~ s/-/_/g; $opt =~ s/\W//g; $opt =~ s/_+$//g; $opt } grep { $_ =~ /--[^ =]+/ } @opts;
       @opts = uniq @opts;
    my %okay = map { $_ => 1 } @opts;
    $app->plugin( 'Mojolicious::Plugin::Args' ) if $args_override;
    $app->hook( around_action => sub {
        my ( $next, $c, $action, $last ) = @_;
        my $url  = $c->req->url->to_abs;
        return $next->() unless $c->stash->{format} and $c->stash->{format} eq 'pdf';
        $c->respond_to( pdf => sub {
            my $url  = $c->req->url->to_abs;
               $url =~ s/\.pdf($|\?)/$1/i;

            $app->log->debug( "...fetching url $url for pdf" );

            my %opts = %{ $opts };

            args_override: {
                last args_override unless $args_override;
                my %args = $c->args;
                my @keys = grep { $okay{ $_ } } keys %args;
                $opts{ $_ } = $args{ $_ } for @keys;
                $app->log->debug( "pdf args override...", $app->dumper( \%opts ) ) if @keys;
            };

            conf_override: {
                last conf_override unless $conf_override and exists $app->config->{pdf};
                my ( %conf, %over, %seen );
                my ( $path, @path );
                %conf = %{ $app->config->{pdf} };
                $path = $app->renderer->template_for( $c );
                @path = split /\//, $path;
                path: for my $i ( 0 .. $#path ) {
                    my $conf = \%conf;
                    my @path = @path[ 0 .. $i ];
                    my @seen;
                    seen: for my $path ( @path ) {
                        last path unless exists $conf->{ $path }; $conf = $conf->{ $path };
                        push @seen, $path; my $seen = join '/', @seen; next seen if $seen{ $seen }; $seen{ $seen } = 1;
                        for my $key ( keys %{ $conf } ) {
                            next if not defined $conf->{ $key } or ref $conf->{ $key };
                            $over{ $key } = $conf->{ $key };
                        }
                    }
                }
                $path = $c->url_for;
                $path =~ s/^\///;
                @path = split /\//, $path;
                path: for my $i ( 0 .. $#path ) {
                    my $conf = \%conf;
                    my @path = @path[ 0 .. $i ];
                    my @seen;
                    seen: for my $path ( @path ) {
                        last path unless exists $conf->{ $path }; $conf = $conf->{ $path };
                        push @seen, $path; my $seen = join '/', @seen; next seen if $seen{ $seen }; $seen{ $seen } = 1;
                        for my $key ( keys %{ $conf } ) {
                            next if not defined $conf->{ $key } or ref $conf->{ $key };
                            $over{ $key } = $conf->{ $key };
                        }
                    }
                }
                $opts{ $_ } = $over{ $_ } for keys %over;
                $app->log->debug( "pdf conf override...", $app->dumper( \%opts ) ) if %over;
            };

            my $kit = new PDF::WebKit ( $url, %opts );
            my $pdf = $kit->to_pdf;

            $c->res->headers->content_type( 'application/pdf' );
            $c->res->body( $pdf );
            $c->rendered( 200 );
        } );
    } );

    $app->helper( is_pdf_request => sub { shift->req->headers->user_agent =~ /wkhtmltopdf/i ? 1 : 0 } );
}

# ABSTRACT: Uses wkhtmltopdf via PDF::WebKit to render your app exactly as it looks in Chrome/WebKit but vector scalable and in PDF.
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::PDFRenderer - Uses wkhtmltopdf via PDF::WebKit to render your app exactly as it looks in Chrome/WebKit but vector scalable and in PDF.

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    package App;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my $self = shift;

        $self->plugin( 'Mojolicious::Plugin::PDFRenderer', {
            javascript_delay => 1000
            , load_error_handling => 'ignore'
            , page_height => '5in'
            , page_width => '10.5in'
            # options that would otherwise be passed to PDF::WebKit,
            # see `wkhtmltopdf --extended-help` for more (replace dashes w/ underscores)
        } );
        # ...
    }

Then go to http://yourapp:3000/any/route, take a good look, then go to http://yourapp:3000/any/route.pdf. Cool, huh?

=head1 REQUIREMENTS

=over 2

=item L<PDF::WebKit>

=item L<"wkhtmltopdf"|http://wkhtmltopdf.org/>

=item A preforking server instance running (e.g. ./script/app prefork [...] or ./script/app hypnotoad [...], etc) with at least 2
connections / workers available so that the extension can hit the back-end again, i.e. a request in a request.

=back

=head1 SEE ALSO

=over 2

=item Other cool stuff I've written

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/sharabash/mojolicious-plugin-pdfrenderer/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/sharabash/mojolicious-plugin-pdfrenderer>

  git clone git://github.com/sharabash/mojolicious-plugin-pdfrenderer.git

=head1 AUTHOR

Nour Sharabash <amirite@cpan.org>

=head1 CONTRIBUTORS

=over 4

=item *

Nour Sharabash <nour.sharabash@gmail.com>

=item *

Nour Sharabash <nour@hellosign.com>

=item *

gabriele.ceranto <gabriele.ceranto@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Nour Sharabash.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

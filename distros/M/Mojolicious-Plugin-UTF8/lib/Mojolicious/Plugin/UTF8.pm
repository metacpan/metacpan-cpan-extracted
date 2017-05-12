package Mojolicious::Plugin::UTF8;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ( $self, $app, $opts ) = @_;
    charset_encoding: {
        $app->hook( after_dispatch => sub {
            my ( $c ) = @_;
            if ( my $content_type = $c->res->headers->header( 'Content-Type' ) ) {
                $c->res->headers->header( 'Content-Type' => "$content_type; charset=utf-8" )
                    if $content_type =~ /^[^\/;]+\/[^\/;]+$/;
            }
        } );
        $app->hook( after_render => sub {
            my ( $c ) = @_;
            if ( my $content_type = $c->res->headers->header( 'Content-Type' ) ) {
                $c->res->headers->header( 'Content-Type' => "$content_type; charset=utf-8" )
                    if $content_type =~ /^[^\/;]+\/[^\/;]+$/;
            }
        } );
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::UTF8

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    package App;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my $self = shift;

        $self->plugin( 'Mojolicious::Plugin::UTF8' );
    }

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/sharabash/mojolicious-plugin-utf8/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/sharabash/mojolicious-plugin-utf8>

  git clone git://github.com/sharabash/mojolicious-plugin-utf8.git

=head1 AUTHOR

Nour Sharabash <amirite@cpan.org>

=head1 CONTRIBUTOR

Nour Sharabash <nour.sharabash@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Nour Sharabash.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

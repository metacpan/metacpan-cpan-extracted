package Mojolicious::Plugin::Args;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON 'decode_json';

sub register {
    my ( $self, $app, $opts ) = @_;
    $opts->{ '-want-detail' } //= 0 unless exists $opts->{ '-want-detail' };
    my $want_detail = delete $opts->{ '-want-detail' };

    $app->helper( args => sub {
        my $c = shift;
        my $stash = $c->stash;
        my @param = $c->param;
        my ( %args, %save );
        $args{ $_ } = $c->param( $_ ) for @param;
        $save{ $_ } = $stash->{args}{ $_ } for grep { exists $stash->{args} and defined $stash->{args}{ $_ } } keys %args;
        my $type = $c->req->headers->header( 'Content-Type' );
        if ( ( $c->req->method ne 'GET' and $type and $type =~ 'application/json' ) or
             ( $c->req->method eq 'GET' and defined $stash->{format} and $stash->{format} eq 'json' and defined $args{json} ) ) {
            my @args = keys %args;
            my $json = decode_json( $c->req->method eq 'GET' ? delete $args{json} : $c->req->body );
            my @json = keys %{ $json };
            do {
                $args{__args}->{ $_ } = $args{ $_ }   for @args; # save to __priv
                $args{__json}->{ $_ } = $json->{ $_ } for @json; # for specific access
            } if $want_detail;
            $args{ $_ } = $json->{ $_ } for @json;
        }
        %args = ( %args, %save ); # this allows interception and override from route conditions that want to validate/modify and/or hooks
        $stash->{args} = \%args;
        return wantarray ? %{ $stash->{args} } : $stash->{args};
    } ) unless $app->renderer->helpers->{args};
}

# ABSTRACT: gives you back the request parameters as a simple %args hash, even if it's posted in json.
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Args - gives you back the request parameters as a simple %args hash, even if it's posted in json.

=head1 VERSION

version 0.05

=head1 SYNOPSIS

Route something like this:

    package App;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my $self = shift;

        $self->plugin( 'Mojolicious::Plugin::Args' );

        my $r = $self->routes;

        $r->any( '/example/test' )->to( 'example#test' );
    }

Here's the controller:

    package App::Example;
    use Mojo::Base 'Mojolicious::Controller';

    sub test {
        my $self = shift;
        my %args = $self->args;

        $self->log->debug( 'args', $self->dumper( \%args ) );
        $self->render( json => \%args );
    }

Now send a POST to it (jQuery example):

    $.ajax( {
        type: 'POST'
        ,url: '/example/test'
        ,contentType: 'application/json'
        ,dataType: 'json'
        ,data: JSON.stringify( { foo: 'bar' } )
    } );

Inspect the response. Keen. Try a GET on the endpoint with ".json" typed (C</example/test.json>) and a json query string variable (C<?json=...>). Same result.

    $.ajax( {
        type: 'GET'
        ,url: '/example/test.json?json='+ JSON.stringify( { foo: 'bar' } )
    } );

Also, try regular query string vars (e.g. C<?foo=bar&baz=foo>) and form-url-encoded POST stuff. Works the same. All-in-one: no more dealing with the stupid C<param> helper.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/sharabash/mojolicious-plugin-args/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/sharabash/mojolicious-plugin-args>

  git clone git://github.com/sharabash/mojolicious-plugin-args.git

=head1 AUTHOR

Nour Sharabash <amirite@cpan.org>

=head1 CONTRIBUTOR

Nour Sharabash <nour.sharabash@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Nour Sharabash.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

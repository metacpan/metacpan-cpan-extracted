package Mojolicious::Plugin::DumpyLog;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ( $self, $app, $opts ) = @_;
    logger_methods: {
        do { my $method = $_;
        $app->helper( $method => sub {
            my ( $c, @args ) = @_;

            my $dump = pop @args if ref $args[ -1 ];
            my $name = ref $c eq 'Mojolicious::Controller' ? ref $c->app : ref $c;

            $app->log->$method( $name .' - '. join ', ', grep { defined } @args );
            $app->log->$method( $c->dumper( $dump ) ) if $dump;
        } ) } for qw/debug error fatal info log warn/; # proxy over the base logger methods
    };
}

# ABSTRACT: Automatically runs Data::Dumper against the last element in the list passed to any ->log->method() if it's a ref.
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::DumpyLog - Automatically runs Data::Dumper against the last element in the list passed to any ->log->method() if it's a ref.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    package App;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my $self = shift;

        $self->plugin( 'Mojolicious::Plugin::DumpyLog' );
        # ...
    }

then

    package App::Example;
    use Mojo::Base 'Mojolicious::Controller';

    sub test {
        my $self = shift;
        my %foo = ( bar => 'baz' );
        $self->debug( "foo", "bar", "baz", \%foo );
        $self->render( json => [] );
    }

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/sharabash/mojolicious-plugin-dumpylog/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/sharabash/mojolicious-plugin-dumpylog>

  git clone git://github.com/sharabash/mojolicious-plugin-dumpylog.git

=head1 AUTHOR

Nour Sharabash <amirite@cpan.org>

=head1 CONTRIBUTOR

Nour Sharabash <nour.sharabash@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Nour Sharabash.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

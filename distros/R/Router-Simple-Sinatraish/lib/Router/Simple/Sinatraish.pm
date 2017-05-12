package Router::Simple::Sinatraish;
use strict;
use warnings;
use parent qw/Exporter/;
use 5.00800;
our $VERSION = '0.03';
use Router::Simple;

our @EXPORT = qw/router any get post/;

sub router {
    my $class = shift;
    no strict 'refs';
    no warnings 'once';
    ${"${class}::ROUTER"} ||= Router::Simple->new();
}

# any [qw/get post delete/] => '/bye' => sub { ... };
# any '/bye' => sub { ... };
sub any($$;$) {
    my $pkg = caller(0);
    if (@_==3) {
        my ($methods, $pattern, $code) = @_;
        $pkg->router->connect(
            $pattern,
            {code => $code},
            { method => [ map { uc $_ } @$methods ] }
        );
    } else {
        my ($pattern, $code) = @_;
        $pkg->router->connect(
            $pattern,
            {code => $code},
        );
    }
}

sub get  {
    my $pkg = caller(0);
    $pkg->router->connect($_[0], {code => $_[1]}, {method => ['GET', 'HEAD']});
}
sub post {
    my $pkg = caller(0);
    $pkg->router->connect($_[0], {code => $_[1]}, {method => ['POST']});
}

1;
__END__

=encoding utf8

=head1 NAME

Router::Simple::Sinatraish - Sinatra-ish routers on Router::Simple

=head1 SYNOPSIS

    package MySinatraishFramework;
    use Router::Simple::Sinatraish;
    
    sub import {
        Router::Simple::Sinatraish->export_to_level(1);
    }

    sub to_app {
        my ($class) = caller(0);
        sub {
            my $env = shift;
            if (my $route = $class->router->match($env)) {
                return $route->{code}->($env);
            } else {
                return [404, [], ['not found']];
            }
        };
    }

    package MyApp;
    use MySinatraishFramework;

    get '/' => sub {
        [200, [], ['ok']];
    };
    post '/edit' => sub {
        [200, [], ['ok']];
    };
    any '/any' => sub {
        [200, [], ['ok']];
    };

    __PACKAGE__->to_app;

=head1 DESCRIPTION

Router::Simple::Sinatraish is toolkit library for sinatra-ish WAF.

=head1 EXPORTABLE METHODS

=over 4

=item my $router = YourClass->router;

Returns this instance of L<Router::Simple>.

=back

=head1 EXPORTABLE FUNCTIONS

=over 4

=item get($path:Str, $code:CodeRef)

    get '/' => sub { ... };

Add new route, handles GET method.

=item post($path:Str, $code:CodeRef)

    post '/' => sub { ... };

Add new route, handles POST method.

=item any($path:Str, $code:CodeRef)

    any '/' => sub { ...  };

Add new route, handles any HTTP method.

=item any($methods:ArrayRef[Str], $path:Str, $code:CodeRef)

    any [qw/GET DELETE/] => '/' => sub { ...  };

Add new route, handles any HTTP method.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

L<Router::Simple>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package Plack::Middleware::SetLocalEnv;
use 5.008001;
use strict;
use warnings;
use parent "Plack::Middleware";

our $VERSION = "0.02";

sub call {
    my ($self, $env) = @_;

    local %ENV = %ENV;
    for my $key (keys %$self) {
        $ENV{$key} = $env->{ $self->{$key} }
            if exists $env->{$self->{$key}};
    }
    $self->app->($env);
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::SetLocalEnv - Set localized environment variables from the value of PSGI environment.

=head1 SYNOPSIS

    use Plack::Builder;
    builder {
        enable 'SetLocalEnv' =>
            REQUEST_ID       => "HTTP_X_REQUEST_ID",
            URL_SCHEME       => "psgi.url_scheme",
        #   "local %ENV key" => "psgi env key",
        ;
        $app;
    };

=head1 DESCRIPTION

Plack::Middleware::SetLocalEnv - Set localized environment variables(Perl's %ENV) from the value of PSGI environment.

=head1 LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

FUJIWARA Shunichiro E<lt>fujiwara.shunichiro@gmail.comE<gt>

=cut


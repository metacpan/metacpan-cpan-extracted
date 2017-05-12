package Plack::Middleware::DebugRequestParams;
use 5.008005;
use strict;
use warnings;
use parent qw(Plack::Middleware);
use Text::ASCIITable;
use Plack::Request;
use Text::VisualWidth::UTF8;

our $VERSION = "0.06";

sub call {
    my($self, $env) = @_;

    if (! ($self->{ignore_path} &&  $env->{REQUEST_URI} =~ /$self->{ignore_path}/)) {
        my $req = Plack::Request->new($env);
        my $params = $req->parameters;
        if (%$params) {
            my $table = Text::ASCIITable->new(+{ cb_count => \&Text::VisualWidth::UTF8::width });
            $table->setCols(qw(Parameter Value));
            for my $key (sort keys %$params) {
                my @values = $params->get_all($key);
                for my $value (@values) {
                    $table->addRow($key, $value);
                }
            }
            print STDERR $table;
        }
    }

    return $self->app->($env);
}


1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::DebugRequestParams - debug request parameters (inspired by Catalyst)

=head1 SYNOPSIS

    $ plackup -e 'enable "DebugRequestParams"' app.psgi
    $ curl -F foo=bar -F baz=foobar http://localhost:5000/
    .--------------------.
    | Parameter | Value  |
    +-----------+--------+
    | baz       | foobar |
    | foo       | bar    |
    '-----------+--------'

=head1 OPTIONS

=over

=item ignore_path

    use Plack::Builder;

    builder {
        enable "DebugRequestParams",
            ignore_path => qr{^/(images|js|css)/},
        $app;
    };

=back

=head1 LICENSE

Copyright (C) Hiroki Honda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroki Honda E<lt>cside.story@gmail.comE<gt>

=cut


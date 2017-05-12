package Plack::Middleware::LogFilter;
use strict;
use warnings;
use parent qw(Plack::Middleware);

use Plack::Util::Accessor qw(filter);

our $VERSION = "0.01";

sub call {
    my ($self, $env) = @_;

    $env->{'psgi.errors'} =
        Plack::Middleware::LogFilter::_wrap->new(
            $env,
            $self->filter,
        );
    my $res = $self->app->($env);
    return $res;
}


package Plack::Middleware::LogFilter::_wrap;

sub new {
    my ($class, $env, $filter) = @_;
    return bless {
        env => $env,
        '_psgi.errors' => $env->{'psgi.errors'},
        filter => $filter || sub { return 1; },
    }, $class;
}

sub print {
    my ($self, $output) = @_;

    my $filter = $self->{filter};
    if (!$filter || (ref $filter eq 'CODE' && $filter->($self->{env}, $output))) {
        return $self->{'_psgi.errors'}->print($output);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::LogFilter - modify log output.

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'LogFilter', filter => sub {
            my ($env, $output) = @_;

            # ignore static file log
            if ($output =~ /\/static\/(js|css|images)/) {
                return 0;
            }

            return 1;
        };
        $app
    };

=head1 DESCRIPTION

This middleware allows the modification of log output.

=head1 LICENSE

Copyright (C) Uchiko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Uchiko E<lt>memememomo@gmail.comE<gt>

=cut


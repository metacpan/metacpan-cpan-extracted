# 
# This file is part of Plack-Middleware-Status
# 
# This software is copyright (c) 2010 by Patrick Donelan.
# 
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# 
package Plack::Middleware::Status;
BEGIN {
  $Plack::Middleware::Status::VERSION = '1.101150';
}

# ABSTRACT: Plack Middleware for mapping urls to status code-driven responses
use strict;
use parent qw/Plack::Middleware/;
use HTTP::Status;
use Plack::Util::Accessor qw( path status );
use Carp;


sub call {
    my $self = shift;
    my $env  = shift;

    my $res = $self->_handle($env);
    return $res if $res;

    return $self->app->($env);
}

sub _handle {
    my ( $self, $env ) = @_;

    my $path_match = $self->path;
    my $status     = $self->status;
    my $path       = $env->{PATH_INFO};
    for ($path) {
        my $matched = 'CODE' eq ref $path_match ? $path_match->($_) : $_ =~ $path_match;
        return unless $matched;
    }

    my $message = HTTP::Status::status_message($status) or do {
        carp "Invalid HTTP status: $status";
        return;
    };

    return [ $status, [ 'Content-Type' => 'text/plain', 'Content-Length' => length($message) ], [$message] ];
}

1;

__END__
=pod

=head1 NAME

Plack::Middleware::Status - Plack Middleware for mapping urls to status code-driven responses

=head1 VERSION

version 1.101150

=head1 SYNOPSIS

    # app.psgi
    use Plack::Builder;
    my $app = sub { 
        # ... 
    };
    builder {
        enable 'Status', path => qr{/not-implemented}, status => 501;
        $app;
    };

=head1 AUTHOR

  Patrick Donelan <pat@patspam.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Patrick Donelan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


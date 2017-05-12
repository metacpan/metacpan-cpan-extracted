package Plack::Middleware::LogAny;
{
  $Plack::Middleware::LogAny::VERSION = '0.001';
}
# ABSTRACT: Use Log::Any to handle logging from your Plack app

use Log::Any qw{};
use Plack::Util::Accessor qw{category logger};
use parent qw{Plack::Middleware};
use strict;
use warnings;


sub prepare_app {
    my ($self) = @_;
    $self->logger (Log::Any->get_logger (category => $self->category || ''));
}


sub call {
    my ($self, $env) = @_;

    $env->{'psgix.logger'} = sub {
        my $args = shift;
        my $level = $args->{level};
        $self->logger->$level ($args->{message});
    };

    $self->app->($env);
}

1;

__END__
=pod

=head1 NAME

Plack::Middleware::LogAny - Use Log::Any to handle logging from your Plack app

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  builder {
      enable "LogAny", category => "plack";
      $app;
  }

=head1 DESCRIPTION

LogAny is a L<Plack::Middleware> component that allows you to use
L<Log::Any> to handle the logging object, C<psgix.logger>.

It really tries to be the thinnest possible shim, so it doesn't handle
any configuration beyond setting the category to which messages from
plack might be logged.

=head1 METHODS

=head2 prepare_app

This method initializes the logger using the category that you
(optionally) set.

=head2 call

Actually handles making sure the logger is invoked.

=head1 CONFIGURATION

=over 4

=item category

The C<Log::Any> category to send logs to. Defaults to C<''> which
means it send to the root logger.

=back

=head1 SEE ALSO

L<Log::Any>

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Michael Alan Dorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


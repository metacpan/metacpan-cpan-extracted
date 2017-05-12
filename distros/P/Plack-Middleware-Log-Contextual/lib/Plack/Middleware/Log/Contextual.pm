package Plack::Middleware::Log::Contextual;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(level logger);

use Log::Contextual qw(with_logger);
use Plack::Middleware::Log::Contextual::Logger;

sub call {
    my($self, $env) = @_;

    my $logger = $self->logger;
    unless ($logger) {
        if ($env->{'psgix.logger'}) {
            $logger = Plack::Middleware::Log::Contextual::Logger->new($env->{'psgix.logger'}, $self->level);
        } else {
            $env->{'psgi.errors'}->print(__PACKAGE__ . ": logger or psgix.logger is not available.\n");
        }
    }

    my $res;
    with_logger $logger, sub { $res = $self->app->($env) };

    if (ref $res eq 'CODE') {
        return sub {
            my $r = shift;
            with_logger $logger, sub { $res->($r) };
        };
    }

    return $res;
}

require Plack::Middleware::Log::Contextual;

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Plack::Middleware::Log::Contextual - integrate Log::Contextual with Plack/PSGI logger middleware

=head1 SYNOPSIS

  # in your PSGI web application
  use Log::Contextual qw(:log);

  log_info  { "Information" };
  log_fatal { "ZOMG this shouldn't happen: " . $self->dump_stuff };

  # standalone mode
  use Plack::Builder;
  use Log::Dispatchouli;

  my $ld = Log::Dispatchouli->new(...);

  builder {
      enable "Log::Contextual", logger => $ld;
      $app;
  };

  # PSGI logger mode
  use Plack::Builder;

  builder {
      enable "ConsoleLogger"; # should come before Log::Contextual
      enable "Log::Contextual";
      $app;
  };

=head1 DESCRIPTION

Plack::Middleware::Log::Contextual is a PSGI middleware component that
integrates L<Log::Contextual> with your application. It works as a
standalone and could also be used in combination with PSGI logger
framework.

=head1 CONFIGURATION

=head2 Standalone mode

You can use Log::Contextual as a standalone, meaning you can configure
the logger object by yourself in the PSGI setup, and all the logging
calls get propagated to the logger object you configured.

  use Plack::Builder;
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init(...);

  my $logger = Log::Log4perl->get_logger;

  builder {
      enable "Log::Contextual", logger => $logger;
      $psgi_app;
  };

=head2 PSGI logger mode

This middleware also works with the middleware components that support
C<psgix.logger> extention, such as L<Plack::Middleware::SimpleLogger>,
L<Plack::Middleware::LogDispatch> or L<Plack::Middleware::ConsoleLogger>.

  use Plack::Builder;

  builder {
      enable "ConsoleLogger";
      enable "Log::Contextual", level => "debug";
      $psgi_app;
  };

Note that the PSGI logger should be applied B<before> this middleware.

Unlike the standalone mode where you configure the minimum (and
maximum) level in the logger, you should configure the minimum
C<level> in the middleware configuration like seen above. It defaults
to C<debug>.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2011- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut

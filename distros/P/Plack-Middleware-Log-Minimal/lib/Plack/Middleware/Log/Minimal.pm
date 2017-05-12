package Plack::Middleware::Log::Minimal;
use strict;
use warnings;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw( autodump loglevel formatter encoding);
use Log::Minimal 0.09;
use Carp qw/croak/;
use Encode;

our $VERSION = '0.06';

sub build_logger {
    my ($self, $env) = @_;
    return sub {
        my ( $time, $type, $message, $trace, $raw_message) = @_;
        $message = Encode::encode($self->encoding,$message) if Encode::is_utf8($message);
        $env->{'psgi.errors'}->print($self->formatter->($env, $time, $type, $message, $trace, $raw_message));
    };
}


sub prepare_app {
    my $self = shift;
    $self->formatter(sub{
        my ($env, $time, $type, $message, $trace, $raw_message) = @_;
        sprintf "%s [%s] [%s] %s at %s\n", $time, $type, $env->{REQUEST_URI}, $message, $trace;
    }) unless $self->formatter;

    my $encoding = find_encoding($self->encoding || 'utf8');
    croak(sprintf 'encoding %s no found', $self->encoding) unless ref $encoding;
    $self->encoding($encoding);
}

sub call {
    my ($self, $env) = @_;
    local $Log::Minimal::PRINT = $self->build_logger($env);
    local $ENV{$Log::Minimal::ENV_DEBUG} = ($ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development') ? 1 : 0;
    local $Log::Minimal::AUTODUMP = 1 if $self->autodump;
    local $Log::Minimal::COLOR = 1 if $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development';
    local $Log::Minimal::LOG_LEVEL = $self->loglevel if $self->loglevel;
    $self->app->($env);
}

1;
__END__

=head1 NAME

Plack::Middleware::Log::Minimal - Log::Minimal middleware to prints to psgi.errors

=head1 SYNOPSIS

  use Log::Minimal;
  use Plack::Builder;

  builder {
      enable "Plack::Middleware::Log::Minimal", autodump => 1;
      sub {
          my $env = shift;
          debugf("debug message");
          infof("infomation message");
          warnf("warning message");
          critf("critical message");
          ["200",[ 'Content-Type' => 'text/plain' ],["OK"]];
      };
  };

  # print "2010-10-20T00:25:17 [INFO] infomation message at example.psgi" to psgi.errors stream

=head1 DESCRIPTION

Plack::Middleware::Log::Minimal is middleware that integrates with L<Log::Minimal>.
When Log::Minimal log functions like warnf, infof or debugf were used in PSGI Application,
this middleware adds requested URI to messages and prints that to psgi.errors stream.

IF $ENV{PLACK_ENV} is "development", Plack::Middleware::Log::Minimal enable Log::Minimal::COLOR automatically.

=head1 CONFIGURATIONS

=over 4

=item loglevel

Set the log level to output.

  enable 'Log::Level', loglevel => 'INFO';

Support levels are DEBUG,INFO,WARN,CRITICAL and NONE.
If NONE is set, no output. Default log level is DEBUG.

=item  autodump

Enable $Log::Minimal::AUTODUMP for serialize object or reference message.

=item formatter

Log format CODE reference. Default is.

  enable 'Log::Minimal',
      formatter => sub {
          my ($env, $time, $type, $message, $trace, $raw_message) = @_;
          sprintf "%s [%s] [%s] %s at %s\n", $time, $type, $env->{REQUEST_URI}, $message, $trace;
      });

You can filter log messages and add more request information to message in this formatter CODE ref.
$message includes Term color characters, If you want raw message text, use $raw_message.

=item encoding

Encoding name to display log. This middleware encode (utf8 flagged) text log messages automatically.
Default is utf8

=back

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

L<Log::Minimal>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



package Plack::Middleware::AxsLog;

use strict;
use warnings;
use 5.8.5;
use parent qw/Plack::Middleware/;
use Plack::Util;
use Time::HiRes qw/gettimeofday/;
use Plack::Util::Accessor qw/response_time combined ltsv format format_options compiled_format error_only long_response_time logger/;
use POSIX qw//;
use Time::Local qw//;
use HTTP::Status qw//;
use Apache::LogFormat::Compiler;

our $VERSION = '0.21';

sub prepare_app {
    my $self = shift;
    $self->combined(1) if ! defined $self->combined;
    $self->response_time(0) if ! defined $self->response_time;
    $self->error_only(0) if ! defined $self->error_only;
    $self->long_response_time(0) if ! defined $self->long_response_time;

    my ($format, %format_options);
    if ( $self->format ) {
        $format = $self->format;
        %format_options = %{ $self->format_options } if $self->format_options;
    }
    elsif ( $self->ltsv ) {
        $format = join "\t",
            qw!host:%h user:%u time:%t req:%r status:%>s size:%b referer:%{Referer}i ua:%{User-agent}i!;
        $format .= "\t" . 'taken:%D' if $self->response_time;
    }
    elsif ( $self->combined ) {
        $format = q!%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"!;
        $format .= ' %D' if $self->response_time;
    }
    else {
        $format = q!%h %l %u %t "%r" %>s %b!;
        $format .= ' %D' if $self->response_time;
    }

    $self->compiled_format(Apache::LogFormat::Compiler->new($format, %format_options)->code_ref);
}

sub call {
    my $self = shift;
    my($env) = @_;

    my $t0 = [gettimeofday];

    my $res = $self->app->($env);
    if ( ref($res) && ref($res) eq 'ARRAY' ) {
        my $length = Plack::Util::content_length($res->[2]);
        if ( defined $length ) {
            $self->log_line($t0, $env,$res,$length);
            return $res;
        }        
    }
    Plack::Util::response_cb($res, sub {
        my $res = shift;
        my $length = Plack::Util::content_length($res->[2]);
        if ( defined $length ) {
            $self->log_line($t0, $env,$res,$length);
            return;
        }
        return sub {
            my $chunk = shift;
            if ( ! defined $chunk ) {
                $self->log_line($t0, $env,$res,$length);
                return;
            }
            $length += length($chunk);
            return $chunk;
        };	
    });
}

sub log_line {
    my $self = shift;
    my ($t0, $env, $res, $length) = @_;

    my $elapsed = int(Time::HiRes::tv_interval($t0) * 1_000_000);

    unless (
         ( $self->{long_response_time} == 0 && !$self->{error_only} )
      || ( $self->{long_response_time} != 0 && $elapsed >= $self->{long_response_time} ) 
      || ( $self->{error_only} && HTTP::Status::is_error($res->[0]) ) 
    ) {
        return;
    }
    my $log_line = $self->{compiled_format}->(
        $env,
        $res,
        $length,
        $elapsed,
        $t0->[0],
    );

    if ( ! $self->{logger} ) {
        $env->{'psgi.errors'}->print($log_line."\n");
    }
    else {
        $self->{logger}->($log_line."\n");
    }
}


1;
__END__

=head1 NAME

Plack::Middleware::AxsLog - Yet another AccessLog Middleware

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
      enable 'AxsLog',
        combined => 1,
        response_time => 1,
        error_only => 1,
      $app
  };

=head1 DESCRIPTION

Alternative implementation of Plack::Middleware::AccessLog. 
This middleware supports response_time and content_length calculation 
AxsLog also can set condition to display logs by response_time and status code.

Originally, AxsLog was faster AccessLog implementation. But PM::AccessLog became 
to using same access-log generator module L<Apache::LogFormat::Compiler>. 
Two middlewares have almost same performance now.

=head1 ARGUMENTS

=over 4

=item combined: Bool

log format. if disabled, "common" format used. default: 1 (combined format used)

common (Common Log Format) format is

  %h %l %u %t \"%r\" %>s %b
  
  => 127.0.0.1 - - [23/Aug/2012:00:52:15 +0900] "GET / HTTP/1.0" 200 645

combined (NCSA extended/combined log format) format is

  %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"
  
  => 127.0.0.1 - - [23/Aug/2012:00:52:15 +0900] "GET / HTTP/1.1" 200 645 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/21.0.1180.79 Safari/537.1"


=item ltsv: Bool

use ltsv log format. default: 0

LTSV (Labeled Tab-separated Values) format is

  host:%h<TAB>user:%u<TAB>time:%t<TAB>req:%r<TAB>status:%>s<TAB>size:%b<TAB>referer:%{Referer}i<TAB>ua:%{User-agent}i
  
  => host:127.0.0.1<TAB>user:-<TAB>time:[23/Aug/2012:00:52:15 +0900]<TAB>req:GET / HTTP/1.1<TAB>status:200<TAB>size:645<TAB>"referer:-<TAB>ua:Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/21.0.1180.79 Safari/537.1

See also L<http://ltsv.org/>

=item format: String

A format string.

  builder {
      enable 'AxsLog', 
          format => '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i" %D';
      $app
  };

See details on perldoc L<Apache::LogFormat::Compiler>

=item format_options

This variable is passed to L<Apache::LogFormat::Compiler>. You can add char_handlers
and block_handlers with this middleware.

    enable 'AxsLog', 
        format => '%z %{X_MYAPP_VARIABLE}Z', 
        format_options => +{
            char_handlers => +{
                'z' => sub { 'z' },
            },
            block_handlers => +{
                'Z' => sub { 'Z' },
            },
        };

=item response_time: Bool

Adds time taken to serve the request. default: 0. This args effect to common, combined and ltsv format.

=item error_only: Bool

Display logs if response status is error (4xx or 5xx). default: 0

=item long_response_time: Int (microseconds)

Display log if time taken to serve the request is above long_response_time. default: 0 (all request logged)

=item logger: Coderef

Callback to print logs. default:none ( output to psgi.errors )

  use File::RotateLogs;
  my $logger = File::RotateLogs->new();

  builder {
      enable 'AxsLog',
        logger => sub { $logger->print(@_) }
      $app
  };

=back

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

L<Plack::Middleware::AccessLog>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

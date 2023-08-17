package Apache::LogFormat::Compiler;

use strict;
use warnings;
use 5.008001;
use Carp;
use POSIX::strftime::Compiler qw//;
use constant {
    ENVS => 0,
    RES => 1,
    LENGTH => 2,
    REQTIME => 3,
    TIME => 4,
};

our $VERSION = '0.36';

# copy from Plack::Middleware::AccessLog
our %formats = (
    common => '%h %l %u %t "%r" %>s %b',
    combined => '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"',
);

sub _safe {
    my $string = shift;
    return unless defined $string;
    $string =~ s/([^[:print:]])/"\\x" . unpack("H*", $1)/eg;
    return $string;
}

sub _string {
    my $string = shift;
    return '-' if ! defined $string;
    return '-' if ! length $string;
    $string =~ s/([^[:print:]])/"\\x" . unpack("H*", $1)/eg;
    return $string;
}

sub header_get {
    my ($headers, $key) = @_;
    $key = lc $key;
    my @headers = @$headers; # copy
    my $value;
    while (my($hdr, $val) = splice @headers, 0, 2) {
        if ( lc $hdr eq $key ) {
            $value = $val;
            last;
        }
    }
    return $value;
}

my $psgi_reserved = { CONTENT_LENGTH => 1, CONTENT_TYPE => 1 };

my $block_handler = sub {
    my($block, $type, $extra) = @_;
    my $cb;
    if ($type eq 'i') {
        $block =~ s/-/_/g;
        $block = uc($block);
        $block = "HTTP_${block}" unless $psgi_reserved->{$block};
        $cb =  q!_string($_[ENVS]->{'!.$block.q!'})!;
    } elsif ($type eq 'o') {
        $cb =  q!_string(header_get($_[RES]->[1],'!.$block.q!'))!;
    } elsif ($type eq 't') {
        $cb =  q!"[" . POSIX::strftime::Compiler::strftime('!.$block.q!', @lt) . "]"!;
    } elsif (exists $extra->{$type}) {
        $cb =  q!_string($extra_block_handlers->{'!.$type.q!'}->('!.$block.q!',$_[ENVS],$_[RES],$_[LENGTH],$_[REQTIME]))!;
    } else {
        Carp::croak("{$block}$type not supported");
        $cb = "-";
    }
    return q|! . | . $cb . q|
      . q!|;
};

our %char_handler = (
    '%' => q!'%'!,
    h => q!($_[ENVS]->{REMOTE_ADDR} || '-')!,
    l => q!'-'!,
    u => q!($_[ENVS]->{REMOTE_USER} || '-')!,
    t => q!'[' . $t . ']'!,
    r => q!_safe($_[ENVS]->{REQUEST_METHOD}) . " " . _safe($_[ENVS]->{REQUEST_URI}) .
                       " " . $_[ENVS]->{SERVER_PROTOCOL}!,
    s => q!$_[RES]->[0]!,
    b => q!(defined $_[LENGTH] ? $_[LENGTH] : '-')!,
    T => q!(defined $_[REQTIME] ? int($_[REQTIME]/1_000_000) : '-')!,
    D => q!(defined $_[REQTIME] ? $_[REQTIME] : '-')!,
    v => q!($_[ENVS]->{SERVER_NAME} || '-')!,
    V => q!($_[ENVS]->{HTTP_HOST} || $_[ENVS]->{SERVER_NAME} || '-')!,
    p => q!$_[ENVS]->{SERVER_PORT}!,
    P => q!$$!,
    m => q!_safe($_[ENVS]->{REQUEST_METHOD})!,
    U => q!_safe($_[ENVS]->{PATH_INFO})!,
    q => q!(($_[ENVS]->{QUERY_STRING} ne '') ? '?' . _safe($_[ENVS]->{QUERY_STRING}) : '' )!,
    H => q!$_[ENVS]->{SERVER_PROTOCOL}!,

);

my $char_handler = sub {
    my ($char, $extra) = @_;
    my $cb = $char_handler{$char};
    if (!$cb && exists $extra->{$char}) {
        $cb = q!_string($extra_char_handlers->{'!.$char.q!'}->($_[ENVS],$_[RES],$_[LENGTH],$_[REQTIME]))!;
    }
    unless ($cb) {
        Carp::croak "\%$char not supported.";
        return "-";
    }
    q|! . | . $cb . q|
      . q!|;
};

sub new {
    my $class = shift;

    my $fmt = shift || "combined";
    $fmt = $formats{$fmt} if exists $formats{$fmt};

    my %opts = @_;

    my ($code_ref, $code) = compile($fmt, $opts{block_handlers} || {}, $opts{char_handlers} || {});
    bless [$code_ref, $code], $class;
}

sub compile {
    my $fmt = shift;
    my $extra_block_handlers = shift;
    my $extra_char_handlers = shift;
    $fmt =~ s/!/\\!/g;
    $fmt =~ s!
        (?:
             \%\{(.+?)\}([a-zA-Z]) |
             \%(?:[<>])?([a-zA-Z\%])
        )
    ! $1 ? $block_handler->($1, $2, $extra_block_handlers) : $char_handler->($3, $extra_char_handlers) !egx;
    
    my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    my $c = {};
    $fmt = q~sub {
        $_[TIME] = time() if ! defined $_[TIME];
        my @lt = localtime($_[TIME]);
        if ( ! exists $c->{tz_cache} || ! exists $c->{isdst_cache} || $lt[8] != $c->{isdst_cache} ) {
            $c->{tz_cache} = POSIX::strftime::Compiler::strftime('%z',@lt);
            $c->{isdst_cache} = $lt[8];
        }    
        my $t = sprintf '%02d/%s/%04d:%02d:%02d:%02d %s', $lt[3], $abbr[$lt[4]], $lt[5]+1900,
          $lt[2], $lt[1], $lt[0], $c->{tz_cache};
        q!~ . $fmt . q~!
    }~;
    my $code_ref = eval $fmt; ## no critic
    die $@ . "\n===\n" . $fmt if $@;
    wantarray ? ($code_ref, $fmt) : $code_ref;
}

sub log_line {
    my $self = shift;
    $self->[0]->(@_) . "\n";
}

sub code {
    my $self = shift;
    $self->[1];
}

sub code_ref {
    my $self = shift;
    $self->[0];
}

1;
__END__

=encoding utf8

=head1 NAME

Apache::LogFormat::Compiler - Compile a log format string to perl-code 

=head1 SYNOPSIS

  use Apache::LogFormat::Compiler;

  my $log_handler = Apache::LogFormat::Compiler->new("combined");
  my $log = $log_handler->log_line(
      $env,
      $res,
      $length,
      $reqtime,
      $time
  );

=head1 DESCRIPTION

Compile a log format string to perl-code. For faster generation of access_log lines.

=head1 METHOD

=over 4

=item new($fmt:String)

Takes a format string (or a preset template C<combined> or C<custom>)
to specify the log format. This module implements a subset of
L<Apache's LogFormat templates|http://httpd.apache.org/docs/2.0/mod/mod_log_config.html>:

   %%    a percent sign
   %h    REMOTE_ADDR from the PSGI environment, or -
   %l    remote logname not implemented (currently always -)
   %u    REMOTE_USER from the PSGI environment, or -
   %t    [local timestamp, in default format]
   %r    REQUEST_METHOD, REQUEST_URI and SERVER_PROTOCOL from the PSGI environment
   %s    the HTTP status code of the response
   %b    content length of the response
   %T    custom field for handling times in subclasses
   %D    custom field for handling sub-second times in subclasses
   %v    SERVER_NAME from the PSGI environment, or -
   %V    HTTP_HOST or SERVER_NAME from the PSGI environment, or -
   %p    SERVER_PORT from the PSGI environment
   %P    the worker's process id
   %m    REQUEST_METHOD from the PSGI environment
   %U    PATH_INFO from the PSGI environment
   %q    QUERY_STRING from the PSGI environment
   %H    SERVER_PROTOCOL from the PSGI environment

In addition, custom values can be referenced, using C<%{name}>,
with one of the mandatory modifier flags C<i>, C<o> or C<t>:

   %{variable-name}i    HTTP_VARIABLE_NAME value from the PSGI environment
   %{header-name}o      header-name header in the response
   %{time-format]t      localtime in the specified strftime format

=item log_line($env:HashRef, $res:ArrayRef, $length:Integer, $reqtime:Integer, $time:Integer): $log:String

Generates log line.

  $env      PSGI env request HashRef
  $res      PSGI response ArrayRef
  $length   Content-Length
  $reqtime  The time taken to serve request in microseconds. optional
  $time     Time the request was received. optional. If $time is undefined. current timestamp is used.

Sample psgi 

  use Plack::Builder;
  use Time::HiRes;
  use Apache::LogFormat::Compiler;

  my $log_handler = Apache::LogFormat::Compiler->new(
      '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i" %D'
  );
  my $compile_log_app = builder {
      enable sub {
          my $app = shift;
          sub {
              my $env = shift;
              my $t0 = [gettimeofday];
              my $res = $app->();
              my $reqtime = int(Time::HiRes::tv_interval($t0) * 1_000_000);
              $env->{psgi.error}->print($log_handler->log_line(
                  $env,$res,6,$reqtime, $t0->[0]));
          }
      };
      $app
  };

=back

=head1 ABOUT POSIX::strftime::Compiler

This module uses L<POSIX::strftime::Compiler> for generate datetime string. POSIX::strftime::Compiler provides GNU C library compatible strftime(3). But this module will not affected by the system locale. This feature is useful when you want to write loggers, servers and portable applications.

=head1 ADD CUSTOM FORMAT STRING

Apache::LogFormat::Compiler allows one to add a custom format string

  my $log_handler = Apache::LogFormat::Compiler->new(
      '%z %{HTTP_X_FORWARDED_FOR|REMOTE_ADDR}Z',
      char_handlers => +{
          'z' => sub {
              my ($env,$req) = @_;
              return $env->{HTTP_X_FORWARDED_FOR};
          }
      },
      block_handlers => +{
          'Z' => sub {
              my ($block,$env,$req) = @_;
              # block eq 'HTTP_X_FORWARDED_FOR|REMOTE_ADDR'
              my ($main, $alt) = split('\|', $args);
              return exists $env->{$main} ? $env->{$main} : $env->{$alt};
          }
      },
  );

Any single letter can be used, other than those already defined by Apache::LogFormat::Compiler.
Your sub is called with two or three arguments: the content inside the C<{}>
from the format (block_handlers only), the PSGI environment (C<$env>),
and the ArrayRef of the response. It should return the string to be logged.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=head1 SEE ALSO

L<Plack::Middleware::AccessLog>, L<http://httpd.apache.org/docs/2.2/mod/mod_log_config.html>

=head1 LICENSE

Copyright (C) Masahiro Nagano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

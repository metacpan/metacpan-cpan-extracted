package Plack::Middleware::StackTrace::RethrowFriendly;
use strict;
use warnings;

# core
use Scalar::Util 'refaddr';
use MIME::Base64 qw(encode_base64);

# cpan
use parent qw(Plack::Middleware::StackTrace);
use Try::Tiny;

our $VERSION = "0.03";

sub call {
    my($self, $env) = @_;

    my ($last_key, %seen);
    local $SIG{__DIE__} = sub {
        my $key = _make_key($_[0]);
        my $list = $seen{$key} || [];

        # If we get the same keys, the exception may be rethrown and
        # we keep the original stacktrace.
        push @$list, $Plack::Middleware::StackTrace::StackTraceClass->new(
            indent => 1,
            message => munge_error($_[0], [ caller ]),
            ignore_package => __PACKAGE__,
            no_refs => 1,
        );
        $seen{$key} = $list;
        $last_key = $key;

        die @_;
    };

    my $caught;
    my $res = try {
        $self->app->($env);
    } catch {
        $caught = $_;
        _error('text/plain', $caught, 'no_trace');
    };

    my $trace = $self->force ? $seen{$last_key} : $seen{_make_key($caught)};
    $trace ||= [];
    if (scalar @$trace && $self->should_show_trace($caught, $res)) {
        my $text = $trace->[0]->as_string;
        my $html = @$trace > 1
            ? _multi_trace_html(@$trace) : $trace->[0]->as_html;
        $env->{'plack.stacktrace.text'} = $text;
        $env->{'plack.stacktrace.html'} = $html;
        $env->{'psgi.errors'}->print($text) unless $self->no_print_errors;
        $res = ($env->{HTTP_ACCEPT} || '*/*') =~ /html/
            ? _error('text/html', $html)
            : _error('text/plain', $text);
    }
    # break %seen here since $SIG{__DIE__} holds the ref to it, and
    # $trace has refs to Standalone.pm's args ($conn etc.) and
    # prevents garbage collection to be happening.
    undef %seen;

    return $res;
}

sub should_show_trace {
    my ($self, $err, $res) = @_;
    return 1 if $err;
    return $self->force && ref $res eq 'ARRAY' && $res->[0] == 500;
}

sub no_trace_error { Plack::Middleware::StackTrace::no_trace_error(@_) }
sub munge_error { Plack::Middleware::StackTrace::munge_error(@_) }
sub utf8_safe { Plack::Middleware::StackTrace::utf8_safe(@_) }

sub _make_key {
    my ($val) = @_;
    if (!defined($val)) {
        return 'undef';
    } elsif (ref($val)) {
        return 'ref:' . refaddr($val);
    } else {
        return "str:$val";
    }
}

sub _error {
    my ($type, $content, $no_trace) = @_;
    $content = utf8_safe($content);
    $content = no_trace_error($content) if $no_trace;
    return [ 500, [ 'Content-Type' => "$type; charset=utf-8" ], [ $content ] ];
}

sub _multi_trace_html {
    my (@trace) = @_;

    require Devel::StackTrace::AsHTML;
    my $msg = Devel::StackTrace::AsHTML::encode_html(
        $trace[0]->frame(0)->as_string(1),
    );

    my @data_uris = map { _trace_as_data_uri($_) } @trace;
    my @links = map {
        sprintf
            '<a class="link" href="%s" target="trace">#%s</a>',
            $data_uris[$_],
            $_;
    } (0..$#data_uris);

    my $css = << '----';
body {
  height: 100%;
  margin: 0;
  padding: 0;
}
div#links {
  z-index: 100;
  position: absolute;
  top: 0;
  height: 30px;
}
#content {
  z-index: 50;
  position: absolute;
  top: 0;
  height: 100%;
  width: 100%;
  margin: 0;
  padding: 30px 0 4px 0;
  box-sizing: border-box;
}
iframe#trace {
  border: none;
  padding: 0;
  margin: 0;
  height: 100%;
  width: 100%;
}
a.selected {
  color: #000;
  font-weight: bold;
  text-decoration: none;
}
----

    sprintf << '----', $msg, $css, join(' ', @links), $data_uris[0];
<!DOCTYPE html>
<html>
<head>
<title>Error: %s</title>
<style type="text/css">
%s
</style>
<script>
(function(d) {
  var select = function() {
    Array.prototype.forEach.call(d.querySelectorAll('a.link'), function(a) {
        a.className = a.className.replace(/\s*\bselected\b/, '');
    });
    this.className += ' selected';
  };
  d.addEventListener('DOMContentLoaded', function() {
    Array.prototype.forEach.call(d.querySelectorAll('a.link'), function(a) {
        a.addEventListener('click', select);
    });
    select.call(d.querySelector('a.link'));
  });
})(document);
</script>
</head>
<body>
<div id="links">
  Throws: %s
</div>
<div id="content">
  <iframe src="%s" id="trace" name="trace"></iframe>
</div>
</body>
</html>
----
}

sub _trace_as_data_uri ($) {
    my $html = $_[0]->as_html;
    return 'data:text/html;charset=utf-8;base64,'.encode_base64($html);
}

1;
__END__

=head1 NAME

Plack::Middleware::StackTrace::RethrowFriendly - Display the original stack trace for rethrown errors

=head1 SYNOPSIS

  use Plack::Builder;
  builder {
      enable "StackTrace::RethrowFriendly";
      $app;
  };

=head1 DESCRIPTION

This middleware is the same as L<Plack::Middleware::StackTrace> except
that additional information for rethrown errors are available for HTML
stack trace.

If you catch (C<eval> or C<try>-C<catch> for example) an error and
rethrow (C<die> or C<croak> for example) it, all the errors including
rethrown ones are visible through the throwing point selector at the
top of the HTML.

For example, consider the following code.

  sub fail {
      die 'foo';
  }

  sub another {
      fail();
  }

  builder {
      enable 'StackTrace';

      sub {
          eval { fail() }; # (1)
          another();       # (2)

          return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ];
      };
  };

L<Plack::Middleware::StackTrace> blames (1) since it is the first
place where C<'foo'> is raised.  This behavior may be misleading if
the real culprit was something done in C<another>.

C<Plack::Middleware::StackTrace::RethrowFriendly> displays stack
traces of both (1) and (2) in each page and (1) is selected by
default.

=head1 SEE ALSO

L<Plack::Middleware::StackTrace>

=head1 LICENSE

Copyright (C) TOYAMA Nao and INA Lintaro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

TOYAMA Nao E<lt>nanto@moon.email.ne.jpE<gt>

INA Lintaro E<lt>tarao.gnn@gmail.comE<gt>

=cut

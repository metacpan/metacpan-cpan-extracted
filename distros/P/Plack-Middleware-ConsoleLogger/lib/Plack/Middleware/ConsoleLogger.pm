package Plack::Middleware::ConsoleLogger;
use strict;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(group);

use 5.008001;
our $VERSION = '0.05';

use JavaScript::Value::Escape;

sub call {
    my($self, $env) = @_;

    my @logs;
    $env->{'psgix.logger'} = sub {
        my $args = shift;
        push @logs, $args;
        # TODO cascade?
    };

    $self->response_cb($self->app->($env), sub {
        my $res = shift;

        if (Plack::Util::header_get($res->[1], 'Content-Type') =~ /html/) {
            return sub {
                my $chunk = shift;
                return unless defined $chunk;
                $chunk =~ s!</body>!$self->generate_js(\@logs) . "</body>"!ei;
                return $chunk;
            };
        }
    });
}

sub generate_js {
    my($self, $logs) = @_;

    my $js = q(<script type="text/javascript">);
    $js .= q/console.group("/ . $self->group . q/");/ if $self->group;

    for my $log (@$logs) {
        my $level = $self->_validate_level($log->{level});
        $level = "error" if $level eq 'fatal';
        my $message = javascript_value_escape($log->{message});
        $message =~ s/([^\x00-\xff])/sprintf "\\u%04x", ord($1)/eg;
        utf8::downgrade($message);
        $js .= qq/console.$level("$message");/;
    }

    $js .= "console.groupEnd();" if $self->group;
    $js .= "</script>";
    $js;
}

sub _validate_level {
    my ($self, $level) = @_;
    return "debug" if !$level;
    if (grep {/$level/} (qw/warn debug error info fatal/)) {
        return $level;
    }else{
        return "debug";
    }
}

1;

__END__

=head1 NAME

Plack::Middleware::ConsoleLogger - Write logs to Firebug or Webkit Inspector

=head1 SYNOPSIS

  enable "ConsoleLogger";

=head1 DESCRIPTION

This middleware captures logs from PSGI applications and plack
middleware components and makes them available to see on JavaScript
console for Firebug and Webkit Inspector.

=head1 CONFIGURATIONS

=over 4

=item group

Set the group to use with console log. Defaults to undef.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Rack::FirebugLogger

=cut



package OpenTracing::Integration::System;

use strict;
use warnings;

our $VERSION = '1.004'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

no indirect;
use utf8;

=encoding utf8

=head1 NAME

OpenTracing::Integration::System - support tracing system calls

=head1 SYNOPSIS

To create trace each time a system is called:

  use OpenTracing::Any qw($tracer);
  use OpenTracing::Integration qw(System);
  system("ls");

Additionally, this modules supports span context propagation using the OPENTRACING_CONTEXT environment variable.
Any call to system will fill the environment variable OPENTRACING_CONTEXT=<traceid>:<id> in order to propagate
down the context to other programs.

Of course, this requires that the child process implements extracting the span from that variable.
Luckily, this perl module can do that for you using:

  use OpenTracing::Any qw($tracer);
  use OpenTracing::Integration qw(System);

  my $span_context = OpenTracing::Integration::System->extract_context();
  my $span;
  if ($span_context)
  {
    $span = $tracer->span(operation_name => 'main', references => [$tracer->child_of($span_context)]);
  }
  else
  {
    $span = $tracer->span(operation_name => 'main');
  }

=head1 DESCRIPTION

See L<OpenTracing::Integration> for more details.

=cut

use Syntax::Keyword::Try;
use Role::Tiny::With;
use OpenTracing::Any qw($tracer);

with qw(OpenTracing::Integration);

my $loaded;

sub load {
    my ($class, $load_deps) = @_;
    unless($loaded++) {

        *CORE::GLOBAL::system = sub {
            my @args = @_;

            my $span = $tracer->span(operation_name => "system");
            $span->tag('command' => join(" ", @args));
            $class->inject_context($span);

            CORE::system(@args);

            if ($? == -1) {
                my $message = "failed to execute: $!";
                $span->tag('error' => 'true');
                $span->log($message);
            } elsif ($? & 127) {
                my $message = sprintf "child died with signal %d, %s coredump", ($? & 127),  ($? & 128) ? 'with' : 'without';
                $span->tag('error' => 'true');
                $span->log($message);
            } else {
                my $exitcode = ($? >> 8);
                $span->tag('exitcode' => $exitcode);
                if ($exitcode > 0)
                {
                    $span->tag('error' => 'true');
                    $span->log("exitcode greater than 0");
                }
            }


            return $?;
        };
    }
}

sub inject_context {
    my ($class, $span) = @_;

    # Propagate down the context to child process
    my %result = %{ $tracer->inject($span->span) };
    $ENV{OPENTRACING_CONTEXT} = $result{trace_id} . ":" . $result{id};
}

sub extract_context {
    my $class = shift;
    return unless $ENV{OPENTRACING_CONTEXT};

    my ($trace_id, $id) = split(':', $ENV{OPENTRACING_CONTEXT});
    delete $ENV{OPENTRACING_CONTEXT};

    return $tracer->extract({
        trace_id => $trace_id,
        id => $id
    });
}

1;

__END__

=head1 AUTHOR

Francis Tremblay C<< francis.tremblay@unity3d.com >>

=head1 LICENSE

Copyright Unity 2021. Licensed under the same terms as Perl itself.

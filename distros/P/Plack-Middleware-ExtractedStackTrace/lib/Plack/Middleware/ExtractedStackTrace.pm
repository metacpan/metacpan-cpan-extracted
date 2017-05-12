package Plack::Middleware::ExtractedStackTrace;

use strict;
use warnings;

use parent qw/Plack::Middleware/;

our $VERSION = '1.000000';

use Devel::StackTrace;
use Devel::StackTrace::Extract qw( extract_stack_trace );
use Devel::StackTrace::AsHTML;
use Try::Tiny qw( catch try );
use Plack::Util::Accessor qw( force no_print_errors );

## no critic (ValuesAndExpressions::ProhibitAccessOfPrivateData)

sub call {
    my ( $self, $env ) = @_;

    my $trace;
    my $caught;

    my $res = try {
        $self->app->($env);
    }
    catch {
        $caught = $_;
        [
            500,
            [ 'Content-Type', 'text/plain; charset=utf-8' ],
            [ _no_trace_error( _utf8_safe($caught) ) ]
        ];
    };

    $trace = extract_stack_trace($caught) if $caught;

    if (
        $trace
        && ( $caught
            || ( $self->force && ref $res eq 'ARRAY' && $res->[0] == 500 ) )
        ) {
        my $text = $trace->as_string;
        my $html = $trace->as_html;
        $env->{'plack.stacktrace.text'} = $text;
        $env->{'plack.stacktrace.html'} = $html;
        $env->{'psgi.errors'}->print($text) unless $self->no_print_errors;
        if ( ( $env->{HTTP_ACCEPT} || '*/*' ) =~ /html/ ) {
            $res = [
                500,
                [ 'Content-Type' => 'text/html; charset=utf-8' ],
                [ _utf8_safe($html) ]
            ];
        }
        else {
            $res = [
                500,
                [ 'Content-Type' => 'text/plain; charset=utf-8' ],
                [ _utf8_safe($text) ]
            ];
        }
    }

    return $res;
}

sub _no_trace_error {
    my $msg = shift;
    chomp($msg);

    return <<"EOF";
The application raised the following error:

  $msg

For which no stack trace was captured.
EOF
}

sub _utf8_safe {
    my $str = shift;

    # NOTE: I know messing with utf8:: in the code is WRONG, but
    # because we're running someone else's code that we can't
    # guarantee which encoding an exception is encoded, there's no
    # better way than doing this. The latest Devel::StackTrace::AsHTML
    # (0.08 or later) encodes high-bit chars as HTML entities, so this
    # path won't be executed.
    ## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
    ## no critic (Modules::RequireExplicitInclusion)
    if ( utf8::is_utf8($str) ) {
        utf8::encode($str);
    }
    ## use critic

    $str;
}

1;

=pod

=head1 NAME

Plack::Middleware::ExtractedStackTrace - Displays stack trace from your exception objects when your app dies

=head1 VERSION

version 1.000000

=head1 ACKNOWLEDGEMENTS

Parts of this code (in this module file only) were derived from
L<Plack::MiddleWare::StackTrace>, part of the Plack distribution. Copyright for
code derived from Plack resides with the original holder.

=head1 AUTHOR

Mark Fowler <mfowler@maxmind.com>

=head1 CONTRIBUTOR

=for stopwords Olaf Alders

Olaf Alders <oalders@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Displays stack trace from your exception objects when your app dies



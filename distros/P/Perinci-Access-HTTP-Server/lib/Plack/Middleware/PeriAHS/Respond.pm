package Plack::Middleware::PeriAHS::Respond;

our $DATE = '2016-03-16'; # DATE
our $VERSION = '0.60'; # VERSION

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(
                                add_text_tips
                                enable_logging
                                pass_psgi_env
                        );

use Perinci::AccessUtil qw(insert_riap_stuffs_to_res);
use Data::Clean::JSON;
use Log::Any::Adapter;
use Perinci::Result::Format 0.31;
use Scalar::Util qw(blessed);
use Time::HiRes qw(gettimeofday);

# we're doing the cleansing of Riap response ourselves instead of delegating to
# Perinci::Result::Format, because we might need the cleansed elsewhere (e.g.
# when doing access logging).
my $cleanser = Data::Clean::JSON->get_cleanser;

# to avoid sending colored YAML/JSON output
$Perinci::Result::Format::Enable_Decoration = 0;

sub prepare_app {
    my $self = shift;

    $self->{add_text_tips}  //= 1;
    $self->{enable_logging} //= 1;
    $self->{pass_psgi_env}  //= 0;
}

sub format_result {
    my ($self, $rres, $env) = @_;

    # turn off Text::ANSITable stuffs that make things look nice in terminals
    # but ugly in browser
    local $ENV{UNICODE}   = 0;
    local $ENV{COLOR}     = 0;
    local $ENV{BOX_CHARS} = 0;

    my $midpr = $env->{"middleware.PeriAHS.ParseRequest"};
    my $rreq = $env->{"riap.request"};

    # adjust entity uri's against riap_uri_prefix configuration
    if ($rreq->{action} eq 'info' && $rres->[0] == 200) {
        for ($rres->[2]{uri}) {
            s/\A\Q$midpr->{riap_uri_prefix}//;
        }
    }

    my $fmt = $rreq->{fmt} // $env->{'periahs.default_fmt'} // 'json';

    my $formatter;
    for ($fmt, "json") { # fallback to json if unknown format
        $formatter = $Perinci::Result::Format::Formats{$_};
        if ($formatter) {
            $log->tracef("formatting result using %s", $formatter);
            $fmt = $_;
            last;
        }
    }

    # do Riap 1.2 stuffs, but only encode binary result if we're sending as
    # JSON, because the other formats are binary safe
    insert_riap_stuffs_to_res($rres, $rreq->{v}, undef, $fmt =~ /json/);

    my $ct = $formatter->[1];

    my $fres = Perinci::Result::Format::format($rres, $fmt);

    if ($fmt =~ /^json/ && defined($env->{"periahs.jsonp_callback"})) {
        $fres = $env->{"periahs.jsonp_callback"}."($fres)";
    }

    if ($self->{add_text_tips} && $fmt =~ /^text/ && !ref($fres)) {
        my @tips;
        my $pf = $midpr->{parse_form};
        if ($rreq->{action} eq 'list') {
            my (@f, @p);
            if ($rreq->{detail}) {
                @f = grep {$_->{type} eq 'function'} @{$rres->[2]};
                @p = grep {$_->{type} eq 'package' } @{$rres->[2]};
            }
            if (@f) {
                local $rreq->{uri} = "pl:$midpr->{riap_uri_prefix}".$f[rand(@f)]{uri};
                push @tips, "* To call a function, try:\n    ".
                    $midpr->{get_http_request_url}->($midpr, $env, $rreq);
                if ($pf) {
                    push @tips, "* Function arguments can be given via GET/POST params or JSON hash in req body";
                } else {
                    push @tips, "* Function arguments can be given via JSON hash in request body";
                }
                $rreq->{uri} = "pl:$midpr->{riap_uri_prefix}".$f[rand(@f)]{uri};
                my $url = $midpr->{get_http_request_url}->($midpr, $env, $rreq);
                push @tips, "* To find out which arguments a function supports, try:\n    ".
                    ($pf ? "$url?-riap-action=meta" : "curl -H 'x-riap-action: meta' $url");
            }
            if (@p) {
                local $rreq->{uri} = "pl:$midpr->{riap_uri_prefix}".$p[rand(@p)]{uri};
                push @tips, "* To list the content of a (sub)package, try:\n    ".
                    $midpr->{get_http_request_url}->($midpr, $env, $rreq);
            }
            if ($rreq->{detail} && @{$rres->[2]}) {
                local $rreq->{uri} = "pl:$midpr->{riap_uri_prefix}".$rres->[2][rand(@{ $rres->[2] })]{uri};
                my $url = $midpr->{get_http_request_url}->($midpr, $env, $rreq);
                push @tips, "* To find out all available actions on an entity, try:\n    ".
                    ($pf ? "$url?-riap-action=actions" : "curl -H 'x-riap-action: actions' $url");
            }
            push @tips,"* This server uses Riap protocol for great autodiscoverability, for more info:\n".
                "    https://metacpan.org/module/Riap";
        }
        if (@tips) {
            $fres .= "\nTips:\n".join("\n", @tips)."\n";
        }
    }

    ($fres, $ct);
}
my %str_levels = qw(1 critical 2 error 3 warning 4 info 5 debug 6 trace);

sub call {
    $log->tracef("=> PeriAHS::Respond middleware");

    my ($self, $env) = @_;

    die "This middleware needs psgi.streaming support"
        unless $env->{'psgi.streaming'};

    my $rreq = $env->{"riap.request"};
    my $pa   = $env->{"periahs.riap_client"}
        or die "\$env->{'periahs.riap_client'} not defined, ".
            "perhaps ParseRequest middleware has not run?";

    return sub {
        my $respond = shift;

        my $writer;
        my $loglvl  = $self->{enable_logging} ? ($rreq->{'loglevel'} // 0) : 0;
        my $rres; #  short for riap response
        $env->{'periahs.start_action_time'} = [gettimeofday];
        if ($loglvl > 0) {
            $writer = $respond->([
                200, ["Content-Type" => "text/plain",
                      "X-Riap-V" => "1.1.22",
                      "X-Riap-Logging" => 1]]);
            Log::Any::Adapter->set(
                {lexically=>\my $lex},
                "Callback",
                min_level => $str_levels{$loglvl} // 'warning',
                logging_cb => sub {
                    my ($method, $self, $format, @params) = @_;
                    my $msg0 = join(
                        "",
                        "[$method][", scalar(localtime), "] $format\n",
                    );
                    my $msg = join(
                        "",
                        "l", length($msg0), " ",
                        $msg0);
                    $writer->write($msg);
                },
            );
            {
                local $rreq->{args}{-env} = $env if $self->{pass_psgi_env};
                $rres = $pa->request($rreq->{action} => $rreq->{uri}, $rreq);
            }
        } else {
            {
                local $rreq->{args}{-env} = $env if $self->{pass_psgi_env};
                $rres = $pa->request($rreq->{action} => $rreq->{uri}, $rreq);
            }
        }
        $rres = $cleanser->clone_and_clean($rres);
        $env->{'periahs.finish_action_time'} = [gettimeofday];

        $env->{'riap.response'} = $rres;
        my ($fres, $ct) = $self->format_result($rres, $env);

        if ($writer) {
            $writer->write("r" . length($fres) . " " . $fres);
            $writer->close;
        } else {
            $respond->([
                200, ["Content-Type" => $ct,
                      "X-Riap-V" => "1.1.22",
                  ], [$fres]]);
        }
    };
}

1;
# ABSTRACT: Send Riap request to Riap server and send the response to client

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::PeriAHS::Respond - Send Riap request to Riap server and send the response to client

=head1 VERSION

This document describes version 0.60 of Plack::Middleware::PeriAHS::Respond (from Perl distribution Perinci-Access-HTTP-Server), released on 2016-03-16.

=head1 SYNOPSIS

 # in your app.psgi
 use Plack::Builder;

 builder {
     enable "PeriAHS::Respond";
 };

=head1 DESCRIPTION

This middleware sends Riap request (C<$env->{"riap.request"}>) to Riap client
(C<Perinci::Access::*> object, stored in C<$env->{"periahs.riap_client"}> by
PeriAHS::ParseRequest middleware, thus this middleware requires the
PeriAHS::ParseRequest middleware), format the result, and send it to client.
This middleware is the one that sends response to client and should be put as
the last middleware after all the parsing, authentication, and authorization
middlewares.

The result will also be put in C<$env->{"riap.response"}>.

=head2 How logging works

If Riap request key C<loglevel> is set to larger than 0 and the server chooses
to support logging, the server will encode each part with:

Log message:

 "l" + <number-of-bytes> + " " + <log message>
   example: l56 [trace][Thu Apr  4 06:41:09 2013] this is a log message!

Part of Riap response:

 "r" + <number-of-bytes> + " " + <data>
  example: r9 [200,"OK"]

So the actual HTTP response body might be something like this (can be sent by
the server in HTTP chunks, so that complete log messages can be displayed before
the whole Riap response is received):

 l56 [trace][Thu Apr  4 06:41:09 2013] this is a log message!
 l58 [trace][Thu Apr  4 06:41:09 2013] this is another log msg!
 r9 [200,"OK"]

Developer note: additional parameter in the future can be in the form of e.g.:

 "l" + <number-of-bytes> + ("," + <additional-param> )* + " "

=for Pod::Coverage .*

=head1 CONFIGURATIONS

=over

=item * add_text_tips => BOOL (default: 1)

If set to 1, then when output format is C<text> or C<text-pretty>, additional
text tips can be added at the end of response. This helps autodiscoverability:
user can just start using something like:

 % curl http://host/api/
 ...

 Tips:
 * To call a function, try:
     http://host/api/func1
 * Function arguments can be given via GET/POST parameters or JSON request body
 * To find out which arguments a function supports, try:
     http://host/api/func1?-riap-action=meta
 * To list subpackages, try:
     http://host/api/SubModule/
 * To find out all available actions on an entity, try:
     http://host/api/SubModule?-riap-action=actions
 * This server uses Riap protocol for great autodiscoverability, for more info:
     https://metacpan.org/module/Riap

=item * enable_logging => BOOL (default: 1)

If client sends Riap request key C<loglevel> with a value larger than 0, then
server choosing to support this feature must send C<X-Riap-Logging: 1> HTTP
response header and chunked response (as described in L<Riap::HTTP>) with each
chunk prepended (as described in L<Riap::HTTP> and the above description). You
can choose not to support this, by setting this configuration to 0.

=item * pass_psgi_env => BOOL (default: 0)

Set this to true if you want your functions to have access to the PSGI
environment. Functions will get it through the special argument C<-env>.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Access-HTTP-Server>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Perinci-Access-HTTP-Server>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Access-HTTP-Server>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

# this is a false positive, mostly
## no critic: ValuesAndExpressions::ProhibitCommaSeparatedStatements

package Perinci::WebScript::JSON;

our $DATE = '2018-11-22'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Mo qw(build default);

has url => (is=>'rw');
has riap_client => (is=>'rw');
has riap_client_args => (is=>'rw');

sub BUILD {
    my ($self, $args) = @_;

    if (!$self->{riap_client}) {
        require Perinci::Access::Lite;
        my %rcargs = (
            riap_version => $self->{riap_version} // 1.1,
            %{ $self->{riap_client_args} // {} },
        );
        $self->{riap_client} = Perinci::Access::Lite->new(%rcargs);
    }
}

sub run {
    my $self = shift;

    # get Rinci metadata
    my $res = $self->riap_client->request(meta => $self->url);
    die $res unless $res->[0] == 200;
    my $meta = $res->[2];

    # create PSGI app
    require JSON::MaybeXS;
    require Perinci::Sub::GetArgs::WebForm;
    require Plack::Request;
    my $app = sub {
        my $req = Plack::Request->new($_[0]);
        my $args = Perinci::Sub::GetArgs::WebForm::get_args_from_webform(
            $req->parameters, $meta, 1);
        my $res = $self->riap_client->request(
            call => $self->url,
            {args=>$args},
        );

        [
            $res->[0],
            ['Content-Type' => 'application/json; charset=UTF-8'],
            [JSON::MaybeXS->new->allow_nonref(1)->encode($res->[2])],
        ],
    };

    # determine appropriate deployment
    if ($0 =~ /\.fcgi\z/ || $ENV{FCGI_ROLE}) {
        require Plack::Handler::FCGI;
        Plack::Handler::FCGI->new->run($app);
    } elsif ($0 =~ /\.cgi\z/ || $ENV{GATEWAY_INTERFACE}) {
        require Plack::Handler::CGI;
        Plack::Handler::CGI->new->run($app);
    } else {
        die "Can't determine what deployment to use";
    }
}

1;
# ABSTRACT: From Rinci + function, Create Plack application that returns JSON response

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::WebScript::JSON - From Rinci + function, Create Plack application that returns JSON response

=head1 VERSION

This document describes version 0.002 of Perinci::WebScript::JSON (from Perl distribution Perinci-WebScript-JSON), released on 2018-11-22.

=head1 SYNOPSIS

In F<My/App.pm>:

 package My::App;
 use Encode::Simple;

 our %SPEC;
 $SPEC{uppercase} = {
     v => 1.1,
     args => {
         input => {schema=>'str*', req=>1},
     },
     args_as => 'array',
     result_naked => 1,
 };
 sub uppercase {
     my ($input) = @_;
     uc(decode 'UTF-8', $input);
 }
 1;

To run as CGI script, create F<app.cgi>:

 #!/usr/bin/env perl
 use Perinci::WebScript::JSON;
 Perinci::WebScript::JSON->new(url => '/My/App/uppercase')->run;

To run as FCGI script, create F<app.fcgi>:

 #!/usr/bin/env perl
 use Perinci::WebScript::JSON;
 Perinci::WebScript::JSON->new(url => '/My/App/uppercase')->run;

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-WebScript-JSON>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-WebScript-JSON>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-WebScript-JSON>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

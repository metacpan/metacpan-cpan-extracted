package Nephia::TestApp;
use strict;
use warnings;
use FindBin qw/$Bin/;
use Nephia plugins => [
    'View::MicroTemplate' => +{ include_path => [$Bin.'/nephia-test_app/view'] },
    'Dispatch',
    'FormValidator::Lite',
];
use utf8;

app {
    get '/' => sub {
        [200, [],
            render('index.html', {
                apppath  => 'lib/' . __PACKAGE__ .'.pm',
            })
        ];
    };

    post '/form' => sub {
        my $res = form(
            first_name => [qw/NOT_NULL/],
            last_name => [qw/NOT_NULL/],
            mail => [qw/NOT_NULL EMAIL_LOOSE/],
        );
        $res->set_param_message(
            first_name => 'FIRST NAME',
            last_name => 'LAST NAME',
            mail => 'E-MAIL ADDRESS'
        );

        my $response;
        if ($res->has_error) {
            $response = render('index.html', {
                error_messages => [$res->get_error_messages],
            });
        }
        else {
            my $req = req;
            my $first_name = param('first_name');
            my $last_name = param('last_name');
            my $full_name = sprintf('%s %s', $first_name, $last_name);
            my $mail = $req->param('mail');
            $response = render('confirm.html', {
                full_name => $full_name,
                mail => $mail,
            });
        }
        [200, [], $response];
    };
};

1;

=head1 NAME

MyApp - Web Application

=head1 SYNOPSIS

  $ plackup

=head1 DESCRIPTION

MyApp is web application based Nephia.

=head1 AUTHOR

clever guy

=head1 SEE ALSO

Nephia

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


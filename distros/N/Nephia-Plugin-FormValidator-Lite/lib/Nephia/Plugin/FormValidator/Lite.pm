package Nephia::Plugin::FormValidator::Lite;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.03";

use FormValidator::Lite;
use Carp qw/croak/;
use Try::Tiny;
use parent 'Nephia::Plugin';

sub new {
    my ($class, %opts) = @_;
    my $self = $class->SUPER::new(%opts);
    $self->{RUN_SQL} = [];
    return $self;
}

sub exports { qw/form/ }

sub form(@) {
    my $self = shift;
    my $context = shift;
    sub (@) {
        my %rule = @_;
        my $req = $context->get('req');
        my $conf = $context->get('config')->{'Plugin::FormValidator::Lite'};
        try {
            FormValidator::Lite->load_constraints(@{$conf->{constants}});
        }
        catch {
            croak 'Constraints of FormValidator::Lite is invalid format in config';
        };

        my $validator;
        try {
            $validator = FormValidator::Lite->new($req);
            $validator->load_function_message($conf->{function_message});
            $validator->check(
                %rule
            );

            # default param message is param key
            $validator->set_param_message(
                map { $_, $_ } keys %rule
            );
        }
        catch {
            die $_;
        };

        return $validator;
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Nephia::Plugin::FormValidator::Lite - FormValidator::Lite plugin for Nephia

=head1 SYNOPSIS

    use Nephia plugins => [qw/FormValidator::Lite/];
    post '/form' => sub {
        my $res = form(
            first_name => [qw/NOT_NULL/],
            last_kana => [qw/NOT_NULL/],
            mail => [qw/NOT_NULL EMAIL/],
        );

        # Alias name of params. This use in error messages.
        # Default is param key.
        $res->set_param_message(
            first_name => 'First name',
            last_name => 'Last name',
            mail => 'Mail address'
        );

        # check error
        if ($res->has_error) {
            return {
                template => 'index.html',
                error_message => $res->get_error_messages, # print errors
            };
        }
        else {
            my $req = req;
            return {
                template => 'confirm.html',
                form => {
                    name => $req->('param'),
                    name_kana => $req->('name_kana'),
                    mail => $req->('mail'),
                }
            };
        }
    };

    # in etc/conf/common.pl
    +{
        'Plugin::FormValidator::Lite' => {
            function_message => 'en',
            constants => [qw/Email/]
    }
};

=head1 DESCRIPTION

Nephia::Plugin::FormValidator::Lite is a L<FormValidator::Lite> binding for Nephia.

=head1 SEE ALSO

L<Nephia>

L<FormValidator::Lite>

=head1 LICENSE

Copyright (C) MACOPY.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

MACOPY E<lt>macopy123[attttt]gmai.comE<gt>

=cut


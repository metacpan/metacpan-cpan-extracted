package Tapper::Reports::Web::Controller::Tapper;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Controller::Tapper::VERSION = '5.0.17';
use strict;
use warnings;
use 5.010;
use Tapper::Reports::Web::Util;

use parent 'Tapper::Reports::Web::Controller::Base';

sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;

        # the easy way, to avoid fiddling with Mason autohandlers on
        # simple redirects

        my $body = <<EOF;
<html>
<head>
<meta http-equiv="refresh" content="0; URL=/tapper/start">
<meta name="description" content="Tapper"
<title>Tapper</title>
</head>
EOF
        $c->response->body($body);
}


sub auto :Private
{
        my ( $self, $c ) = @_;
        my $util    = Tapper::Reports::Web::Util->new();


        my (undef, $action) = split '/', $c->req->action;
        $c->stash->{top_menu} = $util->prepare_top_menu($action);
        if ($c->config->{use_authentication}) {
                if ($c->user_exists()) {
                        my $username = $c->user->username;
                        foreach (@{$c->stash->{top_menu}}) {
                                if ($_->{text} eq 'Login') {
                                        $_->{text} = "Logout $username";
                                        $_->{uri} = '/tapper/user/logout';
                                }
                        }
                }
        }

        # if auto returns false the remaining actions are not called
        1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Controller::Tapper

=head2 auto

This function is called. It creates the datastructure for the associated
autohandler template to generate the navigation links. This
datastructure is put onto the stash and therefore the function does not
return anything. It is called automatically from Catalyst with an object
reference ($self) and the catalyst context. Thus you also don't need to
worry about parameters.

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

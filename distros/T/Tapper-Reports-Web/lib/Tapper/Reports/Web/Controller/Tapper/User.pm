package Tapper::Reports::Web::Controller::Tapper::User;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Controller::Tapper::User::VERSION = '5.0.17';
use strict;
use warnings;
use 5.010;
use parent 'Tapper::Reports::Web::Controller::Base';


sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;
}



sub login :Local :Args(0)
{
        my ($self, $c) = @_;
        $c->stash->{'template'} = 'tapper/user/login.mas';
        if ( exists($c->req->params->{'username'})) {
                if ( $c->authenticate({ username => $c->req->params->{'username'},
                                        password => $c->req->params->{'password'},
                                      })) {
                        $c->response->redirect('/tapper/start');
                        $c->detach();
                        return;
                } else {
                        $c->stash->{message} = 'Invalid login';
                }
        }
}


sub logout :Local :Args(0) {
        my ($self, $c) = @_;
        $c->stash->{template} = 'tapper/user/logout.mas';
        $c->logout();
        $c->response->redirect('/tapper/start');
        $c->detach();
        return;
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::User

=head1 DESCRIPTION

Catalyst Controller .

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::User - Catalyst Controller for user handling

=head1 METHODS

All methods described in here expect the object (because they are
methods) and the catalyst context (because they are catalyst controller
methods) as the first two parameters. The method API documentation will
not name these two parameters explicitly.

=head2 index

=head2 login

=head2 logout

=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 LICENSE

This program is released under the following license: freebsd

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

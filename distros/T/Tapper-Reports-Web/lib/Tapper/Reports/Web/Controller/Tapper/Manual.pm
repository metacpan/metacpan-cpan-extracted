package Tapper::Reports::Web::Controller::Tapper::Manual;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Controller::Tapper::Manual::VERSION = '5.0.14';
use strict;
use warnings;

use parent 'Tapper::Reports::Web::Controller::Base';

sub auto :Private
{
        my ( $self, $c ) = @_;
        $c->forward('/tapper/manual/prepare_navi');
}


sub index :Path :Args(0)
{
        my ( $self, $c ) = @_;
}

sub prepare_navi : Private
{
        my ( $self, $c ) = @_;

        $c->stash->{navi} = [
                 {
                  title  => "Download PDF",
                  href => "/tapper/static/manual/tapper-manual.pdf",
                 },
                 {
                  title  => "Tapper Manual",
                  href   => "",
                  subnavi => [
                              {
                               href => "#Synopsis",
                               title => "Synopsis",
                              },
                              {
                               href => "#Technical-Infrastructure",
                               title => "Infrastructure",
                              },
                              {
                               href => "#Test-Protocol",
                               title => "Test Protocol",
                              },
                              {
                               href => "#Test-Suite-Wrappers",
                               title => "Test Suite Wrappers",
                              },
                              {
                               href => "#Preconditions",
                               title => "Preconditions",
                              },
                              {
                               href => "#Web-User-Interface",
                               title => "Web User Interface",
                              },
                              {
                               href => "#Reports-API",
                               title => "Reports API",
                              },
                              {
                               href => "#Complete-Use-Cases",
                               title => "Complete Use-Cases",
                              },
                             ],
                 },
                ];

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Manual

=head1 DESCRIPTION

Catalyst Controller.

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Hardware - Catalyst Controller

=head1 METHODS

=head1 AUTHOR

Steffen Schwigon,,,

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

This software is Copyright (c) 2019 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

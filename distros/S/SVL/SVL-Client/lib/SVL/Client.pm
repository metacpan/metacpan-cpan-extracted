package SVL::Client;

use strict;
use Catalyst qw/-Debug/;

our $VERSION = '0.01';

SVL::Client->config( name => 'SVL::Client' );

SVL::Client->setup;

=head1 NAME

SVL::Client - Catalyst based application

=head1 SYNOPSIS

    script/svl_client_server.pl

=head1 DESCRIPTION

Catalyst based application.

=head1 METHODS

=over 4

=item default

=cut

sub default : Private {
    my ( $self, $c ) = @_;
    $c->res->output('Congratulations, SVL::Client is on Catalyst!');
}

=back

=head1 AUTHOR

Arthur Bergman

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;

package OAuthomatic::OAuthInteraction::ViaMicroWeb;
# ABSTRACT: Handling oauth callback via embedded web server



use Moose;
use namespace::sweep;
use Proc::Background;
use Carp;


has 'micro_web' => (is=>'ro', isa=>'OAuthomatic::Internal::MicroWeb', required=>1,
                    handles => [ 'callback_url', 'wait_for_oauth_grant' ]);

sub prepare_to_work {
    my $self = shift;
    $self->micro_web->start_using;
    return;
}

sub cleanup_after_work {
    my $self = shift;
    $self->micro_web->finish_using;
    return;
}

with 'OAuthomatic::OAuthInteraction';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic::OAuthInteraction::ViaMicroWeb - Handling oauth callback via embedded web server

=head1 VERSION

version 0.0201

=head1 DESCRIPTION

This module uses in-process web server to handle callback after OAuth permission
is granted. Used as default implementation of C<oauth_interaction> plugin
of L<OAuthomatic>.

=head1 PARAMETERS

=head2 micro_web

Embedded web server object. Here it will be used to handle OAuth callback and display
minimal info to the user afterwards.

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

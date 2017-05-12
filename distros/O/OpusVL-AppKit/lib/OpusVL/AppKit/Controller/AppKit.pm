package OpusVL::AppKit::Controller::AppKit;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

__PACKAGE__->config
(
    appkit_myclass              => 'OpusVL::AppKit',
);


sub auto 
    : Action 
    : AppKitFeature('Password Change,User Administration,Role Administration')
{
    my ($self, $c) = @_;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Controller::AppKit

=head1 VERSION

version 2.29

=head2 auto

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

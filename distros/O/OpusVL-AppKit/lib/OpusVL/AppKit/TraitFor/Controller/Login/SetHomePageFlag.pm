package OpusVL::AppKit::TraitFor::Controller::Login::SetHomePageFlag;

use MooseX::MethodAttributes::Role;
use namespace::autoclean;

requires qw/
    login
    login_form_stash_key
/;

after 'login' => sub {
    my ( $self, $ctx ) = @_;

    $ctx->stash->{homepage} = 1;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::TraitFor::Controller::Login::SetHomePageFlag

=head1 VERSION

version 2.29

=head1 DESCRIPTION

Simple controller role to allow make the homepage logo visible on 
the login page of AppKit applications.

=head1 NAME

OpusVL::AppKit::TraitFor::Controller::Login::SetHomePageFlag

=head1 METHODS

=head2 after 'login'

    $ctx->stash->{ homepage => 1 };

=head1 SEE ALSO

=over

=item L<CatalystX::SimpleLogin::ControllerRole::Login>

=back

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

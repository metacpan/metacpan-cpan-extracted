package App::Main;

our $VERSION = '0.01';

use Scaffold::Class
  version => $VERSION,
  base    => 'Scaffold::Handler',
  mixin   => 'Scaffold::Uaf::Authenticate',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub do_main {
    my $self = shift;

    my $data = {
        header  => 'An Example Web Site',
        menu    => 'main_menu.tt',
        content => 'content.tt',
    };

    $self->stash->view->data($data);
    $self->stash->view->title("Scaffold");
    $self->stash->view->template("main.tt");
    $self->stash->view->template_wrapper("wrapper.tt");

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

App::Main - A test handler for Scaffold

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over 4

=back

=head1 SEE ALSO

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

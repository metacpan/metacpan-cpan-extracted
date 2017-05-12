package PAD::Plugin::Static;
use strict;
use warnings;
use parent 'PAD::Plugin';
use Plack::App::File;

sub execute {
    my $self = shift;
    Plack::App::Directory->new->to_app->($self->request->env);
}

1;
__END__

=head1 NAME

PAD::Plugin::Static - serve files via Plack::App::Directory

=head1 SYNOPSIS

    # enable PAD::Plugin::Static
    pad
    pad Static

=head1 AUTHOR

punytan E<lt>punytan@gmail.comE<gt>

=head1 SEE ALSO

L<PAD>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


use strict;
use warnings;
package Mojolicious::Plugin::Dotcloud;
{
  $Mojolicious::Plugin::Dotcloud::VERSION = '1.01';
}
use Mojo::Base 'Mojolicious::Plugin';
# ABSTRACT: A quick and dirty wrapper around DotCloud::Environment
use DotCloud::Environment;

sub register {
    my $self = shift;
    my $app  = shift;
    my $args = shift;

    $app->attr('_dotcloud' => sub { DotCloud::Environment->new($args) });
    $app->helper('dotcloud' => sub { return shift->app->_dotcloud });
}

1;
__END__
=pod
=head1 NAME

Mojolicious::Plugin::Dotcloud - Easy access to your dotCloud environment from your Mojolicious app.

=head1 VERSION

version 1.01

=head1 SYNOPSIS

    use Mojolicious::Plugin::Dotcloud

    $self->plugin('dotcloud' => {
        ...
    });

=head1 HELPERS

=head2 dotcloud

This helper gives you access to the L<DotCloud::Environment> object and all it's methods. See the L<DotCloud::Environment> documentation for more information.

=head1 SEE ALSO

L<DotCloud::Environment>

=head1 AUTHOR

Ben van Staveren, C<< <madcat at cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests through the web interface at L<https://github.com/benvanstaveren/mojolicious-plugin-dotcloud/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::Dotcloud


You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-Authentication>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-Authentication>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-Authentication/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 Ben van Staveren.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

package Resource::Pack::JSON;
BEGIN {
  $Resource::Pack::JSON::VERSION = '0.01';
}
use Moose;
use Resource::Pack;

use Resource::Pack::JSON::URL;

extends 'Resource::Pack::Resource';

=head1 NAME

Resource::Pack::JSON - Resource::Pack resource for the JSON Javascript library

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  my $resource = Resource::Pack::JSON->new(install_to => '/var/www/js');
  $resource->installl;

=head1 DESCRIPTION

This provides the JSON library as a L<Resource::Pack> resource.

=cut

=head1 ATTRIBUTES

=cut

=head2 use_bundled

If true, uses the bundled copy of json2.js that is shipped with this dist.
Otherwise, downloads a copy of the library from L<http://www.json.org/>.

=cut

has use_bundled => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has '+name' => (default => 'json');

sub BUILD {
    my $self = shift;

    resource $self => as {
        install_from(Path::Class::Dir->new(__FILE__)->parent);
        if ($self->use_bundled) {
            file js => 'json2.js';
        }
        else {
            $self->add_service(Resource::Pack::JSON::URL->new(
                name   => 'js',
                url    => 'http://www.json.org/json2.js',
                parent => $self,
            ));
        }
    };
}

__PACKAGE__->meta->make_immutable;
no Moose;
no Resource::Pack;

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-resource-pack-json at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Resource-Pack-JSON>.

=head1 SEE ALSO

L<Resource::Pack>

L<http://www.json.org/>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Resource::Pack::JSON

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Resource-Pack-JSON>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Resource-Pack-JSON>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Resource-Pack-JSON>

=item * Search CPAN

L<http://search.cpan.org/dist/Resource-Pack-JSON>

=back

=head1 AUTHOR

  Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

The bundled copy of json2.js is in the public domain.

=cut

1;
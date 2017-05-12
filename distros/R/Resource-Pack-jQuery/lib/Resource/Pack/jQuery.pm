package Resource::Pack::jQuery;
BEGIN {
  $Resource::Pack::jQuery::VERSION = '0.01';
}
use Moose;
use Resource::Pack;

extends 'Resource::Pack::Resource';

=head1 NAME

Resource::Pack::jQuery - Resource::Pack resource for the jQuery Javascript library

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  my $resource = Resource::Pack::jQuery->new(
      install_to => '/var/www/js',
      version    => '1.4.2',
  );
  $resource->install;

=head1 DESCRIPTION

This provides the jQuery library as a L<Resource::Pack> resource.

=cut

=head1 ATTRIBUTES

=cut

=head2 version

The desired jQuery version. Required, if C<use_bundled> is false.

=cut

has version => (
    is       => 'ro',
    isa      => 'Str',
);

=head2 minified

Whether or not the Javascript should be minified. Defaults to true.

=cut

has minified => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

=head2 use_bundled

If true, uses the bundled copy of jquery-1.4.2.min.js that is shipped with
this dist (and ignores the other attributes). Otherwise, uses the values of
C<version> and C<minified> to download a copy of the library from
L<http://code.jquery.com/>.

=cut

has use_bundled => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has '+name' => (default => 'jquery');

sub _jquery_url {
    my $self = shift;
    return 'http://code.jquery.com/jquery-'
         . $self->version
         . ($self->minified ? '.min' : '')
         . '.js';
}

sub BUILD {
    my $self = shift;

    if (!defined($self->version) && !$self->use_bundled) {
        confess "version must be specified if use_bundled is false";
    }

    resource $self => as {
        install_from(Path::Class::Dir->new(__FILE__)->parent);
        if ($self->use_bundled) {
            file js => 'jquery-1.4.2.min.js';
        }
        else {
            url  js => $self->_jquery_url;
        }
    };
}

__PACKAGE__->meta->make_immutable;
no Moose;
no Resource::Pack;

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-resource-pack-jquery at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Resource-Pack-jQuery>.

=head1 SEE ALSO

L<Resource::Pack>

L<http://jquery.com/>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Resource::Pack::jQuery

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Resource-Pack-jQuery>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Resource-Pack-jQuery>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Resource-Pack-jQuery>

=item * Search CPAN

L<http://search.cpan.org/dist/Resource-Pack-jQuery>

=back

=head1 AUTHOR

  Jesse Luehrs <doy at tozt dot net>

  John Resig is the author of jQuery

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

The bundled copy of jQuery is copyright (c) 2010 The jQuery Project.
It is licensed under either the MIT license or the GPLv2.

=cut

1;
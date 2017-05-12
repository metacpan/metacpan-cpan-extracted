package Resource::Pack::FromFile;
BEGIN {
  $Resource::Pack::FromFile::VERSION = '0.03';
}
use Moose;
use MooseX::Types::Path::Class qw(File);
use Resource::Pack;
# ABSTRACT: easily use external resource description files

extends 'Resource::Pack::Resource';



has resource_file => (
    is       => 'ro',
    isa      => File,
    coerce   => 1,
    required => 1,
);

sub BUILD {
    my $self = shift;
    resource $self => as {
        install_from(Path::Class::File->new($self->resource_file)->parent);
        include($self->resource_file);
    };
}

__PACKAGE__->meta->make_immutable;
no Moose;
no Resource::Pack;


__END__
=pod

=head1 NAME

Resource::Pack::FromFile - easily use external resource description files

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    # in data/resources
    url jquery => 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js';
    file app_js => 'app.js';
    file app_css => (
        file       => 'app.css',
        install_to => 'css',
    );
    dir 'images';

    # in installer script
    my $resource = Resource::Pack::FromFile->new(
        name          => 'my_app',
        resource_file => 'data/resources',
        install_to    => 'app',
    );
    $resource->install;

or

    package My::App::Resources;
    use Moose;
    extends 'Resource::Pack::FromFile';

    has '+name'          => (default => 'my_app');
    has '+resource_file' => (default => 'data/resources');

    my $resource = My::App::Resources->new(install_to => 'app');
    $resource->install;

=head1 DESCRIPTION

This is a subclass of L<Resource::Pack::Resource>, which handles loading a
resource definition from a separate file.

=head1 ATTRIBUTES

=head2 resource_file

The file to read the resource definition from. The containing directory is used
as the default for C<install_from>.

=for Pod::Coverage BUILD

1;

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Resource::Pack|Resource::Pack>

=back

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Jesse Luehrs <doy at tozt dot net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


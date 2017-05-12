package Resource::Pack::URL;
BEGIN {
  $Resource::Pack::URL::VERSION = '0.03';
}
use Moose;
use MooseX::Types::Path::Class qw(File);
use MooseX::Types::URI qw(Uri);
# ABSTRACT: a URL resource

use LWP::UserAgent;

with 'Resource::Pack::Installable',
     'Bread::Board::Service',
     'Bread::Board::Service::WithDependencies';



has url => (
    is       => 'ro',
    isa      => Uri,
    coerce   => 1,
    required => 1,
);


has install_as => (
    is      => 'rw',
    isa     => File,
    coerce  => 1,
    lazy    => 1,
    default => sub { (shift->url->path_segments)[-1] },
);


sub install_from_absolute {
    my $self = shift;
    $self->url;
}


sub install {
    my $self = shift;
    my $response = LWP::UserAgent->new->get($self->url->as_string);
    if ($response->is_success) {
        my $to = $self->install_to_absolute;
        $to->parent->mkpath unless -e $to->parent;
        my $fh = $to->openw;
        $fh->print($response->content);
        $fh->close;
    }
    else {
        confess "Could not fetch file " . $self->url->as_string
              . " because: " . $response->status_line;
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=head1 NAME

Resource::Pack::URL - a URL resource

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    my $url = Resource::Pack::URL->new(
        name => 'jquery',
        url  => 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js',
    );
    $url->install;

=head1 DESCRIPTION

This class represents a URL to be downloaded and installed. It can also be
added as a subresource to a L<Resource::Pack::Resource>. This class consumes
the L<Resource::Pack::Installable>, L<Bread::Board::Service>, and
L<Bread::Board::Service::WithDependencies> roles.

=head1 ATTRIBUTES

=head2 url

Required, read-only attribute for the source URL.

=head2 install_as

The name to use for the installed file. Defaults to the filename portion of the
C<url> attribute.

=head1 METHODS

=head2 install_from_absolute

Returns the entire source url.

=head2 install

Overridden to handle the downloading of the source file, before installing it.

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


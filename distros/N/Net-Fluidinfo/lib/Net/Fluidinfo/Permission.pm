package Net::Fluidinfo::Permission;
use Moose;
extends 'Net::Fluidinfo::Base';

use MooseX::ClassAttribute;
class_has Actions => (
    is => 'ro',
    isa => 'HashRef[ArrayRef[Str]]',
    default => sub {{
        'namespaces' => [qw(create update delete list control)],
        'tags'       => [qw(update delete control)],
        'tag-values' => [qw(write read delete control)]
    }}
);

has category   => (is => 'ro', isa => 'Str');
has path       => (is => 'ro', isa => 'Str');
has action     => (is => 'ro', isa => 'Str');
has policy     => (is => 'rw', isa => 'Str');
has exceptions => (is => 'rw', isa => 'ArrayRef[Str]');

sub is_open {
    my $self = shift;
    $self->policy eq 'open' 
}

sub is_closed {
    my $self = shift;
    $self->policy eq 'closed' 
}

sub has_exceptions {
    my $self = shift;
    @{$self->exceptions} != 0;
}

sub get {
    my ($class, $fin, $category, $path_or_has_path, $action) = @_;

    my $path = $class->get_path_from_string_or_has_path($path_or_has_path);
    $fin->get(
        path       => $class->abs_path('permissions', $category, $path),
        query      => { action => $action },
        headers    => $fin->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            my $h = $class->json->decode($response->content);
            $class->new(
                fin      => $fin,
                category => $category,
                path     => $path,
                action   => $action,
                %$h
            );
        }
    );
}

sub update {
    my $self = shift;

    my $payload = $self->json->encode({policy => $self->policy, exceptions => $self->exceptions});
    $self->fin->put(
        path    => $self->abs_path('permissions', $self->category, $self->path),
        query   => { action => $self->action },
        headers => $self->fin->headers_for_json,
        payload => $payload
    );
}

no Moose;
no MooseX::ClassAttribute;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::Fluidinfo::Permission - Fluidinfo permissions

=head1 SYNOPSIS

 use Net::Fluidinfo::Permission;

 # get
 $permission = Net::Fluidinfo::Permission->get($fin, $category, $path, $action);
 $permission->policy;
 $permission->exceptions;

 # update
 $permission->policy('closed');
 $permission->exceptions($exceptions);
 $permission->update;

=head1 DESCRIPTION

C<Net::Fluidinfo::Permission> models Fluidinfo permissions.

=head1 USAGE

=head2 Inheritance

C<Net::Fluidinfo::Permission> is a subclass of L<Net::Fluidinfo::Base>.

=head2 Class methods

=over

=item Net::Fluidinfo::Permission->get($fin, $category, $path_or_has_path, $action)

Retrieves the permission on action C<$action>, for the category C<$category>
and path extracted from C<$path>, which can be either a string with the very
path, a namespace, or a tag.

C<Net::Fluidinfo> provides a convenience shortcut for this method.

=back

=head2 Instance Methods

=over

=item $tag->update

Updates the permission in Fluidinfo.

=item $tag->category

Returns the category the permission is about.

=item $tag->path

Returns the path of the category the permission is about.

=item $tag->action

Returns the action the permission is about.

=back

=head1 FLUIDINFO DOCUMENTATION

=over

=item Fluidinfo high-level description

L<http://doc.fluidinfo.com/fluidDB/permissions.html>

=item Fluidinfo API documentation

L<http://doc.fluidinfo.com/fluidDB/api/http.html#authentication-and-authorization>

=item Fluidinfo API specification

L<http://api.fluidinfo.com/fluidDB/api/*/permissions/*>

=back

=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2012 Xavier Noria

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut


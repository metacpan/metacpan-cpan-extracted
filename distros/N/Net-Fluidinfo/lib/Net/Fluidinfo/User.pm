package Net::Fluidinfo::User;
use Moose;
extends 'Net::Fluidinfo::Base';

with 'Net::Fluidinfo::HasObject';

has name     => (is => 'ro', isa => 'Str');
has username => (is => 'ro', isa => 'Str');

sub get {
    my ($class, $fin, $username) = @_;

    $fin->get(
        path       => $class->abs_path('users', $username),
        headers    => $fin->accept_header_for_json,
        on_success => sub {
            my $response = shift;
            my $h = $class->json->decode($response->content);
            my $user = $class->new(fin => $fin, username => $username, %$h);
            $user->_set_object_id($h->{id});
            $user;
        }
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::Fluidinfo::User - Fluidinfo users

=head1 SYNOPSIS

 use Net::Fluidinfo::User;

 $user = Net::Fluidinfo::User->get($fin, $username);
 $user->name;
 
=head1 DESCRIPTION

Net::Fluidinfo::User models Fluidinfo users.

=head1 USAGE

=head2 Inheritance

C<Net::Fluidinfo::User> is a subclass of L<Net::Fluidinfo::Base>.

=head2 Roles

C<Net::Fluidinfo::User> consumes the role L<Net::Fluidinfo::HasObject>.

=head2 Class methods

=over

=item Net::Fluidinfo::User->get($fin, $username)

Retrieves the user with username C<$username> from Fluidinfo.

C<Net::Fluidinfo> provides a convenience shortcut for this method.

=back

=head2 Instance Methods

=over

=item $user->username

Returns the username of the user.

=item $user->name

Returns the name of the user.

=back

=head1 FLUIDINFO DOCUMENTATION

=over

=item Fluidinfo high-level description

L<http://doc.fluidinfo.com/fluidDB/users.html>

=item Fluidinfo API specification

L<http://api.fluidinfo.com/fluidDB/api/*/users/*>

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

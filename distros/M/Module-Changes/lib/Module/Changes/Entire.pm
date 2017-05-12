package Module::Changes::Entire;

use warnings;
use strict;
use Module::Changes;


our $VERSION = '0.05';


use base 'Module::Changes::Base';


__PACKAGE__
    ->mk_scalar_accessors(qw(name))
    ->mk_array_accessors(qw(releases));


sub newest_release {
    my $self = shift;
    $self->releases_index(0);
}


sub add_empty_release {
    my ($self, $callback) = @_;
    my $newest_release = $self->newest_release;
    my $release = Module::Changes->make_object_for_type('release',
        version => $newest_release->clone_version,
        author  => $newest_release->author,
    );
    $release->touch_date;
    $callback->($release);
    $self->releases_unshift($release);
}


sub add_new_revision {
    my $self = shift;
    $self->add_empty_release(sub { $_[0]->version->inc_revision });
}


sub add_new_version {
    my $self = shift;
    $self->add_empty_release(sub { $_[0]->version->inc_version });
}


sub add_new_subversion {
    my $self = shift;
    $self->add_empty_release(sub {
        my $release = shift;
        $release->version->components(3);
        $release->version->inc_subversion;
    });
}


sub add_new_alpha {
    my $self = shift;
    $self->add_empty_release(sub { $_[0]->version->inc_alpha });
}


1;

__END__

=head1 NAME

Module::Changes::Entire - an entire Changes file

=head1 SYNOPSIS

    use Module::Changes;
    my $changes = Module::Changes->make_object_for_type('entire');
    print $changes->newest_release->version;

=head1 DESCRIPTION

This class represents an entire Changes file.

See Module::Changes for the definition of the terms I<revision>, I<version>,
I<subversion> and I<alpha>.

=head1 METHODS

This class inherits all methods from L<Module::Changes::Base>.

=over 4

=item name

    $changes->name('Foo-Bar');
    my $name = $changes->name;

Set or get the overall distribution name of the Changes file.

=item releases

    $changes->releases_unshift($release);
    for my $release ($changes->releases) { ... }

This is an array accessor giving access to all the releases contained in the
Changes file. See L<Class::Accessor::Complex>'s C<mk_array_accessors()> for
which methods are available.

=item newest_release

    print $changes->newest_release->version;

Returns the most recent release object.

=item add_empty_release

    $changes->add_empty_release(sub { my $release = shift; ...  });

Adds a release object. Its version number is taken from the previously most
recent release. Its author is also taken from the the previous release.

Takes a coderef argument. The empty release object is passed to the coderef
before adding it to the list of releases. The coderef might manipulate the
version number, for example.

=item add_new_revision

    $changes->add_new_revision;

Add a new release. Its version number is taken from the previously most recent
release, increased to the next revision. Its author is also taken from the the
previous release.

For example, if the previous release was version C<v0.02>, the new release
will be version C<v1.00>.

=item add_new_version

    $changes->add_new_version;

Add a new release. Its version number is taken from the previous release,
increased to the next version. Its author is also taken from the the
previous release. 

For example, if the previous release was version C<v0.02>, the new release
will be version C<v0.03>. If it was C<v0.02_01>, it will still be C<v0.03>.

=item add_new_subversion

    $changes->add_new_subversion;

Add a new release. Its version number is taken from the previous release,
increased to the next subversion. Its author is also taken from the the
previous release.

For example, if the previous release was version C<v0.02>, the new release
will be version C<v0.02.01>.

=item add_new_alpha

    $changes->add_new_alpha;

Add a new release. Its version number is taken from the previous release,
increased to the next alpha. Its author is also taken from the the
previous release.

For example, if the previous release was version C<v0.02>, the new release
will be version C<v0.02_01>.

=back

=head1 TAGS

If you talk about this module in blogs, on del.icio.us or anywhere else,
please use the C<modulechanges> tag.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-module-changes@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 AUTHOR

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package Module::Changes::Release;

use warnings;
use strict;
use DateTime;
use Perl::Version;


our $VERSION = '0.05';


use base 'Module::Changes::Base';


__PACKAGE__
    ->mk_scalar_accessors(qw(version date author))
    ->mk_array_accessors(qw(changes tags));


# Perl::Version offers ->normal() and ->numify(), but I don't like either for
# Changes, so here is my format.

sub version_as_string {
    my $self = shift;

    # How many fields to show? Don't show a subversion of '0'.
    my @components = $self->version->components;
    $self->version->components(2) if @components == 3 && $components[2] == 0;

    $self->version->_format({
        prefix => '',
        printf => ['%d'],
        extend => '.%02d',
        alpha  => '_%02d',
        suffix => '',
        fields => scalar($self->version->components),
    });
}


sub touch_date {
    my $self = shift;
    $self->date(DateTime->now);
}


sub clone_version {
    my $self = shift;
    Perl::Version->new($self->version);
}


sub remove_tag {
    my ($self, $tag) = @_;
    $self->tags(grep { defined($_) && $_ ne $tag } $self->tags);
}


1;

__END__

=head1 NAME

Module::Changes::Release - a release within a Changes file

=head1 SYNOPSIS

    use Module::Changes;
    my $release = Module::Changes->make_object_for_type('release')
    $release->touch_date;

=head1 DESCRIPTION

This class represents a release within the Changes file.

=head1 METHODS

This class inherits all methods from L<Module::Changes::Base>.

=over 4

=item version

    $release->version(Perl::Version->new->('0.01'));
    print $release->version;

Set or get the release's version number. You need to use a L<Perl::Version>
object.

=item version_as_string

    print $release->version_as_string;

Takes the release's version object and returns a string representation.

=item date

    $release->date(DateTime::Format::W3CDTF->new->parse_datetime(...));
    print DateTime::Format::Mail->new->format_datetime($release->date);

Set or get the release's date. You need to use a L<DateTime> object.

=item author

    $release->author('Marcel Gruenauer <marcel@cpan.org>');
    print $release->author;

Set or get the release's author. It is recommended that you use a string as
shown above.

=item changes

    $release->changes_push('Added foobar()');
    for my $change ($release->changes) { ... }

This is an array accessor giving access to all the changes contained in the
release. See L<Class::Accessor::Complex>'s C<mk_array_accessors()> for which
methods are available.

Changes are just strings.

=item tags

    $release->tags_push('APIBREAK');
    for my $tag ($release->tags) { ... }

This is an array accessor giving access to all the tags contained in the
release. See L<Class::Accessor::Complex>'s C<mk_array_accessors()> for which
methods are available.

Tags are a way to help other programs understand (or at least guess) what has
happened in each release.

Tags are just strings. See the documentation for the C<changes> program for a
discussion of recommended tags.

=item touch_date

    $release->touch_date;

Touch the release's date, setting it to the current date andtime.

=item clone_version

    my $version = $release->clone_version;

Makes a clone of the release's version object. This is useful if you want to
use the version in a new release. You need a clone so you don't inadvertently
change this release's version number as well.

=item remove_tag

    $release->remove_tag('APIBREAK');

Takes a tag name and removes all occurrences of it from the tags array.

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


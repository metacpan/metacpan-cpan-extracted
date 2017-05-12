package Template::Provider::ArchiveTar;
use strict;
use Carp qw(croak);
use parent 'Template::Provider';
use vars '$VERSION';
$VERSION = '0.01';

=head1 NAME

Template::Provider::ArchiveTar - fetch templates from an archive

=head1 SYNOPSIS

    my $t = $info->{template} || Template->new({
        POST_CHOMP => 1,
        DEBUG => 1,
        LOAD_TEMPLATES => [
            Template::Provider::ArchiveTar->new({
                archive => Archive::Tar->new('theme.tar'),
            }),
        ],
    });

=cut

sub _init {
    my( $class, $options ) = @_;
    my $archive = delete $options->{archive}
        or croak "Need a valid archive object for the template files";
    my $self = $class->SUPER::_init( $options );
    $self->{archive} = $archive;
};

sub _template_modified {
    my ($self,$path) = @_;
    # we fake this by always returning a fresh timestamp so no caching here
    return time
}

sub _template_content {
    my ($self,$path) = @_;
    my $content = $self->{archive}->get_content($path);
    if( wantarray ) {
        return ($content,'',time);
    } else {
        return $content
    }
};

1;

=head1 DESCRIPTION

Using this module you can provide templates through a Tar archive or any
object compatible with the API of L<Archive::Tar>. Interesting examples
are L<Archive::Dir>, L<Archive::Merged> and L<Archive::SevenZip>.

=head1 SEE ALSO

L<Template::Provider>

L<Template::Provider::DBI>

=head1 REPOSITORY

The public repository of this module is 
L<http://github.com/Corion/template-provider-archivetar>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Template-Provider-ArchiveTar>
or via mail to L<Template-Provider-ArchiveTar-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2014-2016 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

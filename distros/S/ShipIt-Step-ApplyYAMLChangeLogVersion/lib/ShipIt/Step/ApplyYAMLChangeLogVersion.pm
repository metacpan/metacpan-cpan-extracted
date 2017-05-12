package ShipIt::Step::ApplyYAMLChangeLogVersion;

use strict;
use warnings;
use Dist::Joseki;
use Dist::Joseki::Version;


our $VERSION = '0.02';


use base qw(ShipIt::Step);


sub init {
    my ($self, $conf) = @_;

    $self->{file} = $conf->value("ApplyYAMLChangeLogVersion.file") ||
        'Changes';
}


sub run {
    my ($self, $state) = @_;

    my $version = Dist::Joseki::Version->new->
        get_newest_version($self->{file});
    my $is_tagged = $state->vc->exists_tagged_version($version);

    die "Version $version is already tagged. Update $self->{file}.\n" if
        $is_tagged;

    -e $self->{file} or die "$self->{file} does not exist\n";
    -r $self->{file} or die "$self->{file} is not readable\n";

    # call dist(1) so the ~/.distrc gets used
    system("dist version -s -f $self->{file}") and
        die "Can't apply YAML Changelog version: $?\n";

    $state->set_version($version);
}   


1;


__END__



=head1 NAME

ShipIt::Step::ApplyYAMLChangeLogVersion - apply version from YAML Changes file to modules and scripts

=head1 SYNOPSIS

None.

=head1 DESCRIPTION

This L<ShipIt> step reads the most recent version number from the YAML Changes
file and applies it to all modules in C<lib/> and to all scripts in C<bin/>.

To use it, just list in your C<.shipit> file. 

The precondition to using this step is that you always maintain the Changes
file. The C<dist> program, found in L<Dist::Joseki>, furthers such a
development style with its C<dist change> command. You can then dispense with
the usual C<FindVersion> and C<ChangeVersion> steps and just have something
like this (here broken into two lines for clarity):

    steps = ApplyYAMLChangeLogVersion, Manifest, DistTest, Commit, Tag,
            MakeDist, UploadCPAN, DistClean, Twitter

=head1 TAGS

If you talk about this module in blogs, on del.icio.us or anywhere else,
please use the C<shipitstepapplyyamlchangelogversion> tag.

=head1 VERSION 
                   
This document describes version 0.02 of L<ShipIt::Step::ApplyYAMLChangeLogVersion>.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<<bug-shipit-step-applyyamlchangelogversion@rt.cpan.org>>, or through the web interface at
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


package Software::Catalog::Role::Software;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-02'; # DATE
our $DIST = 'Software-Catalog'; # DIST
our $VERSION = '1.0.7'; # VERSION

use Role::Tiny;

use PerlX::Maybe;

sub available_archs {
    my $self = shift;
    sort keys %{ $self->canon2native_arch_map };
}

requires 'archive_info';

around archive_info => sub {
    my $orig = shift;
    my ($self, %args) = @_;

    # supply default for 'arch' argument
    if (!defined $args{arch}) {
        $args{arch} = $self->_detect_arch;
    }

    # supply default for 'version' argument
    if (!defined $args{version}) {
        my $verres = $self->latest_version(maybe arch => $args{arch});
        return [500, "Can't get latest version: $verres->[0] - $verres->[1]"]
            unless $verres->[0] == 200;
        $args{version} = $verres->[2];
        $args{alternate_version} = $verres->[3]{'func.alternate_version'}
            if defined $verres->[3]{'func.alternate_version'};
    }

    $orig->($self, %args);
};

requires 'available_versions';

around available_versions => sub {
    my $orig = shift;
    my ($self, %args) = @_;

    # supply default for 'arch' argument
    if (!defined $args{arch}) {
        require Software::Catalog::Util;
        $args{arch} = Software::Catalog::Util::detect_arch();
    }

    $orig->($self, %args);
};

requires 'canon2native_arch_map';

requires 'cmp_version'; # usually from versioning scheme role

requires 'homepage_url';

requires 'is_dedicated_profile';

requires 'is_valid_version'; # usually from versioning scheme role

requires 'latest_version';

around latest_version => sub {
    my $orig = shift;
    my ($self, %args) = @_;

    # supply default for 'arch' argument
    if (!defined $args{arch}) {
        $args{arch} = $self->_detect_arch;
    }

    $orig->($self, %args);
};

requires 'download_url';

around download_url => sub {
    my $orig = shift;
    my ($self, %args) = @_;

    # supply default for 'arch' argument
    if (!defined $args{arch}) {
        $args{arch} = $self->_detect_arch;
    }

    # supply default for 'version' argument
    if (!defined $args{version}) {
        my $verres = $self->latest_version(maybe arch => $args{arch});
        return [500, "Can't get latest version: $verres->[0] - $verres->[1]"]
            unless $verres->[0] == 200;
        $args{version} = $verres->[2];
        $args{alternate_version} = $verres->[3]{'func.alternate_version'}
            if defined $verres->[3]{'func.alternate_version'};
    }

    $orig->($self, %args);
};

requires 'release_note';

around release_note => sub {
    my $orig = shift;
    my ($self, %args) = @_;

    # supply default for 'arch' argument
    if (!defined $args{arch}) {
        $args{arch} = $self->_detect_arch;
    }

    # supply default for 'version' argument
    if (!defined $args{version}) {
        my $verres = $self->latest_version(maybe arch => $args{arch});
        return [500, "Can't get latest version: $verres->[0] - $verres->[1]"]
            unless $verres->[0] == 200;
        $args{version} = $verres->[2];
        $args{alternate_version} = $verres->[3]{'func.alternate_version'}
            if defined $verres->[3]{'func.alternate_version'};
    }

    $orig->($self, %args);
};

sub _canon2native_arch {
    my ($self, $arch) = @_;

    my $map = $self->canon2native_arch_map;
    my $rmap = {reverse %$map};
    if ($map->{$arch}) {
        return $map->{$arch};
    } elsif ($rmap->{$arch}) {
        return $arch;
    } else {
        die "Unknown arch '$arch'";
    }
}

sub _native2canon_arch {
    my ($self, $arch) = @_;

    my $map = $self->canon2native_arch_map;
    my $rmap = {reverse %$map};
    if ($rmap->{$arch}) {
        return $rmap->{$arch};
    } elsif ($map->{$arch}) {
        return $arch;
    } else {
        die "Unknown arch '$arch'";
    }
}

1;
# ABSTRACT: Role for software

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Catalog::Role::Software - Role for software

=head1 VERSION

This document describes version 1.0.7 of Software::Catalog::Role::Software (from Perl distribution Software-Catalog), released on 2020-10-02.

=head1 REQUIRED METHODS

=head2 archive_info

Get information about an archive of software download.

Usage:

 my $envres = $swobj->archive_info(%args);
 # sample result:
 # [200, "OK", {
 #   programs => [
 #     {name=>"firefox", path=>"/"},
 #   ],
 # }]

Return L<enveloped result|Rinci::function/"Enveloped result">. The payload is a
hash that can contain these keys: C<programs> which is an array of C<<
{name=>"PROGRAM_NAME", path=>"/PATH/"} >> records.

Arguments:

=over

=item * arch

Str, must be one of known architectures (see L</canon2native_arch_map>).
Optional. If not specified, this role's method modifier will supply
the default (the architecture the perl interpreter is built on).

=item * format

Str, optional. If software provides several archive formats that might differ in
structure or other aspects (e.g. ".zip" and ".tar.gz"), the user can choose
which by passing this argument.

=item * version

Str. Optional. If not specified, this role's method modifier will supply
the default from L</latest_version>.

=back

=head2 available_versions

List all available versions of a software. This usually means versions available
for download. It does not always equate all known versions.

Usage:

 my $envres = $swobj->available_versions(%args);

Return L<enveloped result|Rinci::function/"Enveloped result">.

Arguments:

=over

=item * arch

Str, must be one of known architectures (see L</canon2native_arch_map>).
Optional. If not specified, this role's method modifier will supply
the default (the architecture the perl interpreter is built on).

=back

If you do not want to provide this functionality, you can return something like:

 [501, "Not implemented"]

=head2 canon2native_arch_map

Return a mapping of architecture names from canonical to native.

 my $hashref = $swobj->canon2native_arch_map;

The canonical architecture names are:

 linux-x86        (Linux, Intel x86 32bit)
 linux-x86_64     (Linux, AMD/Intel 64bit)
 win32            (Windows, Intel x86 32bit)
 win64            (Windows, AMD/Intel 64bit)

Since each software might label the architectures differently, you will need to
provide a mapping. For example:

 sub canon2native_arch_map {
     return +{
         'linux-x86_64' => 'linux64',
         'win64' => 'win64',
     },
 }

When an architecture is not mapped, it is assumed to be unsupported by the
software.

=head2 cmp_version

Compare two version strings and return -1|0|1 like Perl's C<cmp()> operator.

Usage:

 my $cmp = $swobj->cmp_version($v1, $v2); # -1, 0, or 1

This method can often be supplied by a L<Versioning::Scheme>::* role if your
software follows a scheme that is supported.

=head2 download_url

Get download URL.

Usage:

 my $envres = $swobj->download_url(%args);
 # sample result:
 # [200, "OK", "https://www.example.org/foo-1.23.tar.gz"]

Return L<enveloped result|Rinci::function/"Enveloped result">.

Arguments:

=over

=item * arch

Str, must be one of known architectures (see L</canon2native_arch_map>).
Optional. If not specified, this role's method modifier will supply
the default (the architecture the perl interpreter is built on).

=item * version

Str. Optional. If not specified, this role's method modifier will supply
the default from L</latest_version>.

=back

=head2 homepage_url

Return the homepage URL.

Arguments: none.

=head2 is_dedicated_profile

Check whether the software uses "dedicated profile".

Usage:

 my $is_dedicated = $swobj->is_dedicated_profile;

This method is created to support Firefox 67+ but can be used by other software
too. If C<is_dedicated_profile> returns a true value, it means the software
checks program location for profile and we should not use symlink for latest
version, e.g. /opt/firefox -> /opt/firefox-70.0 but should copy
/opt/firefox-70.0 (or later version) to /opt/firefox instead, to avoid changing
of program location whenever there's a new version.

Arguments: none.

=head2 is_valid_version

Check whether a version string is a syntactically valid version string for a
particular software. This does not mean that the said version actually exists,
just that the syntax is valid.

Usage:

 my $is_valid = $swobj->is_valid_version;

This method can often be supplied by a L<Versioning::Scheme>::* role if your
software follows a scheme that is supported.

=head2 latest_version

Get latest version information.

Usage:

 my $envres = $swobj->latest_version;
 # sample result:
 # [200, "OK", "80.0.1"]

Return L<enveloped result|Rinci::function/"Enveloped result">.

Arguments:

=over

=item * arch

Str, must be one of known architectures (see L</canon2native_arch_map>).
Optional. If not specified, this role's method modifier will supply
the default (the architecture the perl interpreter is built on).

=item * version

Str. Optional. If not specified, this role's method modifier will supply
the default from L</latest_version>.

=back

=head2 release_note

Get release note.

Usage:

 my $envres = $swobj->release_note(%args);
 # sample result:
 # [200, "OK", "..."]

Return L<enveloped result|Rinci::function/"Enveloped result">.

Arguments:

=over

=item * arch

Str, must be one of known architectures (see L</canon2native_arch_map>).
Optional. If not specified, this role's method modifier will supply
the default (the architecture the perl interpreter is built on).

=item * format

Str, optional. If software provides several release note formats, the user can
choose which by passing this argument. A sane default will be chosen.

=item * version

Str. Optional. If not specified, this role's method modifier will supply
the default from L</latest_version>.

=back

=head1 PROVIDED METHODS

=head2 available_archs

Return a sorted list of available architectures for a software.

 my @archs = $swobj->available_archs;

This information is retrieved from L</canon2native_arch_map>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Software-Catalog>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Software-Catalog>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Software-Catalog>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2015, 2014, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

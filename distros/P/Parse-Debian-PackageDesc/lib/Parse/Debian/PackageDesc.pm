package Parse::Debian::PackageDesc;

use strict;
use warnings;
our $VERSION = 0.15;
use 5.00800;

use Carp    qw(carp croak); # NEVER USE warn OR die !
use English qw(-no_match_vars);
use File::Basename;
use Encode;


sub new {
    my ($class, $path, %user_opts) = @_;

    my $self = bless {
                        path    => $path,
                        options => { %user_opts },
                     }, $class;
    if (-r $path) {
        open F, $path;
        $self->{contents} = decode('utf-8', join("", <F>));
        close F;
    }
    else {
        croak "Can't read file '$path'";
    }

    return $self;
}

sub path { $_[0]->{path} }

sub get_line_attr {
    my ($self, $attr) = @_;

    $self->{contents} =~ /^$attr: (.*)/m;
    return $1;
}

sub get_block_attr {
    my ($self, $attr) = @_;

    # Collect lines that start with space
    $self->{contents} =~ /^$attr:\s*\n(( [^\n]+\n)+)/m;
    return $1;
}

sub date {
    $_[0]->get_line_attr("Date");
}

sub name {
    $_[0]->source;
}

# This is special because we have to cover the binNMU case (we get lines like:
# "Source: libparse-debian-packagedesc-perl (0.12-1)" but we have to return
# just "libparse-debian-packagedesc-perl")
sub source {
    my $source_value = $_[0]->get_line_attr("Source");
    $source_value =~ s/ .*//;
    return $source_value;
}

sub architecture {
    split(/\s+/, $_[0]->get_line_attr("Architecture"));
}

sub version {
    $_[0]->get_line_attr("Version");
}

sub extract_upstream_version {
    my ($pkg, $version) = @_;

    $version =~ s/-[a-z0-9+.~]+$//i;
    return $version
}

sub upstream_version {
    my ($self) = @_;
    return __PACKAGE__->extract_upstream_version($self->version);
}

sub extract_debian_revision {
    my ($pkg, $version) = @_;

    $version =~ /-([a-z0-9+.~]+)$/i;
    return $1 || "";
}

sub debian_revision {
    my ($self) = @_;
    return __PACKAGE__->extract_debian_revision($self->version);
}

sub distribution {
    $_[0]->get_line_attr("Distribution");
}

sub urgency {
    $_[0]->get_line_attr("Urgency");
}

sub maintainer {
    $_[0]->get_line_attr("Maintainer");
}

sub changed_by {
    $_[0]->get_line_attr("Changed-By");
}

sub binary_packages {
    split(/\s/, $_[0]->get_line_attr("Binary"));
}

sub changes {
    $_[0]->get_block_attr("Changes");
}

sub files {
    my ($self) = @_;

    my $files = $self->get_block_attr("Files");
    return map { my @fields = split(/\s+/, $_); $fields[5] }
               split(/\n/, $files);
}

sub binary_package_files {
    my ($self) = @_;

    grep { $_ =~ /\.deb$/ } $self->files;
}

sub execute_gpg_verify {
    my ($self) = @_;

    my $options = defined $self->{options}->{gpg_homedir} ?
                    "--homedir '$self->{options}->{gpg_homedir}'" :
                    "";
    my $gpg_cmd_line = "LC_ALL=C gpg $options --verify ".$self->path." 2>&1";
    $self->{gpg_verify_output} = `$gpg_cmd_line`;
    $self->{gpg_verify_status} = $?;
}

sub gpg_verify_status {
    my ($self) = @_;

    if (!$self->{gpg_verify_status}) {
        $self->execute_gpg_verify;
    }
    return $self->{gpg_verify_status};
}

sub gpg_verify_output {
    my ($self) = @_;

    if (!$self->{gpg_verify_output}) {
        $self->execute_gpg_verify;
    }
    return $self->{gpg_verify_output};
}

sub correct_signature {
    my ($self) = @_;
    return ($self->gpg_verify_status == 0);
}

sub signature_id {
    my ($self) = @_;
    $self->gpg_verify_output =~ /^gpg: Signature.*ID (\w+)$/m;
    return $1;
}

1;

__END__

=head1 NAME

Parse::Debian::PackageDesc - Parses Debian changes and source package files

=head1 SYNOPSIS

 use Parse::Debian::PackageDesc;
 my $changes = Parse::Debian::PackageDesc->new('/path/foo.changes');
 my $source  = Parse::Debian::PackageDesc->new('/path/foo.dsc');
 my $pkg     = Parse::Debian::PackageDesc->new($changes_or_dsc,
                                               gpg_homedir => '/dir/gnupg');
 print $pkg->name, "\n";
 print $pkg->version, "\n";
 print $pkg->debian_revision, "\n";
 print $pkg->distribution, "\n";
 print join(", ", $pkg->binary_packages), "\n";
 print $pkg->changes, "\n";

=head1 DESCRIPTION

C<Parse::Debian::PackageDesc> parses a Debian C<.changes> file (or a C<.dsc>
file) and allows you to retrieve its information easily. It can even check for
GPG signatures, assuming you have GNUPG installed and an appropriate
configuration.

=head1 SUBROUTINES/METHODS

=head2 CLASS METHODS

=over 4

=item C<new($path)>

=item C<new($path, %user_opts)>

Creates a new object representing the C<.changes> or C<.dsc> file in C<$path>.
The only valid option for C<%user_opts> is C<gpg_homedir>, which points to the
GNUPG home directory with the appropriate options and keyrings for GPG
signature validation.

=back

=head2 INSTANCE METHODS

=over 4

=item C<path>

Returns the changes/dsc file path (the one given in the constructor).

=item C<date>

Returns the latest package revision date.

=item C<name>

=item C<source>

Returns the name of the source package.

=item C<version>

Returns the full package version.

=item C<upstream_version>

Returns the upstream version of the package. For native packages, the full
version is returned.

=item C<debian_revision>

Returns just the Debian revision of the package. So, if the full version is
C<3.15-5>, it returns just C<5>. For native packages, C<""> is returned.

=item C<distribution>

Returns the distribution the package is for.

=item C<urgency>

Returns the urgency for the package.

=item C<maintainer>

Returns the package maintainer.

=item C<changed_by>

Returns who made the upload.

=item C<binary_packages>

Returns a list of binary package names in the changes/dsc file.

=item C<changes>

Returns the latest package revision changelog entry.

=item C<files>

Returns the list of files referenced by the changes/dsc file.

=item C<binary_package_files>

Returns the list of binary package files referenced by the changes/dsc file.

=item C<signature_id>

Returns the key id for the signature of the changes/dsc file, or C<undef> if
there was no signature or there was some error with C<gpg>.

=item C<correct_signature>

Returns whether the the changes/dsc file has a correct signature.

=back

=head1 CONFIGURATION AND ENVIRONMENT

This module requires no configuration file or environment variables. However,
you may want to setup a special GNUPG directory with a defined keyring to
validate the GNUPG signatures.

=head1 AUTHOR

Esteban Manchado Velázquez <estebanm@opera.com>.

=head1 LICENSE AND COPYRIGHT

This code is offered under the Open Source BSD license.

Copyright (c) 2009, Opera Software. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

=over 4

=item

Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

=item

Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

=item

Neither the name of Opera Software nor the names of its contributors may
be used to endorse or promote products derived from this software without
specific prior written permission.

=back

=head1 DISCLAIMER OF WARRANTY

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

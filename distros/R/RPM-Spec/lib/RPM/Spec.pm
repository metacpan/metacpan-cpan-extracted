#############################################################################
#
# Manipulate (and probably abuse) a RPM spec
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 05/04/2009 09:36:47 PM PDT
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package RPM::Spec;

use Moose;
use namespace::autoclean;

use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class ':all';

use Path::Class;
#use RPM::Spec::DependencyInfo;

our $VERSION = '0.05';

# debugging
#use Smart::Comments '###', '####';

#############################################################################

has specfile => (is => 'ro', isa => File, coerce => 1, required => 1);

has filter_magic => (is => 'ro', isa => Bool, coerce => 1, default => 1);

#############################################################################

has _content => (
    traits => [ 'Array' ], is => 'ro', isa => 'ArrayRef[Str]', lazy_build => 1,

    handles => {
        has_content          => 'count',
        num_lines_in_content => 'count',
        grep_content         => 'grep',
        content              => 'elements',
    },
);

sub _build__content { [ split /\n/, shift->specfile->slurp ] }

has license => (is => 'ro', isa => 'Str', lazy_build => 1);
has epoch   => (is => 'ro', isa => 'Maybe[Str]', lazy_build => 1);
has version => (is => 'ro', isa => 'Str', lazy_build => 1);
has release => (is => 'ro', isa => 'Str', lazy_build => 1);
has summary => (is => 'ro', isa => 'Str', lazy_build => 1);
has source0 => (is => 'ro', isa => 'Str', lazy_build => 1);
has name    => (is => 'ro', isa => 'Str', lazy_build => 1);
# FIXME should we be a Uri type?
has url     => (is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_license { shift->_find(sub { /^License:/i    }) }
sub _build_epoch   { shift->_find(sub { /^Epoch:/i      }) }
sub _build_version { shift->_find(sub { /^Version:/i    }) }
sub _build_release { shift->_find(sub { /^Release:/i    }) }
sub _build_summary { shift->_find(sub { /^Summary:/i    }) }
sub _build_source0 { shift->_find(sub { /^Source(0|):/i }) }
sub _build_name    { shift->_find(sub { /^Name:/i       }) }
sub _build_url     { shift->_find(sub { /^URL:/i        }) }

# LineToken: value_returned
sub _find { (split /\s+/, (shift->grep_content(shift))[0], 2)[1] }

has _build_requires => (
    traits => [ 'Hash' ], is => 'ro', isa => 'HashRef', lazy_build => 1,

    handles => {
        has_build_requires    => 'count',
        has_build_require     => 'exists',
        build_require_version => 'get',
        num_build_requires    => 'count',
        build_requires        => 'keys',
        full_build_requires   => 'elements',
    },
);

sub _build__build_requires {
    my $self = shift @_;

    my %brs =
        map { my @p = split /\s+/, $_; $p[0] => $p[2] ? $p[2] : 0 }
        map { $_ =~ s/^BuildRequires:\s*//; $_                    }
        $self->grep_content(sub { /^BuildRequires:/i }            )
        ;

    ### %brs
    return \%brs;
}

has _requires => (
    traits => [ 'Hash' ], is => 'ro', isa => 'HashRef', lazy_build => 1,

    handles => {
        has_requires    => 'count',
        has_require     => 'exists',
        require_version => 'get',
        num_requires    => 'count',
        requires        => 'keys',
        full_requires   => 'elements',
    },
);

sub _build__requires {
    my $self = shift @_;

    my %brs =
        map { my @p = split /\s+/, $_; $p[0] => $p[2] ? $p[2] : 0 }
        map { $_ =~ s/^Requires:\s*//; $_                    }
        $self->grep_content(sub { /^Requires:/i }            )
        ;

    # only one "magic" requires at the moment
    delete $brs{'perl(:MODULE_COMPAT_%(eval'} if $self->filter_magic;

    ### %brs
    return \%brs;
}

has _middle => (
    traits => ['Array'], is => 'ro', isa => 'ArrayRef[Str]', lazy_build => 1,
    handles => { middle => 'elements' },
);

sub _build__middle { [ _after('%description', _before('%changelog', shift->content)) ] }

has _changelog => (
    traits => ['Array'], is => 'ro', isa => 'ArrayRef[Str]', lazy_build => 1,
    handles => {
        has_changelog          => 'count',
        grep_changelog         => 'grep',
        num_lines_in_changelog => 'count',
        changelog              => 'elements',
    },
);

sub _build__changelog { [ _after('%changelog', shift->content) ] }

sub _before  { my $sep = shift @_; my @l; do { return @l if /^$sep/; push @l, $_ } for @_ }
sub _after   { reverse _before(shift, reverse @_) }


__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

RPM::Spec - A very simplistic read-only method of accessing RPM spec files

=head1 SYNOPSIS

    use RPM::Spec;

    my $spec = RPM::Spec->new('path/to/my.spec');

    say 'Version is: ' . $spec->version;
    say 'Spec has an epoch' if $spec->has_epoch;

=head1 DESCRIPTION

B<WARNING: This code is actively being worked on, and the API may change.>

RPM::Spec provides simplistic access to the different bits of information a
spec file provides... It is basically a collection of different parsing
routines that were scattered through a bunch of other modules.

=head1 CLASS FUNCTIONS

=over 4

=item B<new(specfile =E<gt> [Str|File])>

Create a new RPM::Specfile object.  The only required parameter is 'specfile',
which is either a string or L<Path::Class::File> object pointing to the
location of the specfile.

=back

=head1 METHODS

=head2 Tag Functions

These methods each return the value of the given tag.  If the tag is not
present, undef is returned.

=over 4

=item B<license>

=item B<epoch>

=item B<release>

=item B<version>

=item B<source0>

Note this will pick up from either of "Source" or "Source0" tags.

=item B<name>

=item B<url>

=item B<summary>

=item B<middle>

The "middle" of a spec; e.g. everything from the first %description until the
changelog starts.

=back

=head2 Dependency Functions

Documentation as this interface is likely to change in the Very Near Future.

=head2 Content Functions

=over 4

=item B<content()>

Returns an array of strings representing the specfile.

=item B<has_content>

Is the file empty?

=item B<num_lines_in_content>

Returns the line count of the specfile.

=item B<grep_content(sub { ... })>

Given a coderef, greps through the content with it.  See also L<grep>.

=back

=head1 CAVEATS

=head2 No macro parsing

Macros are not evaluated.  e.g., if "Release: 1%{?dist}" is in your spec file,
"1%{?dist}" will be returned by release().

=head2 Read only!

We can't make any changes.

=head1 SEE ALSO

L<...>

=head1 BUGS AND LIMITATIONS

Please report problems to Chris Weyl <cweyl@alumni.drew.edu>, or (preferred)
to this package's RT tracker at <bug-RPM-Spec@rt.cpan.org>.

Patches are welcome.

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the

    Free Software Foundation, Inc.
    59 Temple Place, Suite 330
    Boston, MA  02111-1307  USA

=cut


package Search::Typesense::Version;

use Moo;
use Carp qw(croak);
use Search::Typesense::Types qw(
  NonEmptyStr
  PositiveOrZeroInt
);

our $VERSION = '0.07';

has version_string => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

has [qw/major minor patch/] => (
    is       => 'rwp',
    isa      => PositiveOrZeroInt,
    init_arg => undef,
);

sub BUILD {
    my $self    = shift;
    my $version = $self->version_string;

    # this isn't quite semver, but it seems to fit what Typesense is doing
    # See https://semver.org/ if this breaks
    unless ( $version =~ /^\d+\.\d+\.\d+$/a ) {
        croak("Invalid version string: $version");
    }
    my @version = split /\./ => $version;
    $self->_set_major( $version[0] );
    $self->_set_minor( $version[1] );
    $self->_set_patch( $version[2] );
}

sub comparator {
    my $self = shift;
    return sprintf "%03d%03d%03d" => $self->major, $self->minor, $self->patch;
}

1;

__END__

=head1 NAME

Search::Typesense::Version - Version object for the Typesense server

=head1 DESCRIPTION

Do not use directly. This is returned by the C<typesense_version> method from
L<Search::Typesense>.

=head1 METHODS

=head2 C<version_string>

    my $version        = $typesense->typesense_version;
    my $version_string = $version->version_string;

Returns the semantic version string, such as C<0.19.0>.

=head2 C<major>

    my $version = $typesense->typesense_version;
    my $major   = $version->major;

Returns the major version number.

=head2 C<minor>

    my $version = $typesense->typesense_version;
    my $minor   = $version->minor;

Returns the minor version number.

=head2 C<patch>

    my $version = $typesense->typesense_version;
    my $patch   = $version->patch;

Returns the patch version number.

=head2 C<comparator>

Returns a numeric string suitable for numeric comparisons between versions.

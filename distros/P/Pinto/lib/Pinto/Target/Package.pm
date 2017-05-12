# ABSTRACT: Specifies a package by name and version

package Pinto::Target::Package;

use Moose;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(Str);

use Try::Tiny;
use Module::CoreList;
use CPAN::Meta::Requirements;

use Pinto::Types qw(Version);
use Pinto::Util qw(throw trim_text);

use version;
use overload ( '""' => 'to_string');

#------------------------------------------------------------------------------

our $VERSION = '0.12'; # VERSION

#------------------------------------------------------------------------------

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has version => (
    is      => 'ro',
    isa     => Str | Version,
    default => '0',
    coerce  => 1,
);

has _vreq => (
    is       => 'ro',
    isa      => 'CPAN::Meta::Requirements',
    writer   => '_set_vreq',
    init_arg => undef,
);

#------------------------------------------------------------------------------

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my @args = @_;

    if ( @args == 1 and not ref $args[0] ) {

        throw "Invalid package specification: $_[0]"
            unless $_[0] =~ m{^ ([A-Z0-9_:]+) (?:~)? (.*)}ix;

        my ($name, $version) = ($1, $2);
        $version =~ s/^\@/==/; # Allow "@" as a synonym for "=="
        @args = ( name => $name, version => trim_text($version) || 0 );
    }

    return $class->$orig(@args);
};

#------------------------------------------------------------------------------

sub BUILD {
    my $self = shift;

    # We want to construct the C::M::Requirements object right away to ensure
    # $self->version is a valid string.  But if we do this in a builder, it 
    # has to be lazy because it depends on other attributes. So instead, we
    # construct it during the BUILD and use a private writer to set it.

    my $args = {$self->name => $self->version};

    my $req = try   { CPAN::Meta::Requirements->from_string_hash( $args) }
              catch { throw "Invalid package target ($self): $_"      };

    $self->_set_vreq($req);
    return $self;
}

#------------------------------------------------------------------------------


sub is_core {
    my ( $self, %args ) = @_;

    ## no critic qw(PackageVar);

    # Note: $PERL_VERSION is broken on old perls, so we must make
    # our own version object from the old $] variable
    my $pv = version->parse( $args{in} ) || version->parse($]);

    # If it ain't in here, it ain't in the core
    my $core_modules = $Module::CoreList::version{ $pv->numify + 0 };
    throw "Invalid perl version $pv" if not $core_modules;
    return 0 if not exists $core_modules->{ $self->name };

    # We treat deprecated modules as if they have already been removed
    my $deprecated_modules = $Module::CoreList::deprecated{ $pv->numify + 0 };
    return 0 if $deprecated_modules && exists $deprecated_modules->{ $self->name };

    # on some perls, we'll get an 'uninitialized' warning when
    # the $core_version is undef.  So force to zero in that case
    my $core_version = $core_modules->{ $self->name } || 0;

    return 1 if $self->is_satisfied_by( $core_version );
    return 0;
}

#-------------------------------------------------------------------------------


sub is_perl {
    my ($self) = @_;

    return $self->name eq 'perl';
}

#-------------------------------------------------------------------------------


sub is_satisfied_by {
    my ($self, $version) = @_;

    return $self->_vreq->accepts_module($self->name => $version);
}

#-------------------------------------------------------------------------------

sub unversioned {
    my ($self) = @_;

    return (ref $self)->new(name => $self->name);
}

#-------------------------------------------------------------------------------


sub to_string {
    my ($self) = @_;
    my $format = $self->version =~ m/^ [=<>!\@] /x ? '%s%s' : '%s~%s';
    return sprintf $format, $self->name, $self->version;
}

#------------------------------------------------------------------------------
# XXX Are we using this?

sub gte {
    my ($self, $other, $flip) = @_;
    return $self->is_satisfied_by($other) if not $flip;
    return $other->is_satisfied_by($self) if $flip;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer

=head1 NAME

Pinto::Target::Package - Specifies a package by name and version

=head1 VERSION

version 0.12

=head1 METHODS

=head2 is_core

=head2 is_core(in => $version)

Returns true if this Target is satisfied by the perl core as-of a particular
version.  If the version is not specified, it defaults to whatever version you
are using now.

=head2 is_perl()

Returns true if this Target is a perl version of perl itself.

=head2 is_satisfied_by($version)

Returns true if this Target is satisfied by version C<$version> of the package.

=head2 to_string()

Serializes this Target to its string form.  This method is called whenever the
Target is evaluated in string context.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

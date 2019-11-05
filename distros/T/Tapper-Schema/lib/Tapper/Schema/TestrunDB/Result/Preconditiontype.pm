package Tapper::Schema::TestrunDB::Result::Preconditiontype;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::Preconditiontype::VERSION = '5.0.11';
# ABSTRACT: Tapper - Containing types of preconditions

use strict;
use warnings;

our %preconditiontype_description =
    (
     package      => 'a package, might be a kernel, eg. .tgz, .rpm, ...',
     image        => 'a complete os image, .tgz, .iso, ...',
     subdir       => 'a subdir that can just be copied/rsynced',
     xen          => 'a setup description for a Xen based host+guests',
     kvm          => 'a setup description for a KVM based host+guests',
     dist_xen     => 'Xen environment of a particular distribution',
     dist_kvm     => 'KVM environment of a particular distribution',
     distribution => 'a particular whole distribution',
     description  => 'just a description, no actual file and not a particular other type. can be used for meta packges or dependency trees',
    );

use parent 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("preconditiontype");
__PACKAGE__->add_columns
    (
     "name",        { data_type => "VARCHAR",  default_value => undef, is_nullable => 0, size => 255,    },
     "description", { data_type => "TEXT",     default_value => "",    is_nullable => 0,                 },
    );
__PACKAGE__->set_primary_key("name");


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::Preconditiontype - Tapper - Containing types of preconditions

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

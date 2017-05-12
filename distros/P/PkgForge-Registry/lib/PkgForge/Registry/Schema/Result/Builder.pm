package PkgForge::Registry::Schema::Result::Builder; # -*- perl -*-
use strict;
use warnings;

# $Id: Builder.pm.in 16917 2011-05-02 12:53:11Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16917 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Registry/PkgForge_Registry_1_3_0/lib/PkgForge/Registry/Schema/Result/Builder.pm.in $
# $Date: 2011-05-02 13:53:11 +0100 (Mon, 02 May 2011) $

our $VERSION = '1.3.0';

use DateTime;

use base 'DBIx::Class::Core';

=head1 NAME

PkgForge::Registry::Schema::Result::Builder

=head1 VERSION

This documentation refers to PkgForge::Registry::Schema::Result::Builder version 1.3.0

=cut

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);

__PACKAGE__->table('builder');

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'builder_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 platform

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 current

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 modtime

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \'now()'}

=cut

__PACKAGE__->add_columns(
  'id',
  {
    data_type         => 'integer',
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => 'builder_id_seq',
  },
  'name',
  { data_type => 'varchar', is_nullable => 0, size => 50 },
  'platform',
  { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
  'current',
  { data_type => 'integer', is_foreign_key => 1, is_nullable => 1 },
  'modtime',
  {
    data_type      => 'datetime',
    is_foreign_key => 0,
    is_nullable    => 0,
  },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('builder_current_key', ['current']);
__PACKAGE__->add_unique_constraint('builder_name_key', ['name']);

=head1 RELATIONS

=head2 current

Type: belongs_to

Related object: L<PkgForge::Registry::Schema::Result::Task>

=cut

__PACKAGE__->belongs_to(
  'current',
  'PkgForge::Registry::Schema::Result::Task',
  { id => 'current' },
  { join_type => 'LEFT', on_delete => 'CASCADE', on_update => 'CASCADE' },
);

=head2 platform

Type: belongs_to

Related object: L<PkgForge::Registry::Schema::Result::Platform>

=cut

__PACKAGE__->belongs_to(
  'platform',
  'PkgForge::Registry::Schema::Result::Platform',
  { id => 'platform' },
  { on_delete => 'CASCADE', on_update => 'CASCADE' },
);

=head2 build_logs

Type: has_many

Related object: L<PkgForge::Registry::Schema::Result::BuildLog>

=cut

__PACKAGE__->has_many(
  'build_logs',
  'PkgForge::Registry::Schema::Result::BuildLog',
  { 'foreign.builder' => 'self.name' },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
__END__

=head1 DEPENDENCIES

This module requires L<DBIx::Class>, it also needs L<DateTime> to
inflate the C<modtime> column into something useful.

=head1 SEE ALSO

L<PkgForge::Registry>, L<PkgForge::Registry::Schema>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux5, Fedora13

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2010 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut

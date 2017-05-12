package PkgForge::Registry::Schema::Result::Platform; # -*- perl -*-
use strict;
use warnings;

# $Id: Platform.pm.in 16917 2011-05-02 12:53:11Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16917 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Registry/PkgForge_Registry_1_3_0/lib/PkgForge/Registry/Schema/Result/Platform.pm.in $
# $Date: 2011-05-02 13:53:11 +0100 (Mon, 02 May 2011) $

our $VERSION = '1.3.0';

use base 'DBIx::Class::Core';

=head1 NAME

PkgForge::Registry::Schema::Result::Platform

=head1 VERSION

This documentation refers to PkgForge::Registry::Schema::Result::Platform version 1.3.0

=cut

__PACKAGE__->table('platform');

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'platform_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 arch

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 active

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 auto

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  'id',
  {
    data_type         => 'integer',
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => 'platform_id_seq',
  },
  'name',
  { data_type => 'varchar', is_nullable => 0, size => 10 },
  'arch',
  { data_type => 'varchar', is_nullable => 0, size => 10 },
  'active',
  { data_type => 'boolean', default_value => \'false', is_nullable => 0 },
  'auto',
  { data_type => 'boolean', default_value => \'false', is_nullable => 0 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('name_arch', ['name', 'arch']);

=head1 RELATIONS

=head2 builders

Type: has_many

Related object: L<PkgForge::Registry::Schema::Result::Builder>

=cut

__PACKAGE__->has_many(
  'builders',
  'PkgForge::Registry::Schema::Result::Builder',
  { 'foreign.platform' => 'self.id' },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tasks

Type: has_many

Related object: L<PkgForge::Registry::Schema::Result::Task>

=cut

__PACKAGE__->has_many(
  'tasks',
  'PkgForge::Registry::Schema::Result::Task',
  { 'foreign.platform' => 'self.id' },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 build_logs

Type: has_many

Related object: L<PkgForge::Registry::Schema::Result::BuildLog>

=cut

__PACKAGE__->has_many(
   'build_logs',
   'PkgForge::Registry::Schema::Result::BuildLog',
   { 'foreign.platform' => 'self.id' },
   { cascade_copy => 0, cascade_delete => 0 },
);

1;
__END__

=head1 DEPENDENCIES

This module requires L<DBIx::Class>.

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

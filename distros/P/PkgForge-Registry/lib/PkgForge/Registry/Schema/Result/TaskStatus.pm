package PkgForge::Registry::Schema::Result::TaskStatus;
use strict;
use warnings;

# $Id: TaskStatus.pm.in 15112 2010-12-13 11:40:50Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 15112 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Registry/PkgForge_Registry_1_3_0/lib/PkgForge/Registry/Schema/Result/TaskStatus.pm.in $
# $Date: 2010-12-13 11:40:50 +0000 (Mon, 13 Dec 2010) $

our $VERSION = '1.3.0';

use base 'DBIx::Class::Core';


=head1 NAME

PkgForge::Registry::Schema::Result::TaskStatus

=head1 VERSION

This documentation refers to PkgForge::Registry::Schema::Result::TaskStatus version 1.3.0

=cut

__PACKAGE__->table('task_status');

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'task_status_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=cut

__PACKAGE__->add_columns(
  'id',
  {
    data_type         => 'integer',
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => 'task_status_id_seq',
  },
  'name',
  { data_type => 'varchar', is_nullable => 0, size => 20 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('task_status_name_key', ['name']);

=head1 RELATIONS

=head2 tasks

Type: has_many

Related object: L<PkgForge::Registry::Schema::Result::Task>

=cut

__PACKAGE__->has_many(
  'tasks',
  'PkgForge::Registry::Schema::Result::Task',
  { 'foreign.status' => 'self.id' },
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

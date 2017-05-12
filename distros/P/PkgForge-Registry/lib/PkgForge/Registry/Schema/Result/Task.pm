package PkgForge::Registry::Schema::Result::Task; # -*- perl -*-
use strict;
use warnings;

# $Id: Task.pm.in 15112 2010-12-13 11:40:50Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 15112 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Registry/PkgForge_Registry_1_3_0/lib/PkgForge/Registry/Schema/Result/Task.pm.in $
# $Date: 2010-12-13 11:40:50 +0000 (Mon, 13 Dec 2010) $

our $VERSION = '1.3.0';

use DateTime;

use base 'DBIx::Class::Core';

=head1 NAME

PkgForge::Registry::Schema::Result::Task

=head1 VERSION

This documentation refers to PkgForge::Registry::Schema::Result::Task version 1.3.0

=cut

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);

__PACKAGE__->table('task');

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'task_id_seq'

=head2 job

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 platform

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 status

  data_type: 'integer'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

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
    sequence          => 'task_id_seq',
  },
  'job',
  { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
  'platform',
  { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
  'status',
  {
    data_type      => 'integer',
    default_value  => 0,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  'modtime',
  {
    data_type      => 'datetime',
    is_foreign_key => 0,
    is_nullable    => 0,
  },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('job_plat', ['job', 'platform']);

=head1 RELATIONS

=head2 builder

Type: might_have

Related object: L<PkgForge::Registry::Schema::Result::Builder>

=cut

__PACKAGE__->might_have(
  'builder',
  'PkgForge::Registry::Schema::Result::Builder',
  { 'foreign.current' => 'self.id' },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 job

Type: belongs_to

Related object: L<PkgForge::Registry::Schema::Result::Job>

=cut

__PACKAGE__->belongs_to(
  'job',
  'PkgForge::Registry::Schema::Result::Job',
  { id => 'job' },
  { on_delete => 'CASCADE', on_update => 'CASCADE' },
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

=head2 status

Type: belongs_to

Related object: L<PkgForge::Registry::Schema::Result::TaskStatus>

=cut

__PACKAGE__->belongs_to(
  'status',
  'PkgForge::Registry::Schema::Result::TaskStatus',
  { id => 'status' },
  { on_delete => 'CASCADE', on_update => 'CASCADE' },
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

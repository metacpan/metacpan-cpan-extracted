package PkgForge::Registry::Schema::Result::BuildLog; # -*- perl -*-
use strict;
use warnings;

# $Id: Builder.pm.in 14547 2010-11-22 13:12:54Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 14547 $
# $HeadURL: https://svn.lcfg.org/svn/source/trunk/PkgForge-Registry/lib/PkgForge/Registry/Schema/Result/Builder.pm.in $
# $Date: 2010-11-22 13:12:54 +0000 (Mon, 22 Nov 2010) $

our $VERSION = '1.3.0';

use DateTime;

use base 'DBIx::Class::Core';

=head1 NAME

PkgForge::Registry::Schema::Result::BuildLog

=head1 VERSION

This documentation refers to PkgForge::Registry::Schema::Result::BuildLog version 1.3.0

=cut

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);

__PACKAGE__->table('build_log');

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'build_log_id_seq'

=head2 job

  data_type: 'varchar'
  is_foreign_key: 0
  is_nullable: 0
  size: 50

=head2 builder

  data_type: 'varchar'
  is_foreign_key: 0
  is_nullable: 0
  size: 50

=head2 platform

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 modtime

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  'id',
  {
    data_type         => 'integer',
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => 'build_log_id_seq',
  },
  'job',
  { data_type => 'varchar', is_foreign_key => 0, is_nullable => 0 },
  'builder',
  { data_type => 'varchar', is_foreign_key => 0, is_nullable => 0 },
  'platform',
  { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
  'modtime',
  {
    data_type      => 'datetime',
    is_foreign_key => 0,
    is_nullable    => 0,
  },
);
__PACKAGE__->set_primary_key('id');

=head1 RELATIONS

=head2 builder

Type: might_have

Related object: L<PkgForge::Registry::Schema::Result::Builder>

=cut

__PACKAGE__->might_have(
  'builder',
  'PkgForge::Registry::Schema::Result::Builder',
  { 'foreign.name' => 'self.builder' },
  { join_type => 'LEFT', on_delete => 'CASCADE', on_update => 'CASCADE' },
);

=head2 job

Type: might_have

Related object: L<PkgForge::Registry::Schema::Result::Job>

=cut

__PACKAGE__->might_have(
  'job',
  'PkgForge::Registry::Schema::Result::Job',
  { 'foreign.uuid' => 'self.job' },
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
  { join_type => 'LEFT', on_delete => 'CASCADE', on_update => 'CASCADE' },
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

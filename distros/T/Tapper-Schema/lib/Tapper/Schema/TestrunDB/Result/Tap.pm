package Tapper::Schema::TestrunDB::Result::Tap;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::Tap::VERSION = '5.0.12';
# ABSTRACT: Tapper - containing tap reports

use 5.010;
use strict;
use warnings;

use parent 'DBIx::Class';

use Data::Dumper;

__PACKAGE__->load_components(qw(InflateColumn::DateTime TimeStamp Core));
__PACKAGE__->table("tap");
__PACKAGE__->add_columns
    (
     "id",                      { data_type => "INT",      default_value => undef,  is_nullable => 0, size => 11, is_auto_increment => 1,     },
     "report_id",               { data_type => "INT",      default_value => undef,  is_nullable => 0, size => 11,                             },
     #
     # raw tap
     "tap",                     { data_type => "LONGBLOB", default_value => "",     is_nullable => 0,                                         },
     "tap_is_archive",          { data_type => "INT",     default_value => undef,   is_nullable => 1, size => 11,                             },
     "processed",               { data_type => "INT",     default_value => 0,       is_nullable => 0, size => 4,                              },
     #
     # parsed tap
     "tapdom",                  { data_type => "LONGBLOB", default_value => "",     is_nullable => 1,                                         },
     "created_at",              { data_type => "DATETIME", default_value => undef,  is_nullable => 0, set_on_create => 1,                     },
     "updated_at",              { data_type => "DATETIME", default_value => undef,  is_nullable => 0, set_on_create => 1, set_on_update => 1, },
    );

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to   ( report => 'Tapper::Schema::TestrunDB::Result::Report', { 'foreign.id' => 'self.report_id' });

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::Tap - Tapper - containing tap reports

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

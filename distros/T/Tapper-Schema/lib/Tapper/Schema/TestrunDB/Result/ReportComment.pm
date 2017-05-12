package Tapper::Schema::TestrunDB::Result::ReportComment;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::ReportComment::VERSION = '5.0.9';
# ABSTRACT: Tapper - Containing comments of reports

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::DateTime TimeStamp Core/);
__PACKAGE__->table("reportcomment");
__PACKAGE__->add_columns
    (
     "id",         { data_type => "INT",      default_value => undef,  is_nullable => 0, size => 11, is_auto_increment => 1,     },
     "report_id",  { data_type => "INT",      default_value => undef,  is_nullable => 0, size => 11, is_foreign_key => 1,        },
     "owner_id",   { data_type => "INT",      default_value => undef,  is_nullable => 1, size => 11, is_foreign_key => 1, extra => { renamed_from => 'user_id'  }, },
     "succession", { data_type => "INT",      default_value => undef,  is_nullable => 1, size => 10,                             },
     "comment",    { data_type => "TEXT",     default_value => "",     is_nullable => 0,                                         },
     "created_at", { data_type => "DATETIME", default_value => undef,  is_nullable => 0, set_on_create => 1,                     },
     "updated_at", { data_type => "DATETIME", default_value => undef,  is_nullable => 0, set_on_create => 1, set_on_update => 1, },
    );

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to   ( report => 'Tapper::Schema::TestrunDB::Result::Report', { 'foreign.id' => 'self.report_id' });
__PACKAGE__->belongs_to   ( owner  => 'Tapper::Schema::TestrunDB::Result::Owner',  { 'foreign.id' => 'self.owner_id' });


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::ReportComment - Tapper - Containing comments of reports

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

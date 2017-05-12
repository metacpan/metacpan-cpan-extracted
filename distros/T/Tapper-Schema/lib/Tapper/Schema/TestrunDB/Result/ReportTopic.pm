package Tapper::Schema::TestrunDB::Result::ReportTopic;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::ReportTopic::VERSION = '5.0.9';
# ABSTRACT: Tapper - containg topic information for reports

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("reporttopic");
__PACKAGE__->add_columns
    (
     "id",                        { data_type => "INT",      default_value => undef,  is_nullable => 0, size => 11, is_auto_increment => 1, },
     "report_id",                 { data_type => "INT",      default_value => undef,  is_nullable => 0, size => 11, is_foreign_key => 1,    },
     "name",                      { data_type => "VARCHAR",  default_value => "",     is_nullable => 1, size => 255,                        },
     "details",                   { data_type => "TEXT",     default_value => "",     is_nullable => 0,                                     },
    );

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to   ( report => 'Tapper::Schema::TestrunDB::Result::Report', { 'foreign.id' => 'self.report_id' });


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::ReportTopic - Tapper - containg topic information for reports

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

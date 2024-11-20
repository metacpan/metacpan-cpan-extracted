package Tapper::Schema::TestrunDB::Result::Scenario;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::Scenario::VERSION = '5.0.12';
# ABSTRACT: Tapper - Grouping of interdependent tests

use 5.010;
use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::Object::Enum", "Core");
__PACKAGE__->table("scenario");
__PACKAGE__->add_columns
    (
     "id",   { data_type => "INT",       default_value => undef, is_nullable => 0, size => 11,  is_auto_increment => 1, },
     "type", { data_type => "VARCHAR",   default_value => "",    is_nullable => 0, size => 255,                         },
     "options", { data_type => "TEXT",    default       => undef, is_nullable => 1,                                      },
     "name",  { data_type => "VARCHAR",                           is_nullable => 1,  size => 255,                        },
    );

__PACKAGE__->set_primary_key(qw/id/);

__PACKAGE__->inflate_column(
    options => {
        inflate => sub {
            require YAML::XS;
            YAML::XS::Load(shift);
        },
        deflate => sub {
            require YAML::XS;
            YAML::XS::Dump(shift);
        },
    }
);


(my $basepkg = __PACKAGE__) =~ s/::\w+$//;

__PACKAGE__->has_many  ( scenario_elements => "${basepkg}::ScenarioElement", { 'foreign.scenario_id'   => 'self.id' });


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::Scenario - Tapper - Grouping of interdependent tests

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

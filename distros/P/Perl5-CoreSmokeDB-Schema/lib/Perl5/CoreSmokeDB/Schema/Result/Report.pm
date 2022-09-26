use utf8;
package Perl5::CoreSmokeDB::Schema::Result::Report;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Perl5::CoreSmokeDB::Schema::Result::Report

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<report>

=cut

__PACKAGE__->table("report");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'report_id_seq'

=head2 sconfig_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 duration

  data_type: 'integer'
  is_nullable: 1

=head2 config_count

  data_type: 'integer'
  is_nullable: 1

=head2 reporter

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 reporter_version

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 smoke_perl

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 smoke_revision

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 smoke_version

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 smoker_version

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 smoke_date

  data_type: 'timestamp with time zone'
  is_nullable: 0

=head2 perl_id

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 git_id

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 git_describe

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 applied_patches

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 hostname

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 architecture

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 osname

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 osversion

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 cpu_count

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 cpu_description

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 username

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 test_jobs

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 lc_all

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 lang

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 user_note

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 manifest_msgs

  data_type: 'bytea'
  is_nullable: 1

=head2 compiler_msgs

  data_type: 'bytea'
  is_nullable: 1

=head2 skipped_tests

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 log_file

  data_type: 'bytea'
  is_nullable: 1

=head2 out_file

  data_type: 'bytea'
  is_nullable: 1

=head2 harness_only

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 harness3opts

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 summary

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 smoke_branch

  data_type: 'text'
  default_value: 'blead'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 nonfatal_msgs

  data_type: 'bytea'
  is_nullable: 1

=head2 plevel

  data_type: 'text'
  default_value: git_describe_as_plevel(git_describe)
  is_nullable: 1
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "report_id_seq",
  },
  "sconfig_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "duration",
  { data_type => "integer", is_nullable => 1 },
  "config_count",
  { data_type => "integer", is_nullable => 1 },
  "reporter",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "reporter_version",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "smoke_perl",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "smoke_revision",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "smoke_version",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "smoker_version",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "smoke_date",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "perl_id",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "git_id",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "git_describe",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "applied_patches",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "hostname",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "architecture",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "osname",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "osversion",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "cpu_count",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "cpu_description",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "username",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "test_jobs",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "lc_all",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "lang",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "user_note",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "manifest_msgs",
  { data_type => "bytea", is_nullable => 1 },
  "compiler_msgs",
  { data_type => "bytea", is_nullable => 1 },
  "skipped_tests",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "log_file",
  { data_type => "bytea", is_nullable => 1 },
  "out_file",
  { data_type => "bytea", is_nullable => 1 },
  "harness_only",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "harness3opts",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "summary",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "smoke_branch",
  {
    data_type     => "text",
    default_value => "blead",
    is_nullable   => 1,
    original      => { data_type => "varchar" },
  },
  "nonfatal_msgs",
  { data_type => "bytea", is_nullable => 1 },
  "plevel",
  {
    data_type     => "text",
    default_value => \"git_describe_as_plevel(git_describe)",
    is_nullable   => 1,
    original      => { data_type => "varchar" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<report_git_id_smoke_date_duration_hostname_architecture_key>

=over 4

=item * L</git_id>

=item * L</smoke_date>

=item * L</duration>

=item * L</hostname>

=item * L</architecture>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "report_git_id_smoke_date_duration_hostname_architecture_key",
  ["git_id", "smoke_date", "duration", "hostname", "architecture"],
);

=head1 RELATIONS

=head2 configs

Type: has_many

Related object: L<Perl5::CoreSmokeDB::Schema::Result::Config>

=cut

__PACKAGE__->has_many(
  "configs",
  "Perl5::CoreSmokeDB::Schema::Result::Config",
  { "foreign.report_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sconfig

Type: belongs_to

Related object: L<Perl5::CoreSmokeDB::Schema::Result::SmokeConfig>

=cut

__PACKAGE__->belongs_to(
  "sconfig",
  "Perl5::CoreSmokeDB::Schema::Result::SmokeConfig",
  { id => "sconfig_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-09-06 09:15:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YSwjDKOFBQjshqCpkN9sCA

##### Problem with DBIx::Class/DBIx::Class::Schema::Loader
# it cannot ADD COLUMN plevel varchar GENERATED ALWAYS AS (...) STORED
# so remove the default_value for the ORM and put it back with SQL in
# Test::Smoke::Gateway::Schema::deploy()
#
my $_plevel_column = __PACKAGE__->column_info('plevel');
__PACKAGE__->remove_column('plevel');
delete($_plevel_column->{default_value});
__PACKAGE__->add_column('plevel', $_plevel_column);

sub arch_os_version_key {
    my $self = shift;
    return join( "##", $self->architecture, $self->osname, $self->osversion, $self->hostname);
}

sub arch_os_version_label {
    my $self = shift;
    return join( " - ", $self->architecture, $self->osname, $self->osversion, $self->hostname);
}

sub arch_os_version_pair {
    my $self = shift;
    return {value => $self->arch_os_version_key, label => $self->arch_os_version_label};
}

my %io_env_order_map = (
    minitest => 1,
    stdio    => 2,
    perlio   => 3,
    locale   => 4,
);
my $max_io_envs = scalar(keys %io_env_order_map);

sub title {
    my $self = shift;

    return join(
        " ",
        "Smoke",
        $self->git_describe,
        $self->summary,
        $self->osname,
        $self->osversion,
        $self->cpu_description,
        $self->cpu_count
    );
}

sub list_title {
    my $self = shift;

    return join(
        " ",
        $self->git_describe,
        $self->osname,
        $self->osversion,
        $self->cpu_description,
        $self->cpu_count
    );
}

sub c_compilers {
    my $self = shift;

    my %c_compiler_seen;
    my $i = 1;
    for my $config ($self->configs) {
        $c_compiler_seen{$config->c_compiler_key} //= {
            index     => $i++,
            key       => $config->c_compiler_key,
            cc        => $config->cc,
            ccversion => $config->ccversion,
        };
    }
    return [
        sort {
            $a->{index} <=> $b->{index}
        } values %c_compiler_seen
    ];
}

sub matrix {
    my $self = shift;

    my %c_compilers = map {
        $_->{key} => $_
    } @{$self->c_compilers};

    my (%matrix, %cfg_order, %io_env_seen);
    my $o = 0;
    for my $config ($self->configs) {
        for my $result ($config->results) {
            my $cc_index = $c_compilers{$config->c_compiler_key}{index};

            $matrix{$cc_index}{$config->debugging}{$config->arguments}{$result->io_env} =
                $result->summary;
            $io_env_seen{$result->io_env} = $result->locale;
        }
        $cfg_order{$config->arguments} //= $o++;
    }

    my @io_env_in_order = sort {
        $io_env_order_map{$a} <=> $io_env_order_map{$b}
    } keys %io_env_seen;

    my @cfg_in_order = sort {
        $cfg_order{$a} <=> $cfg_order{$b}
    } keys %cfg_order;

    my @matrix;
    for my $cc (sort { $a->{index} <=> $b->{index} } values %c_compilers) {
        my $cc_index = $cc->{index};
        for my $cfg (@cfg_in_order) {
            my @line;
            for my $debugging (qw/ N D /) {
                for my $io_env (@io_env_in_order) {
                    push(
                        @line,
                        $matrix{$cc_index}{$debugging}{$cfg}{$io_env} || '-'
                    );
                }
            }
            while (@line < 8) { push @line, " " }
            my $mline = join("  ", @line);
            push @matrix, "$mline  $cfg (\*$cc_index)";
        }
    }
    my @legend = $self->matrix_legend(
        [
            map { $io_env_seen{$_} ? "$_:$io_env_seen{$_}" : $_ }
                @io_env_in_order
        ]
    );
    return @matrix, @legend;
}

sub matrix_legend {
    my $self = shift;
    my ($io_envs) = @_;

    my @legend = (
        (map "$_ DEBUGGING", reverse @$io_envs),
        (reverse @$io_envs)
    );
    my $first_line = join("  ", ("|") x @legend);

    my $length = (3 * 2 * $max_io_envs) - 2;
    for my $i (0 .. $#legend) {
        my $bar_count = scalar(@legend) - $i;
        my $prefix = join("  ", ("|") x $bar_count);
        $prefix =~ s/(.*)\|$/$1+/;
        my $dash_count = $length - length($prefix);
        $prefix .= "-" x $dash_count;
        $legend[$i] = "$prefix  $legend[$i]"
    }
    unshift @legend, $first_line;
    return @legend;
}

sub test_failures {
    my $self = shift;
    return $self->group_tests_by_status('FAILED');
}

sub test_todo_passed {
    my $self = shift;
    return $self->group_tests_by_status('PASSED');
}

sub group_tests_by_status {
    my $self = shift;
    my ($group_status) = @_;

    use Data::Dumper; $Data::Dumper::Indent = 1; $Data::Dumper::Sortkeys = 1;

    my %c_compilers = map {
        $_->{key} => $_
    } @{$self->c_compilers};

    my (%tests);
    my $max_name_length = 0;
    for my $config ($self->configs) {
        for my $result ($config->results) {
            for my $io_env ($result->failures_for_env) {
                for my $test ($io_env->failure) {
                    next if $test->status ne $group_status;

                    $max_name_length = length($test->test)
                        if length($test->test) > $max_name_length;

                    my $key = $test->test . $test->extra;
                    push(
                        @{$tests{$key}{$config->full_arguments}{test}}, {
                            test_env => $result->test_env,
                            test     => { $test->get_inflated_columns },
                        }
                    );
                }
            }
        }
    }
    my @grouped_tests;
    for my $group (values %tests) {
        push @grouped_tests, {test => undef, configs => [ ]};
        for my $cfg (keys %$group) {
            push @{ $grouped_tests[-1]->{configs} }, {
                arguments => $cfg,
                io_envs   => join("/", map $_->{test_env}, @{ $group->{$cfg}{test} })
            };
            $grouped_tests[-1]{test} //= $group->{$cfg}{test}[0]{test};
        }
    }
    return \@grouped_tests;
}

sub duration_in_hhmm {
    my $self = shift;
    return time_in_hhmm($self->duration);
}

sub average_in_hhmm {
    my $self = shift;
    return time_in_hhmm($self->duration/$self->config_count);
}

sub time_in_hhmm {
    my $diff = shift;

    # Only show decimal point for diffs < 5 minutes
    my $digits = $diff =~ /\./ ? $diff < 5*60 ? 3 : 0 : 0;
    my $days = int( $diff / (24*60*60) );
    $diff -= 24*60*60 * $days;
    my $hour = int( $diff / (60*60) );
    $diff -= 60*60 * $hour;
    my $mins = int( $diff / 60 );
    $diff -=  60 * $mins;
    $diff = sprintf "%.${digits}f", $diff;

    my @parts;
    $days and push @parts, sprintf "%d day%s",   $days, $days == 1 ? "" : 's';
    $hour and push @parts, sprintf "%d hour%s",  $hour, $hour == 1 ? "" : 's';
    $mins and push @parts, sprintf "%d minute%s",$mins, $mins == 1 ? "" : 's';
    $diff && !$days && !$hour and push @parts, "$diff seconds";

    return join " ", @parts;
}

=head2 $record->as_hashref([$is_full])

Returns a HashRef with the inflated columns.

=head3 Parameters

Positional:

=over

=item 1. C<'full'>

If the word C<full> is passed as the first argument the related
C<configs> are also included in the resulting HashRef.

=back

=cut

sub as_hashref {
    my $self = shift;
    my ($is_full) = @_;

    my $record = { $self->get_inflated_columns };
    $record->{smoke_date} = $self->smoke_date->rfc3339 if $self->smoke_date;

    if ($is_full eq 'full') {
        $record->{configs} = [ map { $_->as_hashref($is_full) } $self->configs ];
    }

    return $record;
}

1;

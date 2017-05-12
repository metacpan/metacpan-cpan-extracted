package Schedule::LongSteps::Storage::AutoDBIx::Schema::Result::LongstepProcess;
$Schedule::LongSteps::Storage::AutoDBIx::Schema::Result::LongstepProcess::VERSION = '0.015';
use strict;
use warnings;
use base qw/DBIx::Class::Core/;
__PACKAGE__->table('schedule_longsteps_process');
__PACKAGE__->load_components(qw/InflateColumn::DateTime InflateColumn::Serializer/);
__PACKAGE__->add_columns(
    id =>
        { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    process_class =>
        { data_type => "varchar", is_nullable => 0, size => 255 },
    what =>
        { data_type => "varchar", is_nullable => 1, size => 255 },
    status =>
        { data_type => "varchar", is_nullable => 0, size => 50 , default_value => 'pending' },
    run_at =>
        { data_type => "datetime", datetime_undef_if_invalid => 1, is_nullable => 1 },
    run_id =>
        { data_type => "varchar", is_nullable => 1, size => 36 },
    state =>
        { data_type => "text",
          serializer_class => 'JSON',
          is_nullable => 0,
      },
    error =>
        { data_type => "text", is_nullable => 1 }
    );

__PACKAGE__->set_primary_key("id");

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_longprocess_run_id', fields => ['run_id']);
    $sqlt_table->add_index(name => 'idx_longprocess_run_at', fields => ['run_at']);
}
1;

__END__

=head1 NAME

Schedule::LongSteps::Storage::AutoDBIx::Schema::Result::LongstepProcess - A built in DBIx::Class resultset for the AutoDBIx storage schema

=head2 sqlt_deploy_hook

See superclass L<DBIx::Class::Core>

=cut

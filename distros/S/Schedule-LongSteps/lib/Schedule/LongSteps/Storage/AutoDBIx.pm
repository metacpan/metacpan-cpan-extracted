package Schedule::LongSteps::Storage::AutoDBIx;
$Schedule::LongSteps::Storage::AutoDBIx::VERSION = '0.020';
use Moose;
extends qw/Schedule::LongSteps::Storage/;

use Log::Any qw/$log/;

use Schedule::LongSteps::Storage::DBIxClass;
use Schedule::LongSteps::Storage::AutoDBIx::Schema;

use DateTime;

has 'get_dbh' => ( is => 'ro', isa => 'CodeRef' , required => 1 );
has 'auto_deploy' => ( is => 'ro', isa => 'Bool', default => 1 );

has 'dbix_class_storage' => ( is => 'ro', isa => 'Schedule::LongSteps::Storage::DBIxClass' , lazy_build => 1 , handles => [qw/prepare_due_processes create_process find_process/]);
has 'schema' => ( is => 'ro', isa => 'Schedule::LongSteps::Storage::AutoDBIx::Schema' , lazy_build => 1);

sub _build_schema{
    my ($self) = @_;
    my $schema = Schedule::LongSteps::Storage::AutoDBIx::Schema->connect( $self->get_dbh() );
    if( $self->auto_deploy() ){
        # Attempt selecting something from the resultset.
        eval{
            my $count = $schema->resultset('LongstepProcess')->search(undef, { rows => 1 })->first();
        };
        if( my $err = $@ ){
            $log->warn("Got error: ".$err.". Will try to fix it by deploying the internal schema");
            $schema->deploy();
        }
    }
    return $schema;
}

sub _build_dbix_class_storage{
    my ($self) = @_;
    my $storage = Schedule::LongSteps::Storage::DBIxClass->new({ schema => $self->schema(),
                                                                 resultset_name => 'LongstepProcess'
                                                             });
}

=head1 NAME

Schedule::LongSteps::Storage::AutoDBIx - An automatically deployed storage.

=head1 DEPENDENCIES

To use this, you will have to add the following dependencies to your dependency manager:

L<DBIx::Class>, L<SQL::Translator>, L<DBIx::Class::InflateColumn::Serializer>, and one
of DateTime::Format::* matching your database.

=head1 SYNOPSIS

First instantiate a storage with a subroutine returning a valid $dbh (from L<DBI> for instance,
or from your own L<DBIx::Class::Schema>)):

  my $storage = Schedule::LongSteps::Storage::AutoDBIx->new({
                     get_dbh => sub{ return a valid $dbh },
                });

Note that this will automatically create a table named 'schedule_longsteps_process'
in your database. This is not configurable for now. That also means that building such
a storage is slow, so try to do it only once in your application.

Then build and use a L<Schedule::LongSteps> object:

  my $long_steps = Schedule::LongSteps->new({ storage => $storage });

  ...

=head1 ATTRIBUTES

=over

=item get_dbh

A subroutine that returns a valid $dbh (from L<DBI>) database connection handle. Required.

=item auto_deploy

Set that to false if you dont want this to deploy its built in schema automatically. Defaults to 1.

=back

=head2 prepare_due_processes

See L<Schedule::LongSteps::Storage>

=cut

=head2 create_process

See L<Schedule::LongSteps::Storage>

=cut

=head2 find_process

See L<Schedule::LongSteps::Storage>

=cut

=head2 deploy

Deploys this in the given dbh. Use this only ONCE if 'auto_deploy' is false.

Usage:

 $this->deploy();

=cut

sub deploy{
    my ($self) = @_;
    return $self->schema()->deploy();
}

__PACKAGE__->meta->make_immutable();

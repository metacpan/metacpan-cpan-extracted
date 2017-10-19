package Schedule::LongSteps::Storage::AutoDBIx::Schema;
$Schedule::LongSteps::Storage::AutoDBIx::Schema::VERSION = '0.020';
use strict;
use warnings;
use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes({ 'Schedule::LongSteps::Storage::AutoDBIx::Schema::Result' => [ 'LongstepProcess' ] });

sub connection{
    my ($class, @args ) = @_;
    unless( ( ref $args[0] || '' ) eq 'CODE' ){
        defined( $args[3] ) or ( $args[3] = {} );
        $args[3]->{AutoCommit} = 1;
        $args[3]->{RaiseError} = 1;
        $args[3]->{mysql_enable_utf8} = 1;
        ## Only for mysql DSNs
        $args[3]->{on_connect_do} = ["SET SESSION sql_mode = 'TRADITIONAL'"];
    }
    my $self = $class->next::method(@args);
    return $self;
}
1;
__END__

=head1 NAME

Schedule::LongSteps::Storage::AutoDBIx::Schema - A built-in DBIx::Class Schema for the AutoDBIx storage

=head2 connection

See superclass L<DBIx::Class::Schema>

=cut

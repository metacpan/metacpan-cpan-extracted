package Test::DBIx::Class::Stats::Profiler;
use Moo;
use MooX::HandlesVia;
use Time::HiRes;

our $VERSION = 0.02;

=head1 NAME

Test::DBIC::Profiler - a simple DBIC profiler

=head1 SYNOPSIS

See L<Test::DBIC::Calls> for how to use.
This class extends L<DBIx::Class::Storage::Statistics> and could
alternatively be used as per that class.

=head1 METHODS

=over 4

=item C<call_count>

Returns the number of calls made to the database.

=item C<all_calls>

Returns a list of calls made, as an array of hashes:

    [ { sql => ..., params => [...], elapsed => ... }, ... ]

=back

=cut

extends 'DBIx::Class::Storage::Statistics';

has start => (
    is => 'rw',
);

has calls => (
    is => 'lazy',
    default => sub { [] },
    handles_via => 'Array',
    handles => {
        all_calls => 'elements',
        add_call  => 'push',
        call_count => 'count',
    },
);

sub print { } # silence logging

sub query_start {
    my $self = shift();
    my $sql = shift();
    my @params = @_;

    $self->start( time() );
}
 
sub query_end {
    my $self = shift();
    my $sql = shift();
    my @params = @_;
 
    my $elapsed = time() - $self->start;

    $self->add_call({
        sql => $sql,
        params => \@params,
        elapsed => $elapsed
    });
}

=head1 AUTHOR

osfameron <osfameron@cpan.org> 2014-2017
Alexander Hartmaier <abraxxa@cpan.org> 2017

=cut

1;

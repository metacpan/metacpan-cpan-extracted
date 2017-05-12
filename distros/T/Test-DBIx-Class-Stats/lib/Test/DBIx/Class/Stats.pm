package Test::DBIx::Class::Stats;
use parent 'Test::Builder::Module';
use Test::DBIx::Class::Stats::Profiler;

our $VERSION = 0.02;
our @EXPORT = qw( with_stats );

=head1 NAME

Test::DBIx::Class::Stats - test statistics about your DBIx::Class calls

=head1 SYNOPSIS

Run a subtest with a debugging object (L<Test::DBIx::Class::Stats::Profiler>) set to capture
the number of calls that have been made to the database. This may be useful to
check your assumptions about prefetching, etc.

    use Test::More;
    use Test::DBIx::Class::Stats;

    # if you are using Test::DBIx::Class or similar, we can get the 
    # database handle from the `Schema` method
    use Test::DBIx::Class;

    with_stats 'test 1', sub {
        my $stats = shift;

        my $rs = Schema->resultset('Foo')->search();
        is $stats->call_count, 0, 'No calls on preparing RS';

        my @foo = $rs->all;
        is $stats->call_count, 1, '1 call after preparing RS';
    };

    # alternatively, we can pass it in explicitly:
    
    my $db = Schema
    with_stats 'test 2', $db, sub {
        ...
    };

=head1 EXPORTED FUNCTIONS

=over 4

=item C<with_stats $name, [$db], $code>

The L<Test::DBIx::Class::Stats::Profiler> object is created for the database
and is passed to your code reference as its first and only argument.

If C<$db> is not passed, the caller's C<Schema> function will be called.  This
is designed to work with L<Test::DBIx::Class>.

=back

=cut

sub with_stats {
    my ($name, @args) = @_;

    my $subtest = pop @args;
    my $db = @args ? shift @args : caller->Schema;

    my $storage = $db->storage;
    my %old = (
        debug    => $storage->debug,
        debugobj => $storage->debugobj,
    );
    my $stats = Test::DBIx::Class::Stats::Profiler->new();
    $storage->debug(1);
    $storage->debugobj( $stats );

    my $tb = __PACKAGE__->builder;
    $tb->subtest( "With stats: $name", $subtest, $stats );

    $storage->debug( $old{debug} );
    $storage->debugobj( $old{debugobj} );
}

=head1 AUTHOR

osfameron <osfameron@cpan.org> 2014-2017
Alexander Hartmaier <abraxxa@cpan.org> 2017

=cut

1;

#!perl
#

use strict;
use warnings;

package Rose::DBx::CannedQuery::Glycosylated;

our ($VERSION) = '1.01';

use Carp;
use Scalar::Util;

use Moo 2;
use Types::Standard qw/ Str /;

extends 'Rose::DBx::CannedQuery';
with 'MooX::Role::Chatty';

has 'name' => ( is => 'ro', isa => Str, lazy => 1, builder => '_build_name' );

sub _build_name {
    my $self = shift;
    substr( $self->sql, 0, 32 );
}

sub do_one_query_ref {
    my ( $self, $bind_vals, $opts ) = @_;
    $bind_vals ||= [];
    $opts ||= [ {} ];
    $opts = [ {}, $opts ] unless ref $opts;
    my $verbose = $self->verbose;
    my ($rslt);

    if ( $verbose > 2 ) {
        require Data::Dumper;
        my $optstr = Data::Dumper->new($opts)->Terse(1)->Pad("\t")->Dump;
        $optstr =~ s/\n+$//;
        $optstr =~ s/\n\s*/, /g;
        $self->remark(
                'Executing '
              . $self->name
              . (
                @$bind_vals
                ? " with bind values:\n"
                  . join( "\n", map { "\t$_" } @$bind_vals ) . "\n"
                : ' '
              )
              . "with query modifiers:\n$optstr"
        );
    }

    $rslt = $self->resultref( $bind_vals, $opts );
    $self->remark( 'Got ' . scalar(@$rslt) . ' results' ) if $verbose > 2;

    return $rslt;
}

sub do_one_query {
    return @{ shift->do_one_query_ref( \@_ ) };
}

sub do_many_queries {
    my ( $self, $param_sets ) = @_;
    $param_sets ||= [ [] ];
    my $array_of_sets = Scalar::Util::reftype($param_sets) eq 'ARRAY';
    my $verbose       = $self->verbose;
    my (%rslt);

    if ($array_of_sets) {
        my $i = 'Element0000';
        $param_sets = { map { $i++ => $_ } @$param_sets };
    }

    foreach my $bind_name ( sort keys %$param_sets ) {
        my $bind_vals = $param_sets->{$bind_name} || [];
        $self->remark(
            "Executing bind set $bind_name for query " . $self->name )
          if $verbose > 1;
        if ( ref $bind_vals->[0] eq 'ARRAY' ) {

            # We actually have a tuple of $bind_values, $fetch_values
            $rslt{$bind_name} = $self->do_one_query_ref(@$bind_vals);
        }
        else {
            # Just plain old bind values; don't dereference further
            $rslt{$bind_name} = $self->do_one_query_ref($bind_vals);
        }
    }

    return $array_of_sets
      ? [ map { $rslt{$_} } sort keys %rslt ]
      : \%rslt;
}

1;

__END__

=head1 NAME

Rose::DBx::CannedQuery::Glycosylated - Some sugar for Rose::DBx::CannedQuery

=head1 SYNOPSIS

  use Rose::DBx::CannedQuery::Glycosylated;
  my $qry = Rose::DBx::CannedQuery::Glycosylated->new(
              rdb_class => 'My::DB',
              rdb_params => { type => 'real', domain => 'some' },
              sql => 'SELECT * FROM table WHERE attr = ?',
              verbose => 3, logger => $my_debug_logsink,
              name => "$table scan"
            );

  # Typical CannedQuery execution, with trace messages built in
  foreach my $row_hash ( $qry->do_one_query(@bind_vals) ) {
    do_something($row_hash);
  }

  # Resultset too big to copy?  Fetch just a chunk, and use array
  # references rather than hash references
  foreach my $row ( $qry->do_one_query_ref($bind_ref, [ [], 2000 ]) ) {
    do_something($row);
  }

  # Package up several query executions, again with trace messages
  my %conditions = assemble_query_criteria();
  generate_result_table($qry->do_many_queries(\%conditions));
    

=head1 DESCRIPTION

This class provides a lightly sweetened flavor of
L<Rose::DBx::CannedQuery>, intended to simplify the job of running
multiple instances of a particular query, while providing feedback to
the user.  It doesn't (much) alter the way the query interacts with
the database, but is intended to abstract out some of the "chrome"
often repeated in code that tried to keep the user informed as the
queries execute.

=head2 ATTRIBUTES

Instances of F<Rose::DBx::CannedQuery::Glycosylated> have all of the
attributes supplied by L<Rose::DBx::CannedQuery> and
L<MooX::Role::Chatty>.  In addition, one new attribute is added:

=over 4

=item name

A string identifying this particular query; it is used in log messages
to help you figure out which query is executing.

If you do not provide a value, it defaults to the start of the SQL
used to build the query.

=back

=head2 METHODS

=over 4

=item B<do_one_query>([I<@bind_values>])

Execute the query, passing the list of bind values specified in
I<@bind_values>, analogously to L<Rose::DBx::CannedQuery::results>.
Returns the list of resultant rows in array context, or the number of
rows returned in scalar context.

If the L<MooX::Role::Chatty/verbose> attribute is 3 or higher, an
informational message is output (showing the bind values, if any)
prior to execution, and a second message showing the result count is
output after execution.

=item B<do_one_query_ref>([I<$bind_values>, I<$query_opts>])

Execute the query, passing the bind values specified in
I<$bind_values>, which must be a reference to an array of bind values,
as documented in L<Rose::DBx::CannedQuery/resultref>.  Returns the
array reference containng the results of the query.

If I<query_opts> is an array reference, it is passed unchanged to
L<Rose::DBx::CannedQuery/resultref>.  If it is a simple
(non-reference) scalar, the value is passed to
L<DBI/fetchall_arrayref> as the C<$max_rows> parameter.  If you want
resultset rows as array references for efficiency, or want to actually
retrieve a slice of the results for each row, you need to supply
I<query_opts> as an array reference that provides C<$slice>, and
optionally C<$max_rows>.

If the C<verbose> attribute is 3 or higher, an informational message
is output (showing the bind values, if any) prior to execution, and a
second message showing the result count is output after execution.

=item B<do_many_queries>([I<$param_sets>])

Execute the query several times via L</do_one_query>, using different
bind values (and possibly query options) each time, and collect the
results.

The I<$param_sets> parameter is typically a hash reference, where the
keys are strings naming each set of parameters.  If you don't care to name
your sets of bind values, you may also simply pass in a reference to
an array of (array references containing) query parameters.

The value of each element in I<$param_sets> is an array reference. If
the array contains simple sclars, they are treated as a list of bind
parameter values.  If the first element is itself an array reference,
then that element is used as I<$bind_vals> and the next element as
I<$query_opts> (as taken by L</do_one_query_ref>).

If you pass in I<$param_sets> as a hash reference, the return value is a
hash reference, with the keys again being the names of the parameter
sets, and the values being array references containing the results for
that set of bind values.  If you pass in an array reference, an
array reference is returned, which contains array references holding
the results for each parameter set; unsurprisingly, resultset
elements are in the same order as the bind value sets you passed in.

Trace messages are output as described above for L</do_one_query>.  In
addition, if the C<verbose> attribute is 2 or higher, an informational
message is output for each bind set.

=back

=head1 EXPORT

None.

=head1 SEE ALSO

L<Rose::DBx::CannedQuery> and L<MooX::Role::Chatty> for more
information on specific behavior.

L<Rose::DBx::MoreConfig> (or L<Rose::DB>) for more information on
managing the underlying L<DBI> conncetions.

=head1 BUGS AND CAVEATS

Are there, for certain, but have yet to be cataloged.

=head1 VERSION

version 1.01

=head1 AUTHOR

Charles Bailey <cbail@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Charles Bailey

This software may be used under the terms of the Artistic License or
the GNU General Public License, as the user prefers.

=cut

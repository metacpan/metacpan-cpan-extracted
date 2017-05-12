package Runops::Trace;
# ABSTRACT: Trace your program's execution

# vim:shiftwidth=4

use strict;
use warnings;
use Digest::MD5  ();
use File::Spec   ();
use Scalar::Util ();

our $VERSION = '0.14';

use DynaLoader ();
our @ISA = qw( DynaLoader Exporter );
Runops::Trace->bootstrap($VERSION);

our @EXPORT_OK = qw(
    trace_code checksum_code_path trace

    set_tracer get_tracer clear_tracer enable_tracing disable_tracing tracing_enabled

    set_trace_threshold get_trace_threshold get_op_counters
);

our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

sub checksum_code_path {
    my ($f) = @_;

    # Preallocate a 2**19 byte long string. See
    # http://perlmonks.org/?node_id=630323
    open my $nul, '<', File::Spec->devnull;
    my $ops = '';
    sysread $nul, $ops, 2**19, 0;

    # Just stash the pointers.
    _trace_function( sub { $ops .= ${ $_[0] || return } }, $f );

    return Digest::MD5::md5_hex($ops);
}

sub trace_code {
    my ($f) = @_;
    my @ops;
    _trace_function( sub { push @ops, $_[0] }, $f );

    return wantarray ? @ops : join "\n", @ops;
}

sub trace {
    my ( $tracer, $callback ) = @_;

    _trace_function( $tracer, $callback );
    return;
}

sub unmask_op {
    unmask_op_type( _whatever_to_op_type($_) ) for @_;
}

sub mask_op {
    mask_op_type( _whatever_to_op_type($_) ) for @_;
}

sub _whatever_to_op_type {
    my $thingy = shift;

    if ( ref $thingy ) {
        return $thingy->type;
    } elsif ( Scalar::Util::looks_like_number($thingy) ) {
        return $thingy;
    } else {
        require B;
        return B::opnumber($thingy);
    }
}

1;



=pod

=head1 NAME

Runops::Trace - Trace your program's execution

=head1 VERSION

version 0.14

=head1 SYNOPSIS

Per function tracing:

  use Runops::Trace 'checksum_code_path';
  sub is_even { shift() % 2 == 0 ? 1 : 0 }

  my %sufficient;
  for my $number ( 0 .. 10 ) {
      # Get a signature for the code 
      my $codepath = checksum_code_path(
          sub { is_even( $number ) }
      );

      if ( not exists $sufficient{$codepath} ) {
          $sufficient{$codepath} = $number;
      }
  }
  print join ' ', keys %sufficient;

Global tracing

=head1 DESCRIPTION

This module traces opcodes as they are executed by the perl VM. The
trace function can be turned on globally or just during the execution
of a single function.

=head1 INTERFACE

=over

=item trace( TRACE, FUNCTION )

This is a generic way of tracing a function. It ensures that your
C<TRACE> function is called before every operation in the C<FUNCTION>
function.

The C<TRACE> function will be given the pointer of the opnode that is
about to be run. This is an interim API. The desired result is that a
B::OP object is passed instead of just the pointer. Also, it is always
the same scalar - only the value is changing. References taken to this
value will mutate. The C<TRACE> function will be called in void
context.

The C<FUNCTION> function will be called in void context and will not
be given any parameters.

There is no useful return value from this function.

=item MD5SUM = checksum_code_path( FUNCTION )

This returns a hex MD5 checksum of the ops that were visited. This is
a nice, concise way of representing a unique path through code.

=item STRING = trace_code( FUNCTION )

=item ARRAY = trace_code( FUNCTION )

This returns a string representing the ops that were executed. Each op
is represented as its name and hex address in memory.

If called in list context will return the list of L<B::OP> objects.

=item set_tracer( FUNCTION )

This sets the tracer function globally.

C<trace> uses this.

The code reference will be called once per op. The first argument is the
L<B::OP> object for C<PL_op>. The second argument is the operator's arity. This
might later be changed if arity methods are included in L<B::OP> itself. The
remaining arguments are the arguments for the operator taken from the stack,
depending on the operator arity.

=item CODEREF = get_tracer()

Get the tracing sub (if any).

=item clear_tracer()

Remove the tracing sub.

=item enable_tracing()

=item disable_tracing()

Controls tracing globally.

=item tracing_enabled()

Returns whether or not tracing is enabled.

=item set_trace_threshold( INT )

=item INT = get_trace_threshold()

=item HASHREF = get_op_counters()

If set to a nonzero value then every opcode will be counted in a hash
(C<get_op_counters> returns that hash).

The trace function would only be triggerred after the counter for that opcode
has reached a certain number.

This is useful for when you only want to trace a certain hot path.

=item mask_all()

Disable tracing of all ops.

=item mask_none()

=item unmask_all()

Enable tracing of all ops.

=item mask_op( OPTYPE )

=item unmask_op( OPTYPE )

Change the masking of a specific op.

Takes a L<B::OP> object, an op type, or an op name.

=item clear_mask()

Like C<mask_none> was called, but removes the mask entirely.

=item ARITY_NULL

=item ARITY_UNARY

=item ARITY_BINARY

=item ARITY_LIST

=item ARITY_LIST_UNARY

=item ARITY_LIST_BINARY

=item ARITY_UNKNOWN

These constants can be used to inspect the arity paramter.

Note that for C<ARITY_LIST_UNARY> (C<entersub>) and C<ARITY_LIST_BINARY>
(C<aassign>) the arity value is the binary or of C<ARITY_LIST> and
C<ARITY_UNARY> or C<ARITY_BINARY>. Test with C<&> or with C<==> according to
what you are really interested in.

C<ARITY_NULL> means no arguments (e.g. an C<SVOP>).

Some operators do not have their arity figured out yet. Patches welcome.

This should ideally become a method of L<B::OP> later.

=back

=head1 PERL HACKS COMPATIBILITY

This module does not currently implement the interface as described in
the O'Reilly book Perl Hacks.

=head1 ADVANCED NOTES

=over

=item THREAD-UNSAFE

I made no attempt at thread safety. Do not use this module in a
multi-threaded process.

=item WRITE YOUR OWN SUGAR

The C<trace( TRACE, FUNCTION )> function is sufficient to allow any
arbitrary kind of access to running code. This module is included with
two simple functions to return useful values. Consider looking at
their source code and writing your own.

=item ON THE FLY CODE MODIFICATION

If the L<B::Generate> module is loaded, the B:: object that is passed
to the tracing function may also be modified. This would allow you to
modify the perl program as it is running. Thi

=back

=head1 AUTHOR

Rewritten by Joshua ben Jore, originally written by chromatic, based
on L<Runops::Switch> by Rafael Garcia-Suarez.

Merged with Runops::Hook by Chia-Liang Kao and Yuval Kogman.

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl 5.8.x itself.

=head1 AUTHOR

Josh Jore <jjore@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Josh Jore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


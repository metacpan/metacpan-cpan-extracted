package Opcodes;

use 5.006_001;
use strict;

our($VERSION, @ISA, @EXPORT, @EXPORT_OK);

$VERSION = "0.14";

use Exporter ();
use XSLoader ();

BEGIN {
    @ISA = qw(Exporter);
    @EXPORT =
      qw(opcodes opname opname2code opflags opaliases
	 opargs opclass opdesc opname
	 OA_CLASS_MASK
	 OA_MARK
	 OA_FOLDCONST
	 OA_RETSCALAR
	 OA_TARGET
	 OA_RETINTEGER
	 OA_OTHERINT
	 OA_DANGEROUS
	 OA_DEFGV
	 OA_TARGLEX

	 OA_BASEOP
	 OA_UNOP
	 OA_BINOP
	 OA_LOGOP
	 OA_LISTOP
	 OA_PMOP
	 OA_SVOP
	 OA_PADOP
	 OA_PVOP_OR_SVOP
	 OA_LOOP
	 OA_COP
	 OA_BASEOP_OR_UNOP
	 OA_FILESTATOP
	 OA_LOOPEXOP

	 OA_SCALAR
	 OA_LIST
	 OA_AVREF
	 OA_HVREF
	 OA_CVREF
	 OA_FILEREF
	 OA_SCALARREF
	 OA_OPTIONAL

	 OA_NOSTACK
	 OA_MAYSCALAR
	 OA_MAYARRAY
	 OA_MAYVOID
	 OA_RETFIXED
	 OA_MAYBRANCH
	);
    @EXPORT_OK = qw(ppaddr check argnum maybranch);
}
use subs @EXPORT_OK;

sub AUTOLOAD {
    # 'autoload' constants from the constant() XS function.
    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    die "&Opcodes::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { die $error; }
    {
        no strict 'refs';
	*$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

XSLoader::load 'Opcodes', $VERSION;

our @opcodes = opcodes();

sub opname ($) {
    $opcodes[ $_[0] ]->[1];
}

sub ppaddr ($) {
    $opcodes[ $_[0] ]->[2];
}

sub check ($) {
    $opcodes[ $_[0] ]->[3];
}

sub opdesc ($) {
    Opcode::opdesc( opname( $_[0] ));
}

sub opargs ($) {
    $opcodes[ $_[0] ]->[4];
}

# n no_stack - A handcoded list of ops without any SP handling (Note: stack_base is allowed),
# i.e. no args + no return values.
# 'n' 512 is not encoded in opcode.pl. We could add it but then we would have to
# maintain it in CORE as well as here. Here its is needed for older perls. So
# keep it this way. Note that enter,entertry,leave indirectly use the stack.
our %no_stack = map{$_=>1}qw[null unstack scope lineseq
  next redo goto break continue nextstate dbstate pushmark
  regcmaybe regcreset];
# S retval may be scalar. s and i are automatically included
our %retval_scalar = map{$_=>1}qw[];
# A retval may be array
our %retval_array = map{$_=>1}qw[];
# V retval may be void
our %retval_void = map{$_=>1}qw[];
# F fixed retval type (S, A or V)
our %retval_fixed = map{$_=>1}qw[];
# N  pp_* may return other than op_next
our %maybranch = map{$_=>1}
  # LOGOP's which return op_other
  qw[once cond_expr and or orassign andassign dor dorassign grepwhile mapwhile substcont
     enterwhen entergiven range
    ],
  # other OPs
  qw[formline grepstart flip dbstate goto leaveeval
     break
     subst entersub
     return last next redo require entereval entertry continue dump
    ];

sub opflags ($) {
    # 0x1ff = 9 bits OCSHIFT
    my $OCSHIFT = constant('OCSHIFT'); 	# 9
    my $mask = (2 ** $OCSHIFT) - 1;
    my $flags =  opargs($_[0]) & $mask; # & 0x1ff
    # now the extras
    my $opname = opname($_[0]);
    #$flags += 16  if $retint{$opname};
    $flags += 512  if $no_stack{$opname};
    $flags += 1024 if $retval_scalar{$opname} or $flags & 20; # 4|16
    $flags += 2048 if $retval_array{$opname};
    $flags += 4096 if $retval_void{$opname};
    $flags += 8192 if $retval_fixed{$opname};
    $flags += 16384 if maybranch($_[0]);
    return $flags;
}

# See F<opcode.pl> for $OASHIFT and $OCSHIFT. For flags n 512 we
# would have to change that.
sub opclass ($) {
    my $OCSHIFT = constant('OCSHIFT'); 	# 9
    my $OASHIFT = constant('OASHIFT');	# 13
    my $mask = (2 ** ($OASHIFT-$OCSHIFT)) - 1; # 0b1111 4bit 13-9=4 bits
    $mask = $mask << $OCSHIFT;		# 1e00: 4bit left-shifted by 9
    (opargs($_[0]) & $mask) >> $OCSHIFT;
}

sub argnum ($) {
    #my $ARGSHIFT = 4;
    #my $ARGBITS = 32;
    my $OASHIFT = constant('OASHIFT'); # 13
    # ffffe000 = 32-13 bits left-shifted by 13
    my $mask = ((2 ** (32-$OASHIFT)) - 1) << $OASHIFT;
    (opargs($_[0]) & $mask) >> $OASHIFT;
}

sub opaliases ($) {
    my $op = shift;
    my @aliases = ();
    my $ppaddr = ppaddr($op);
    for (@opcodes) {
      push @aliases, ($_->[0]) 
        if $_->[2] == $ppaddr and $_->[0] != $op;
    }
    @aliases;
}

sub opname2code ($) {
    my $name = shift;
    for (0..$#opcodes) { return $_ if opname($_) eq $name; }
    return undef;
}

# All LOGOPs: perl -Mblib -MOpcodes -e'$,=q( );print map {opname $_} grep {opclass($_) == 3} 1..opcodes' =>
#   regcomp substcont grepwhile mapwhile range and or dor cond_expr andassign orassign dorassign entergiven
#   enterwhen entertry once
# All pp which can return other then op_next (inspected pp*.c):
#   once and cond_expr or defined grepwhile
#   substcont formline grepstart mapwhile range flip dbstate goto leaveeval enterwhen break subst entersub
#   return last next redo require entereval entertry continue
# + aliases: maybranch  perl -MOpcodes -e'$,=q( );print map {opname $_} grep {opflags($_) & 16384} 1..opcodes'
# => subst substcont defined formline grepstart grepwhile mapwhile range and or dor cond_expr andassign
#    orassign dorassign dbstate return last next redo dump goto entergiven enterwhen require entereval
#    entertry once
sub maybranch ($) {
    return undef if opclass($_[0]) <= 2;	# NOT if lower than LOGOP
    my $opname = opname($_[0]);
    return 1 if $maybranch{$opname};
    for (opaliases($_[0])) {
        return 1 if $maybranch{opname($_)};
    }
    return undef;
}


1;
__END__

=head1 NAME

Opcodes - More Opcodes information from opnames.h and opcode.h

=head1 SYNOPSIS

  use Opcodes;
  print "Empty opcodes are null and ",
    join ",", map {opname $_}, opaliases(opname2code('null'));

  # All LOGOPs
  perl -MOpcodes -e'$,=q( );print map {opname $_} grep {opclass($_) == 2} 1..opcodes'

  # Ops which can return other than op->next
  perl -MOpcodes -e'$,=q( );print map {opname $_} grep {Opcodes::maybranch $_} 1..opcodes'


=head1 DESCRIPTION

=head1 Operator Names and Operator Lists

The canonical list of operator names is the contents of the array
PL_op_name, defined and initialised in file F<opcode.h> of the Perl
source distribution (and installed into the perl library).

Each operator has both a terse name (its opname) and a more verbose or
recognisable descriptive name. The opdesc function can be used to
return a the description for an OP.

=over 8

=item an operator name (opname)

Operator names are typically small lowercase words like enterloop,
leaveloop, last, next, redo etc. Sometimes they are rather cryptic
like gv2cv, i_ncmp and ftsvtx.

=item an OP opcode

The opcode information functions all take the integer code, 0..MAX0,
MAXO being accessed by scalar @opcodes, the length of
the opcodes array.

=back


=head1 Opcode Information

Retrieve information of the Opcodes. All are available for export by the package.
Functions names starting with "op" are automatically exported.

=over 8

=item opcodes

In a scalar context opcodes returns the number of opcodes in this
version of perl (361 with perl-5.10).

In a list context it returns a list of all the operators with
its properties, a list of [ opcode opname ppaddr check opargs ].

=item opname (OP)

Returns the lowercase name without pp_ for the OP,
an integer between 0 and MAXO.

=item ppaddr (OP)

Returns the address of the ppaddr, which can be used to
get the aliases for each opcode.

=item check (OP)

Returns the address of the check function.

=item opdesc (OP)

Returns the string description of the OP.

=item opargs (OP)

Returns the opcode args encoded as integer of the opcode.
See below or F<opcode.pl> for the encoding details.

  opflags 1-128 + opclass 1-13 << 9 + argnum 1-15.. << 13

=item argnum (OP)

Returns the arguments and types encoded as number acccording
to the following table, 4 bit for each argument.

    'S',  1,		# scalar
    'L',  2,		# list
    'A',  3,		# array value
    'H',  4,		# hash value
    'C',  5,		# code value
    'F',  6,		# file value
    'R',  7,		# scalar reference

  + '?',  8,            # optional

Example:

  argnum(opname2code('bless')) => 145
  145 = 0b10010001 => S S?

  first 4 bits 0001 => 1st arg is a Scalar,
  next 4 bits  1001 => (bit 8+1) 2nd arg is an optional Scalar

=item opclass (OP)

Returns the op class as number according to the following table
from F<opcode.pl>:

    '0',  0,		# baseop
    '1',  1,		# unop
    '2',  2,		# binop
    '|',  3,		# logop
    '@',  4,		# listop
    '/',  5,		# pmop
    '$',  6,		# svop_or_padop
    '#',  7,		# padop
    '"',  8,		# pvop_or_svop
    '{',  9,		# loop
    ';',  10,		# cop
    '%',  11,		# baseop_or_unop
    '-',  12,		# filestatop
    '}',  13,		# loopexop

=item opflags (OP)

Returns op flags as number according to the following table
from F<opcode.pl>. In doubt see your perl source.
I<Warning: There is currently an attempt to change that, but I posted a fix>

    'm' =>  OA_MARK,	 	# needs stack mark
    'f' =>  OA_FOLDCONST,	# fold constants
    's' =>  OA_RETSCALAR,	# always produces scalar
    't' =>  OA_TARGET,		# needs target scalar
    'T' =>  OA_TARGET | OA_TARGLEX,	# ... which may be lexical
    'i' =>  OA_RETINTEGER,	# always produces integer (this bit is in question)
    'I' =>  OA_OTHERINT,	# has corresponding int op
    'd' =>  OA_DANGEROUS,	# danger, unknown side effects
    'u' =>  OA_DEFGV,		# defaults to $_

plus not from F<opcode.pl>:

    'n' => OA_NOSTACK,		# nothing on the stack, no args and return
    'N' => OA_MAYBRANCH		# No next. may return other than PL_op->op_next, maybranch

These not yet:

    'S' =>  OA_MAYSCALAR 	# retval may be scalar
    'A' =>  OA_MAYARRAY 	# retval may be array
    'V' =>  OA_MAYVOID 		# retval may be void
    'F' =>  OA_RETFIXED 	# fixed retval type, either S or A or V

=item OA_* constants

All OA_ flag, class and argnum constants from F<op.h> are exported.
Addionally new OA_ flags have been created which are needed for L<B::CC>.

=item opaliases (OP)

Returns the opcodes for the aliased opcode functions for the given OP, the ops
with the same ppaddr.

=item opname2code (OPNAME)

Does a reverse lookup in the opcodes list to get the opcode for the given
name.

=item maybranch (OP)

Returns if the OP function may return not op->op_next.

Note that not all OP classes which have op->op_other, op->op_first or op->op_last
(higher then UNOP) are actually returning an other next op than op->op_next.

  opflags(OP) & 16384

=back

=head1 SEE ALSO

L<Opcode> -- The Perl CORE Opcode module for handling sets of Opcodes used by L<Safe>.

L<Safe> -- Opcode and namespace limited execution compartments

L<B::CC> -- The optimizing perl compiler uses this module. L<Jit> also,
            but only the static information

=head1 TEST REPORTS

CPAN Testers: L<http://cpantesters.org/distro/O/Opcodes>

Travis: L<https://travis-ci.org/rurban/Opcodes.png|https://travis-ci.org/rurban/Opcodes/>

Coveralls: L<https://coveralls.io/repos/rurban/Opcodes/badge.png|https://coveralls.io/r/rurban/Opcodes?branch=master>

=head1 AUTHOR

Reini Urban C<rurban@cpan.org> 2010, 2014

=head1 LICENSE

Copyright 1995, Malcom Beattie.
Copyright 1996, Tim Bunce.
Copyright 2010, 2014 Reini Urban.
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab shiftwidth=4:

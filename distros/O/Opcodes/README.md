# NAME

Opcodes - More Opcodes information from opnames.h and opcode.h

# SYNOPSIS

    use Opcodes;
    print "Empty opcodes are null and ",
      join ",", map {opname $_}, opaliases(opname2code('null'));

    # All LOGOPs
    perl -MOpcodes -e'$,=q( );print map {opname $_} grep {opclass($_) == 2} 1..opcodes'

    # Ops which can return other than op->next
    perl -MOpcodes -e'$,=q( );print map {opname $_} grep {Opcodes::maybranch $_} 1..opcodes'



# DESCRIPTION

# Operator Names and Operator Lists

The canonical list of operator names is the contents of the array
PL\_op\_name, defined and initialised in file `opcode.h` of the Perl
source distribution (and installed into the perl library).

Each operator has both a terse name (its opname) and a more verbose or
recognisable descriptive name. The opdesc function can be used to
return a the description for an OP.

- an operator name (opname)

    Operator names are typically small lowercase words like enterloop,
    leaveloop, last, next, redo etc. Sometimes they are rather cryptic
    like gv2cv, i\_ncmp and ftsvtx.

- an OP opcode

    The opcode information functions all take the integer code, 0..MAX0,
    MAXO being accessed by scalar @opcodes, the length of
    the opcodes array.



# Opcode Information

Retrieve information of the Opcodes. All are available for export by the package.
Functions names starting with "op" are automatically exported.

- opcodes

    In a scalar context opcodes returns the number of opcodes in this
    version of perl (361 with perl-5.10).

    In a list context it returns a list of all the operators with
    its properties, a list of \[ opcode opname ppaddr check opargs \].

- opname (OP)

    Returns the lowercase name without pp\_ for the OP,
    an integer between 0 and MAXO.

- ppaddr (OP)

    Returns the address of the ppaddr, which can be used to
    get the aliases for each opcode.

- check (OP)

    Returns the address of the check function.

- opdesc (OP)

    Returns the string description of the OP.

- opargs (OP)

    Returns the opcode args encoded as integer of the opcode.
    See below or `opcode.pl` for the encoding details.

        opflags 1-128 + opclass 1-13 << 9 + argnum 1-15.. << 13

- argnum (OP)

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

- opclass (OP)

    Returns the op class as number according to the following table
    from `opcode.pl`:

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

- opflags (OP)

    Returns op flags as number according to the following table
    from `opcode.pl`. In doubt see your perl source.
    _Warning: There is currently an attempt to change that, but I posted a fix_

        'm' =>  OA_MARK,	 	# needs stack mark
        'f' =>  OA_FOLDCONST,	# fold constants
        's' =>  OA_RETSCALAR,	# always produces scalar
        't' =>  OA_TARGET,		# needs target scalar
        'T' =>  OA_TARGET | OA_TARGLEX,	# ... which may be lexical
        'i' =>  OA_RETINTEGER,	# always produces integer (this bit is in question)
        'I' =>  OA_OTHERINT,	# has corresponding int op
        'd' =>  OA_DANGEROUS,	# danger, unknown side effects
        'u' =>  OA_DEFGV,		# defaults to $_

    plus not from `opcode.pl`:

        'n' => OA_NOSTACK,		# nothing on the stack, no args and return
        'N' => OA_MAYBRANCH		# No next. may return other than PL_op->op_next, maybranch

    These not yet:

        'S' =>  OA_MAYSCALAR 	# retval may be scalar
        'A' =>  OA_MAYARRAY 	# retval may be array
        'V' =>  OA_MAYVOID 		# retval may be void
        'F' =>  OA_RETFIXED 	# fixed retval type, either S or A or V

- OA\_\* constants

    All OA\_ flag, class and argnum constants from `op.h` are exported.
    Addionally new OA\_ flags have been created which are needed for [B::CC](https://metacpan.org/pod/B::CC).

- opaliases (OP)

    Returns the opcodes for the aliased opcode functions for the given OP, the ops
    with the same ppaddr.

- opname2code (OPNAME)

    Does a reverse lookup in the opcodes list to get the opcode for the given
    name.

- maybranch (OP)

    Returns if the OP function may return not op->op\_next.

    Note that not all OP classes which have op->op\_other, op->op\_first or op->op\_last
    (higher then UNOP) are actually returning an other next op than op->op\_next.

        opflags(OP) & 16384

# SEE ALSO

[Opcode](https://metacpan.org/pod/Opcode) -- The Perl CORE Opcode module for handling sets of Opcodes used by [Safe](https://metacpan.org/pod/Safe).

[Safe](https://metacpan.org/pod/Safe) -- Opcode and namespace limited execution compartments

[B::CC](https://metacpan.org/pod/B::CC) -- The optimizing perl compiler uses this module. [Jit](https://metacpan.org/pod/Jit) also,
            but only the static information

# TEST REPORTS

CPAN Testers: [http://cpantesters.org/distro/O/Opcodes](http://cpantesters.org/distro/O/Opcodes)

[![Travis](https://travis-ci.org/rurban/Opcodes.png)](https://travis-ci.org/rurban/Opcodes/)

[![Coveralls](https://coveralls.io/repos/rurban/Opcodes/badge.png)](https://coveralls.io/r/rurban/Opcodes?branch=master)

# AUTHOR

Reini Urban `rurban@cpan.org` 2010, 2014

# LICENSE

Copyright 1995, Malcom Beattie.
Copyright 1996, Tim Bunce.
Copyright 2010, 2014 Reini Urban.
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

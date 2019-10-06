Tangle.pm
====================

A classic quantum state emulator using Cayley-Dickson algebra

Install using CPAN:

     $ perl -MCPAN -e 'install Tangle'

Sample Usage:

    my $z1 = Tangle->new(0,1);
    $z1->hadamard;

    my $z2 = Tangle->new(0,1);
    $z2->x_gate;

    my $product    = $z1 * $z2;
    my $division   = $z1 / $z2;
    my $sum        = $z1 + $z2;
    my $difference = $z1 - $z2;
    
    my $z3 = $z2->tensor($z1);

    my $z4 = Tangle->new(0,0,-1,0);

    my $unit_quaternion = $z3 * $z4;

Status:

    I am stuck on the CNOT gate. I see references for the matrix representation online, but I am looking for the equivelent Quaternion multiplication process to produce the desired results.

Warning:

    This is a work in progress. Some things are known to not work.
    Please double check your Sedonion calculations by hand before depending on this program.

    Please contact me if you can describe the operation of the CNOT gate in terms of Quaternion operations.

COPYRIGHT AND LICENSE

    Copyright (C) 2019 by Jeff Anderson

see individual license in each package under LICENSE



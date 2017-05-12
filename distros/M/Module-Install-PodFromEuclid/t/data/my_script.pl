use strict;
use warnings;
use Getopt::Euclid;

for my $x (1 .. $ARGV{-size}{h}) {
    for my $y (1 .. $ARGV{-size}{w}) {
        my $length = $ARGV{-length};
        print "Computing with size $x x $y and length $length\n";
    }
}

__END__

=head1 NAME

yourprog - Your program here

=head1 VERSION

This documentation refers to yourprog version 1.9.4

=head1 USAGE

  yourprog [options]  -s[ize]=<h>x<w>  -o[ut][file] <file>

=head1 REQUIRED ARGUMENTS

=over

=item  -s[ize]=<h>x<w>

Specify size of simulation

=for Euclid:
    h.type:    int > 0
    h.default: 24
    w.type:    int >= 10
    w.default: 80

=back

=head1 OPTIONS

=over

=item  -l[[en][gth]] <l>

Length of simulation. The default is l.default

=for Euclid:
    l.type:    num
    l.default: 1.2


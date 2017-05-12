package Money::PaymentPreparer;

use warnings;
use strict;

=head1 NAME

Money::PaymentPreparer - change sum to bills and coins.

=head1 VERSION

Version 0.03

=cut

our $VERSION = "0.03";

=head1 SYNOPSIS

 use Money::PaymentPreparer;

 my @my_bills  = qw (200 100 50 20 10 5 2 1);

 my $object = PaymentPreparer->new();
 $object->set_bill(@my_bills);
 $object->add(153);
 $object->add(68);
 %result = $object->get();

=cut

sub new {
    my $class = shift;
    my $self  = {};
    $self->{units} = undef;
    $self->{bills} = undef;
    bless $self, $class;
}

sub set_bill {
    my $self = shift;
    @{ $self->{units} } = @_;
    %{ $self->{bills} } = map { $_ => 0 } @_;
}

sub add {
    my $self   = shift;
    my $temp = shift;
    my @units  = @{ $self->{units} };
    my %pieces = %{ $self->{bills} };
    my $unit;
    my $i = 0;
    while ($temp) {
        $unit = $units[$i];

        while ( $temp >= $unit ) {
            $temp -= $unit;
            $pieces{$unit} += 1;
        }
        last if $i == (@units);
        $unit = $units[ ++$i ];
    }

    %{ $self->{bills} } = %pieces;
}


sub get {
my $self = shift;
    return %{ $self->{bills}}; 

}

1;

__END__


=head1 DESCRIPTION

This module change sum (i.e. payment) to collection of bills and coins and keep it all in one hash returned by I<add> or I<get>.

=over 4

=item B<new>

creates the object.

=item B<set_bill>

gets @list of nominations bills and coins. In Europe it should looks like this: 

C<< @my_table = qw (500 200 100 50 20 10 5 2 1); >>

=item B<add>

value to change. It returns %hash of nominals with numbers of bills.

=item B<get>

returns %hash of nominals with numbers of bills.

=back

=head1 TO DO

Support for decimal values.

Check for indivisible values.

=head1 AUTHOR

£ukasz M±drzycki, <F<uksza@cpan.org>>. 

=head1 BUGS

Who knows...

=head1 ACKNOWLEDGEMENTS

All Perl family.

=head1 COPYRIGHT & LICENSE

Copyright(C) 2004, 2005 £ukasz M±drzycki, <F<uksza@cpan.org>>.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

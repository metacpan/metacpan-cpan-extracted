package Number::Closest;

our $VERSION = '0.06';

use Moose;

has 'number'   => (isa => 'Num',           is => 'rw', required => 1);
has 'numbers'  => (isa => 'ArrayRef[Num]', is => 'rw', required => 1);

sub analyze {
    my($self)=@_;

    my @dist = sort { $a->[1] <=> $b->[1] } map { [$_, abs($_ - $self->number)] } sort {$a <=> $b} @{$self->numbers};

    \@dist
}

sub find {
    my($self,$amount)=@_;

    $amount ||= 1;

    my $list = $self->analyze;
    
    my $n = $amount <= scalar @$list ? $amount : scalar @$list ;

    #warn "N: $n";

    my @closest = @{$list}[0..($n-1)] ;

    my @c = map { $_->[0] } @closest;
    
    #use Data::Dumper;
    #warn Dumper \@closest, \@c;

    if ($amount == 1) {
	$c[0] ;
    } else {
	\@c;
    }

}




=head1 NAME

Number::Closest - Find number(s) closest to a number in a list of numbers

=head1 SYNOPSIS

 use Number::Closest;

 my $finder = Number::Closest->new(number => $num, numbers => \@num) ;
 my $closest = $finder->find; # finds closest number
 my $closest_two = $finder->find(2) ;  # gives arrayref of two closest numbers in list
 
 # or, all in one shot
 Number::Closest->new(number => $num, numbers => \@num)->find(1) ;
 



=head1 SEE ALSO

L<http://stackoverflow.com/questions/445782/finding-closest-match-in-collection-of-numbers>

=head1 AUTHOR

Currently maintained by Mike Accardo, <accardo@cpan.org>

Original author Terrence Monroe Brannon.

=head1 COPYRIGHT

    Copyright (c) 2015 Mike Accardo
    Copyright (c) 1999-2014 Terrence Brannon 

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Number::Closest

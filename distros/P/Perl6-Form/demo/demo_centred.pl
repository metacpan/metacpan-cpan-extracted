use Perl6::Form;

@a  = map 'a'x$_, reverse 1..6;
@as = map 'a 'x$_, reverse 1..6;

print form '[{IIIIIIIII}]'x2, \@a, \@as;

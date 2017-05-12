use Perl6::Form;

my @name     = qw(Smith Woo Jones Nguyen Lee);
my @status   = qw(Retired Active Leave);
my @position = qw(Admin Sales Sales Admin );

print form {vfill=>"<unknown>"},
	<<EOFORM, \@name, \@position, [map "($_)", @status];
{IIIIIIIIIIIII} {IIIIIIIIIIII}
{IIIIIIIIIIIII}
------------------------------
EOFORM

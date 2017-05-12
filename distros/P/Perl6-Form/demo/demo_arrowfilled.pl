use Perl6::Form;

sub hashes {
	my ($match,$opts) = @_;
	$opts->{lfill}='>> ';
	$opts->{rfill}='<< ';
	return '{I{'.length($match).'}I}';
}

print form
	{field=>[qr/(#+)/=>\&hashes]},
	"[###|###############################]",
	[1,2,3], [qw[First Second Last]];


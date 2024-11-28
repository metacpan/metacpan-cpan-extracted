use Perlmazing;
our @ISA = qw(Perlmazing::Listable);

my $accent_equivalents = {
	'Á' => 'A', 'À' => 'A', 'Ä' => 'A', 'Â' => 'A', 'Ã' => 'A', 'Å' => 'A',
	'é' => 'e', 'è' => 'e', 'ê' => 'e', 'ë' => 'e', 'e' => 'e', 'e' => 'e',
	'ñ' => 'n',
	'Ó' => 'O', 'Ò' => 'O', 'Ö' => 'O', 'Ô' => 'O', 
	'á' => 'a', 'à' => 'a', 'â' => 'a', 'ä' => 'a', 'ã' => 'a', 'å' => 'a',
	'Ñ' => 'N',
	'Ý' => 'Y', 'Y' => 'Y', 'Ÿ' => 'Y', 
	'É' => 'E', 'È' => 'E', 'Ë' => 'E', 'Ê' => 'E',
	'ý' => 'y', 'ÿ' => 'y', 'y' => 'y', 
	'ú' => 'u', 'ù' => 'u', 'ü' => 'u', 'û' => 'u',
	'Í' => 'I', 'Ì' => 'I', 'Ï' => 'I', 'Î' => 'I',
	'Ú' => 'U', 'Ù' => 'U', 'Ü' => 'U', 'Û' => 'U',
	'í' => 'i', 'ì' => 'i', 'ï' => 'i', 'î' => 'i',
	'ó' => 'o', 'ò' => 'o', 'ö' => 'o', 'ô' => 'o', 'õ' => 'o', 
};

sub main {
	if (defined $_[0]) {
		my $seen;
		for my $i (split //, $_[0]) {
			next if $seen->{$i};
			$seen->{$i} = 1;
			if (exists $accent_equivalents->{$i}) {
				my $ch = sprintf '\x%x', ord $i;
				$_[0] =~ s/$ch/$accent_equivalents->{$i}/g;
			}
		}
	}
}

1;


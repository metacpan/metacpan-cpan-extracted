package P50Tools::Packs::PacksSize;  

use common::sense;

{
    no strict "vars";
    $VERSION = '0.1';
}

sub new {
	my $pac = int rand(65500) + 1;
	return $pac;
}

1;

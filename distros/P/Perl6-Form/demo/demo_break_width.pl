sub break_width {
	my ($str_ref, $width, $ws) = @_;
	$ws ||= '(?!)';
	for ($$str_ref) {
		my $single = qr/$ws|\n|\r|(?s:.)/;
	    return ("",   0) unless /\G((?:$single){1,$width})/gc;
		(my $result = $1) =~ s/$ws|\n|\r/ /g;
		return ($result, substr($_,pos)=~/\S/)
	}
}

use Perl6::Form;

$data = "You can play no part but Pyramus;\n"
	  . "for Pyramus is a sweet-faced man;  ";

print form {break=>\&break_width}, "|{[[[[[}|", $data;



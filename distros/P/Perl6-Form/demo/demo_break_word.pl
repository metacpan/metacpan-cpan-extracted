sub break_word {
	my ($str_ref, $length, $ws) = @_;
	for ($$str_ref) {
		return ("",0) unless /\G(\S{1,$length})\s*/gc;
		return ("$1", substr($_, pos) =~ /\S/);
	}
}

use Perl6::Form;

$data = "You can play no part but Pyramus;\n"
	  . "for Pyramus is a sweet-faced man;  ";

print form {break=>\&break_word}, "|{[[[[[}|", $data;



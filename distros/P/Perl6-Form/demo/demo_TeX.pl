use TeX::Hyphen;
use Carp;

my $hyp;

sub break_TeX
{
    $hyp ||= TeX::Hyphen->new() or croak "Can't open hyphenation file";

    return sub {
		my ($str_ref, $length, $ws) = @_;
		$ws ||= qr/(?!)/;
		(my $text = substr($$str_ref, pos $$str_ref)) =~ s/$ws|\n|\r/ /g;
		return ("",0) unless $text =~ /\S/;
		my $result = "";
		for my $chunk ($text =~ /(\S+\s*)/g) {
			$result .= $chunk and next if length($result.$chunk) <= $length;
			my ($word, $space) = $chunk =~ /(\S+)(\s*)/g;
			$result .= $word and last  if length($result.$word)  <= $length;
			for my $break (reverse $hyp->hyphenate($word)) {
				if (length($result)+$break < $length) {
					$result .= substr($word,0,$break);
					$result .= '-' and pos($$str_ref)-- if $result !~ /-$/;
					last;
				}
			}
			$result ||= do{ pos($$str_ref)--; substr($text,0,$length-1).'-' };
			last;
		}
		pos $$str_ref += length($result);
        return ($result, substr($$str_ref, pos $$str_ref) =~ /\S/);
    }
}


	use Perl6::Form;

	$data = "You can play no part but Pyramus;\n"
		  . "for Pyramus is a sweet-faced man;  ";

	print form {break=>break_TeX()}, "|{[[[[[}|", $data;

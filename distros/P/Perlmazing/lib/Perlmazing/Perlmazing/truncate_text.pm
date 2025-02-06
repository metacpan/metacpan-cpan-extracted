use Perlmazing qw(is_number void_context croak max);

sub main {
	my ($str, $size, $append_string_to_word, $append_string_to_paragraph) = @_;
	return '' unless defined $str and length $str;
	return unless is_number $size;
	my $length = length $str;
	if ($length <= $size or $length <= ($size + max(length($append_string_to_word) || 0, length($append_string_to_word) || 0))) {
    return $str;
  }
	my $next = substr $str, $size, 1;
	$str = substr $str, 0, $size;
  my $is_word_truncated;
  unless ($next eq ' ') {
    if ((my $rindex = rindex($str, ' ')) != -1) {
			$str = substr $str, 0, $rindex;
		} else {
      $is_word_truncated = 1;
    }
	}
	$str =~ s/\s+$//;
  if ($is_word_truncated and length $append_string_to_word) {
    $str .= $append_string_to_word;
  }
  if (length $append_string_to_paragraph) {
    $str .= $append_string_to_paragraph;
  }
	if (void_context) {
    eval {
      $_[0] = $str;
    };
    if (my $e = $@) {
      if ($e =~ /^(Modification of a read\-only value attempted)/) {
        croak $1;
      }
      croak $e;
    }
    return;
  }
  $str;
}

1;

use 5.010; use warnings;

use Perl6::Form;

my $text = "Now is the winter of our discontent made glorious summer by this son of York";

# Subroutine to modify format with ellipsis in too-long lines...
sub dotdotdot ($) {
    my $format = shift;

    # Breaking sub that inserts ellipses...
    state $ellipsis = sub  {
        # Unpack args and set up default...
        my ($text_ref, $width, $ws) = @_;
        $ws //= '\s+';

        # Do any requested whitespace squeezing...
        $$text_ref =~ s{$ws}{$+ // ' '}ex;

        # How long is the piece of string???
        my $text_len = length($$text_ref);

        # Return entire string if it will fit...
        if ($text_len <= $width) {
            pos $$text_ref = $text_len;
            return ($$text_ref, 0)
        }

        # Otherwise truncate with trailing ellipsis...
        else {
            pos $$text_ref = $width-3;
            return (substr($text, 0, $width-3) . '...', 1);
        }
    };

    # Set up temporary break with ellipses...
    return { break => $ellipsis }, $format;
}

print form
      dotdotdot '{<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<}',
      $text,
      dotdotdot '{VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',
      $text;

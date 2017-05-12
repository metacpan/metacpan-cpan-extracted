use 5.010;
use warnings;

use Perl6::Form;

sub break_with_ellipsis {
    my ($breaker) = @_;

    # This generates the replacement line-breaking subroutine...
    return sub {
        my ($str_ref, $width, $ws) = @_;

        # Remember where we started this broken line...
        my $start_pos = pos $$str_ref;

        # Break it with the original breaker....
        my ($nextline, $more) = $breaker->($str_ref, $width, $ws);

        # If not at end-of-string...
        if ($more) {
            # If there's no room for the ellipsis...
            if (length $nextline > $width-3) {

                # Reset line to be (re)broken...
                pos $$str_ref = $start_pos;

                # Rebreak it with room for ellipsis...
                ($nextline, $more) = $breaker->($str_ref, $width-3, $ws);
            }

            # Add the ellipsis...
            $nextline .= '...';
        }

        return ($nextline, $more);
    }
}

use Perl6::Form {
    # Specify a new kind of field...
    field => [
        # Match fields with trailing ellipses...
        qr/ [{] [^}]* \.\.\. [}] /x

        # And do this with them...
        => sub {
                my ($match, $opts) = @_;

                # Temporarily wrap breaking algorithm with ellipsis appender...
                $opts->{break} = break_with_ellipsis( $opts->{break} );

                # Rewrite format (removing ellipses from it)...
                my $fieldtype = substr($match,1,-4);
                return '{' . $fieldtype . substr($fieldtype,-1) x 3 . '}';
            }
    ]
};


# Test it...
my $text = 'Now is the winter of our discontent made glorious summer by this son of York';

print form
    '|---------------------------|',
    ' {<<<<<<<<<<<<<<<<<<<<<<...}',
    $text,
    ' {VVVVVVVVVVVVVVVVVVVVVVVVV}',
    '|---------------------------|';

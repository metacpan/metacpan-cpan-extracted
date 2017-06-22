package NKTI::general::char::split;

use strict;
use warnings;

# Define Version
# ----------------------------------------------------------------
our $VERSION = '0.14';

# Create Action Split Character in string :
# ------------------------------------------------------------------------
sub based_length {

    # Declare parameter module :
    # ----------------------------------------------------------------
    my ($self, $string, $length) = @_;

    # Action Convert string to array based length of char :
    # ----------------------------------------------------------------
    my $this_length = 'A'.$length;
#    my @data = unpack("($this_length)*", $string);
    my $len = "." x $length;
    my @data = ($string =~ m/$len/g);

    # Return Result :
    # ----------------------------------------------------------------
    return @data;
}
# End of Create Action Split Character in string.
# ===========================================================================================================

# Create Module Split Charcter by Character :
# ------------------------------------------------------------------------
sub based_char {

    # Declara parameter module :
    # ----------------------------------------------------------------
    my ($self, $string, $delimiter, $join) = @_;

    # Declare variable for action split :
    # ----------------------------------------------------------------
    my @split = split /$delimiter/, $string;

    # Check IF $join eq 1 :
    # ----------------------------------------------------------------
    if ($join eq 1) {

        # Declare scalar for Placing result :
        # ----------------------------------------------------------------
        my $str_data = '';

        # Prepare To While loop for Join result split :
        # ----------------------------------------------------------------
        my $i = 0;
        my $keys_split = keys (@split);
        my $until_loop = $keys_split;

        # While Loop for Join result split :
        # ----------------------------------------------------------------------------------------
        while ($i < $until_loop) {

            # Join Result split :
            # ----------------------------------------------------------------
            $str_data .= $split[$i];
            
            # Auto Increment :
            # ----------------------------------------------------------------
            $i++;
        }
        # End of While loop for Join result split.
        # ========================================================================================

        # Return Result :
        # ----------------------------------------------------------------
        return $str_data;
    }
    # End of check IF $join eq 1.
    # ----------------------------------------------------------------

    # Check IF $join eq 1 :
    # ----------------------------------------------------------------
    else {

        # Return Result :
        # ----------------------------------------------------------------
        return @split;
    }
    # End of check IF $join eq 1.
    # ----------------------------------------------------------------
}
# End of Create Module Split Charcter by Character.
# ===========================================================================================================
1;
__END__
#
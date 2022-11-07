package Simple::Filter::MacroLite;

# Set the VERSION.
$VERSION = '0.02';

# Load the Perl pragmas.
use strict;
use warnings;

# Outer filter starts here.
use Filter::Simple::Compile sub {
    # Remove package terminator 1; from the package content. 
    $_ =~ s/1;\s//g;
    # Remove the comments from the package content. 
    s/#\s+[0-9a-fA-F]+\s*[\n]+||#\s+.*//gm;
    # sprintf Block starts here.
    $_ = sprintf(
        # Create a single-quoted string for printing.
        q(
            # Inner filter starts here.
            use Filter::Simple::Compile sub {
                # Remove comment lines from the script content. 
                $_ =~ s/#\s+[0-9a-fA-F]+\s*[\n]+//gm;
                # Assemble modules and script.
                $_ = join("", "%s", $_);
            };
            1;
            # Inner filter ends here.
        ), $_
    );
    # sprintf Block ends here.
};
1;
# Outer filter ends here.

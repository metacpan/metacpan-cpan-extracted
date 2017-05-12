package Template::Recall::Base;

use strict;
no warnings;


our $VERSION='0.08';


sub render {

	my ( $class, $template, $hash_ref, $delims ) = @_;

	if ( not defined ($template) ) {
        die "Template::Recall::Base::render() 'template' parameter not present";
    }

    my $user_delims = ref $delims && $#{$delims} == 1 ?  1 : 0;

	if (ref $hash_ref) {

        while ( my ($key, $value) = each %$hash_ref) {
            if ( $user_delims ) {
                my $d = $delims->[0] . '\s*' . $key . '\s*' . $delims->[1];
				$template =~ s/$d/$value/g;
            }
            else { # exactly specified delims
				$template =~ s/$key/$value/g;
            }
        } # while

	} # if


	# Do trimming, if so flagged
	return trim($class->{'trim'}, $template) if defined $class->{'trim'};

	return $template;

} # render()




# Trim output if specified

sub trim {
	my ($trim, $template) = @_;

	return $template if !defined($trim);

	if ($trim eq 'left' or $trim eq 'l') {
		$template =~ s/^\s+//g;
		return $template;
	}

	if ($trim eq 'right' or $trim eq 'r') {
		$template =~ s/\s+$//g;
		return $template;
	}

	if ($trim eq 'both' or $trim eq 'b') {
		$template =~ s/^\s+|\s+$//g;
		return $template;
	}

} # trim()

1;

# Undumps (and dereferences, if possible and $keep_ref is undefined or zero)
# using the Safe module

package Data::Undumper;

use Carp qw(cluck);
use Safe;

sub Undump {
    my($unsafe_code) = shift;
    my($keep_ref) = shift;
    my($name);
    my($compartment) = new Safe;
    my($result);
    
    $unsafe_code .= ' ;';
    $unsafe_code =~ s/\;\s*\;$/\;/;
    ($name) = $unsafe_code =~ /^\s*([^\s\=]+)\s*\=/;
    $unsafe_code .= "$name;";
    $result = $compartment->reval($unsafe_code);
    
    if (!defined($result) && $@ !~ /^\s*$/) {
	cluck $@;
	return undef;
    } else {
	if ($keep_ref) {
	    return $result;
	}
	if ($result =~ /^HASH/) {
	    return %$result;
	} elsif ($result =~ /^ARRAY/) {
	    return @$result;
	} elsif ($result =~ /^SCALAR/) {
	    return $$result;
	} else {
	    return $result;
	}
    }
}

1;

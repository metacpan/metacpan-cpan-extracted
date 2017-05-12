package SafeCall;

use Safe;
use Carp qw( carp cluck);

sub Render_Safe {
    my($argument) = shift;
    my($result);
    my($compartment) = new Safe;
    my($quote) = ($argument =~ /^\s*[\'\"]/) ? 1 : 0;

    if ($argument =~ /^[\s\w\,\'\"]+$/) {
	return $argument;
    }
    if ($argument =~ /\`/) {
	return undef;
    }
    $result = $compartment->reval($argument .';');
    if (!defined($result) || $@ !~ /^\s*$/) {
	cluck $@;
	return undef;
    }
    if ($quote) {
	return "'".$result."'";
    } else {
	return $result;
    }
}

sub Execute {
    my($use_lib) = shift;
    my($module) = shift;
    my($subroutine) = shift;
    my($status_ref) = shift;
    my(@arguments) = @_;
    my($eval_code);
    my(@forbidden) = (
		      'POSIX'
		      );
    my($safe_module);
    my($safe_subroutine);
    
    # Process 'use lib library;'
    if (defined($use_lib) && $use_lib !~ /^\s*$/) {
	$eval_code = "use lib '$use_lib';\n";
    }
    $safe_module = Render_Safe($module);
    $safe_subroutine = Render_Safe($subroutine);
    if (!defined($safe_module) || $safe_module =~ /^\s*$/) {
	carp "Module name was not passed or was illegal";
	if (defined($status_ref) && $status_ref =~ /^SCALAR/) {
	    $$status_ref = -1;
	}
	return;
    }
    # Process 'use module;'
    map {
	if ( $safe_module eq $_) {
	    carp "Module: $_ is forbidden";
	    if (defined($status_ref) && $status_ref =~ /^SCALAR/) {
		$$status_ref = -2;
	    }
	    return;
	}
    } @forbidden;
    $eval_code .= "use $safe_module;\n";
    # Setup subroutine
    if (!defined($safe_subroutine) || $safe_subroutine =~ /^\s*$/) {
	carp "Subroutine name was not passed or was illegal";
	if (defined($status_ref) && $status_ref =~ /^SCALAR/) {
	    $$status_ref = -3;
	}
	return;
    }
    $eval_code .= "$safe_module\:\:$safe_subroutine( \@arguments );\n";
    if (defined($status_ref) && $status_ref =~ /^SCALAR/) {
	$$status_ref = 0;
    }
    return eval $eval_code;
}

1;

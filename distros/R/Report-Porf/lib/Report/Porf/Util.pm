# perl
#
# Class Report::Porf::Util
#
# Utilities for the Perl Open Report Framework (Porf)
#
# Ralf Peine, Tue May 27 11:30:37 2014
#
# More documentation at the end of file
#------------------------------------------------------------------------------

$VERSION = "2.001";

use strict;
use warnings;

#--------------------------------------------------------------------------------
#
#  Report::Porf::Util;
#
#--------------------------------------------------------------------------------

package Report::Porf::Util;

use Carp;

use base qw (Exporter);

our @EXPORT = qw (
print_hash_ref verbose 
get_option_value interprete_value_options complete_value_code
interprete_alignment const_length_left const_length_center const_length_right
);

# --- Print out hash content, flat ----------------------------------------------
sub print_hash_ref {
    my (
        $hash_ref,        # hash to print
        ) = @_;

    print "#------------------------------\n";
    foreach my $key (sort(keys(%$hash_ref))) {
        print "$key = ".$hash_ref->{$key}."\n";
    }
}

# --- true if $value greater than internal stored value ------------------------
sub verbose {
    my ($instance,    # instance_ref
        $verbose      # to compare, 
        ) = @_;

    my $verbose_set = $instance->get_verbose();
    
    return ($verbose_set >= $verbose ? $verbose_set: 0)
        if defined $verbose && defined $verbose_set;
    return $verbose_set;
}

# --- get option value by different keys ---------------------------------------
sub get_option_value {
    my $option_ref = shift;  # ref to option hash

    my $key;                 # check all other args as key in option_ref
    
    while ($key = shift) {
        return $option_ref->{$key} if defined $option_ref->{$key};
    }

    return undef;
}

# --- get active option 'value*' and check, that only one is used --------------
sub interprete_value_options {
    my $option_ref = shift;

    my $value_other   = get_option_value($option_ref, qw (-value         -val     -v));
    my $value_indexed = get_option_value($option_ref, qw (-value_indexed -val_idx -vi));
    my $value_named   = get_option_value($option_ref, qw (-value_named   -val_nam -vn));
    my $value_object  = get_option_value($option_ref, qw (-value_object  -val_obj -vo));
    
    my @used_opts;

    push (@used_opts, "\$value_other => $value_other")         if defined $value_other;
    push (@used_opts, "\$value_indexed => $value_indexed")     if defined $value_indexed;
    push (@used_opts, "\$value_named => $value_named")         if defined $value_named;
    push (@used_opts, "\$value_object => $value_object")       if defined $value_object;

    die "More than one value option used: ".join (", ", @used_opts)
		if (scalar @used_opts > 1);
    
    # recalc value
    my $value_result = $value_other;

    if (defined $value_indexed) {
		die "Not an index for value array position: '$value_indexed'"
			if $value_indexed =~ /\D/;
		$value_result = '$_[0]->['.$value_indexed.']';
    }

    if (defined $value_named) {
		$value_result = '$_[0]->{\''.$value_named.'\'}';
    }

    if (defined $value_object) {
		my $get_value_call = $value_object;
		$get_value_call =~ s/\s*\(\s*\)\s*$//og;
		$get_value_call =~ s/^\s+//og;
		die "Not a method call for an object: '$value_object'"
			if $get_value_call =~ /\W/;
		$value_result = '$_[0]->'.$get_value_call.'()';
    }
	
    return $value_result;
}

# --- complete value code --- add check for default value to code sequence, if $default_value defined -------
sub complete_value_code {
	my $value_code_str = shift;
	my $default_value  = shift;

	return "return $value_code_str" unless defined $default_value;

	$default_value =~ s/'/\\'/og;
	
	return "my \$value = $value_code_str;\n".
		"\$value = '$default_value' if !defined \$value || \$value eq '';\n".
			"return \$value;";
}

# --- get value for alignment --------------------------------------------------
sub interprete_alignment {
    my ($align_selection   # value for alignment
        ) = @_;

    return '' unless $align_selection;
    
    if ( $align_selection =~ /^\s*$/) {
        return '';
    }
    
    if ($align_selection =~ /^\s*-?(l|left)\s*$/i ) {
        return 'Left';
    }

    if ($align_selection =~ /^\s*-?(c|center)\s*$/i ) {
        return 'Center';
    }

    if ($align_selection =~ /^\s*-?(r|right)\s*$/i ) {
        return 'Right';
    }

    die "cannot interprete alignment '$align_selection'";
}

# --- align const length left ------------
sub const_length_left {
    my ($wanted_length,
		$value
	) = @_;

    my $l = length ($value);

    if ( $l < $wanted_length) {
        $value .= ' ' x ($wanted_length - $l);
    }
    elsif ( $l > $wanted_length ) {
        $value = substr ($value, 0, $wanted_length);
    }

    return $value;
}

# --- align const length center ------------
sub const_length_center {
    my ($wanted_length,
		$value
	) = @_;

    my $l = length ($value);

    if ( $l < $wanted_length) {
        my $missing = $wanted_length - $l;
        my $right = int($missing / 2);
        my $left  = $missing - $right;
        $value = ' ' x ($left) . $value . ' ' x ($right);
    }
    elsif ( $l > $wanted_length ) {
        $value = substr ($value, 0, $wanted_length);
    }

    return $value;
}

# --- align const length right ------------
sub const_length_right {
    my ($wanted_length,
		$value
	) = @_;

    my $l = length ($value);

    if ( $l < $wanted_length) {
        $value = ' ' x ($wanted_length - $l) . $value;
    }
    elsif ( $l > $wanted_length ) {
        $value = substr ($value, 0, $wanted_length);
    }

    return $value;
}

# --- escape html special chars ----------------------
sub escape_html_special_chars {
	my ($value) = @_;

	$value =~ s/&/\&amp;/og;
	$value =~ s/</\&lt;/og;
	$value =~ s/>/\&gt;/og;

	return $value;
}


1;

=head1 NAME

C<Report::Porf::Util>

Utilities for Perl Open Report Framework (Porf).

=head1 Documentation

See Framework.pm for documentation of features and usage.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 by Ralf Peine, Germany.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

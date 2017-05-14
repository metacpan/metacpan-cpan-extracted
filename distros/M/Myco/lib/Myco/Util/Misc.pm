package Myco::Util::Misc;

###############################################################################
# $Id: Misc.pm,v 1.1 2006/03/17 20:59:08 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Util::Misc -  a humble perl package

=head1 SYNOPSIS

  use Myco::Util::Misc;

=head1 DESCRIPTION

A simple shell to store oft-used routines for miscellaneous tasks.

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;

##############################################################################
# Programatic Dependencies

##############################################################################
# Constants
##############################################################################

##############################################################################
# Methods
##############################################################################

=head1 ADDED CLASS METHODS

=head2 hash_with_no_values_to_array

  my $attribute_label = Myco::Util::Misc->pretty_print('person_last_name');
  my $do_these_words_match = $attribute_label eq 'Person Last Name';

Convert the keys of a hash ref with all values blank to an array ref. Mainly
used to provide a hack to L<Config::General|Config::General>, which lacks a
function to specify a multi-valued config value without many repetitious lines.

=cut

sub hash_with_no_values_to_array {
    my $self = shift;
    my $hash = shift;
    
    if (ref $hash eq 'HASH') {
        my @values = values %$hash;
        return [ keys %$hash ] unless grep /\w+/, @values;
    } else {
        return $hash;
    }
    
}

1;
__END__


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

L<Myco|Myco>,

=cut

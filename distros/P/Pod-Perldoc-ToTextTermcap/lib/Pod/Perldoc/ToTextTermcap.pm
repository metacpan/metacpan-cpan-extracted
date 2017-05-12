# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2009 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

require 5;
package Pod::Perldoc::ToTextTermcap;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = "0.01";

use base qw(Pod::Perldoc::ToText);

use Pod::Text::Termcap ();

sub parse_from_file {
  my $self = shift;
  
  my @options =
    map {; $_, $self->{$_} }
      grep !m/^_/s,
        keys %$self
  ;
  
  defined(&Pod::Perldoc::DEBUG)
   and Pod::Perldoc::DEBUG()
   and print "About to call new Pod::Text::Termcap ",
    $Pod::Text::Termcap::VERSION ? "(v$Pod::Text::Termcap::VERSION) " : '',
    "with options: ",
    @options ? "[@options]" : "(nil)", "\n";
  ;

  Pod::Text::Termcap->new(@options)->parse_from_file(@_);
}

1;

__END__

=head1 NAME

Pod::Perldoc::ToTextTermcap - let Perldoc render Pod as plaintext with format escapes

=head1 SYNOPSIS

  perldoc -MPod::Perldoc::ToTextTermcap Some::Modulename

or

  PERLDOC=-MPod::Perldoc::ToTextTermcap
  export PERLDOC
  # or: setenv PERLDOC -MPod::Perldoc::ToTextTermcap
  perldoc Some::Module

=head1 DESCRIPTION

This is a "plug-in" class that allows Perldoc to use
L<Pod::Text::Termcap> as a formatter class.

It supports all options supported by L<Pod::Perldoc::ToText>.

=head1 SEE ALSO

L<Pod::Text::Termcap>, L<Pod::Perldoc>, L<Pod::Perldoc::ToText>

=head1 COPYRIGHT

Copyright (c) 2009 Slaven ReziE<x0107>. All rights reserved.

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Slaven ReziE<x0107> <srezic@cpan.org>.

Based on L<Pod::Perldoc::ToText> which is by Sean M. Burke
<sburke@cpan.org> and Adriano R. Ferreira <ferreira@cpan.org>.

=cut

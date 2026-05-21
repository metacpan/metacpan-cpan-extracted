#
#  This file is part of Task::WebDyne::Apache.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#

#
#
package Task::WebDyne::Apache;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION $VERSION_GIT_SHA $AUTHORITY);
use warnings;


#  Version information
#
$AUTHORITY='cpan:ASPEER';
$VERSION='0.003';
$VERSION_GIT_SHA=do { local (@ARGV, $/) = ($_=__FILE__.'.sha'); <> if -f $_ };
chomp($VERSION_GIT_SHA) if defined $VERSION_GIT_SHA;


#  All done, init finished
#
1;

__END__


=head1 NAME

Task::WebDyne::Apache - Prerequisite modules for running WebDyne under Apache


=head1 SYNOPSIS


 cpan Task::WebDyne::Apache
 
 cpanm Task::WebDyne::Apache

=head1 DESCRIPTION

Task::WebDyne::Apache installs the Perl modules typically required to run
WebDyne under Apache.


=head1 AUTHOR

Andrew Speer andrew.speer@isolutions.com.au


=head1 LICENSE and COPYRIGHT

This file is part of Task::WebDyne::Apache.

This software is copyright (c) 2026 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>


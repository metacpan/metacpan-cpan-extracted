#
#  This file is part of Task::WebDyne::Plack.
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
package Task::WebDyne::Plack;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION $VERSION_GIT_SHA $AUTHORITY);
use warnings;


#  Version information
#
$AUTHORITY='cpan:ASPEER';
$VERSION='0.004';
$VERSION_GIT_SHA=do { local (@ARGV, $/) = ($_=__FILE__.'.sha'); <> if -f $_ };
chomp($VERSION_GIT_SHA) if defined $VERSION_GIT_SHA;


#  All done, init finished
#
1;

__END__

=head1 NAME

Task::WebDyne::Plack - Optional Plack integration for WebDyne


=head1 SYNOPSIS

    cpan Task::WebDyne::Plack

    cpanm Task::WebDyne::Plack


=head1 DESCRIPTION

This is a Task-style distribution that exists to pull in the optional
L<WebDyne> + L<Plack> dependency set used for WebDyne Plack deployments.

It does not provide runtime functionality beyond declaring prerequisites.


=head1 AUTHOR

Andrew Speer andrew.speer@isolutions.com.au


=head1 LICENSE and COPYRIGHT

This file is part of Task::WebDyne::Plack.

This software is copyright (c) 2026 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>


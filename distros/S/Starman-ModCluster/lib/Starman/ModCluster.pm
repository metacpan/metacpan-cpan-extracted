package Starman::ModCluster;

use strict;
use warnings;
use 5.008_001;
our $VERSION = '0.09';


1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Starman::ModCluster - mod_cluster extension to Starman web server

=head1 SYNOPSIS

  # Run app.psgi with the default settings
  > starman-modcluster --mc-uri=http://127.0.0.1:6666 --mc-context="/app" --mc-alias="localhost" --mc-host=127.0.0.1

Read more options and configurations by running `perldoc starman-modcluster` (lower-case s).

=head1 DESCRIPTION

Starman::ModCluster is an extension to a Starman web server that allows an application to register with
mod_cluster (httpd module), and that permits one to have dynamic load balancing.

=over 4

=item UNIX only

This server does not support Win32.

=back

=head1 OPTIONS	

For launcher and all of the options please refer to L<starman-modcluster>

=head1 SUPPORT

Please report all bugs via github at
https://github.com/winfinit/Starman-ModCluster/issues

=head1 AUTHOR

Roman Jurkov E<lt>winfinit@cpan.orgE<gt>

=head1 COPYRIGHT

Roman Jurkov, 2014-

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Starman>

=cut

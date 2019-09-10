package Task::Latemp;

use warnings;
use strict;

use 5.008;

use CGI;
use Class::Accessor;
use Data::Dumper;
use File::Basename;
use File::Find::Rule;
use File::Path;
use Getopt::Long;
use HTML::Latemp::GenMakeHelpers;
use HTML::Latemp::NavLinks::GenHtml::Text;
use HTML::Latemp::News;
use HTML::Widgets::NavMenu;
use Pod::Usage;
use Template;
use YAML;

=head1 NAME

Task::Latemp - Specifications for modules needed by the Latemp static site generator.

=cut

our $VERSION = '0.0103';

=head1 DESCRIPTION

Latemp ( L<https://web-cpan.shlomifish.org/latemp/> ) is a static site
generator based on Website Meta Language. This task installs all of its
required dependencies.

=head1 AUTHOR

Shlomi Fish, L<https://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-task-latemp at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-Latemp>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Task::Latemp

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Task-Latemp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Task-Latemp>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Latemp>

=item * MetaCPAN

L<https://metacpan.org/release/Task-Latemp>

=back

=head1 ACKNOWLEDGEMENTS

=head1 SEE ALSO

L<Task> .

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT / Expat .

=cut

1; # End of Task::Latemp

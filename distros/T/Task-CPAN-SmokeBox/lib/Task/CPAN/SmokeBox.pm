package Task::CPAN::SmokeBox;

use strict;
use warnings;
use vars qw[$VERSION];

$VERSION = '0.02';

qq[smoky smoke box foo]

__END__

=head1 NAME

Task::CPAN::SmokeBox - Install the things to make a CPAN Testers smokebox

=head1 SYNOPSIS

  perl -MCPANPLUS -e 'install Task::CPAN::SmokeBox'

=head1 DESCRIPTION

Task::CPAN::SmokeBox is a L<Task> that installs all the modules and utilities useful to 
set up a CPAN Testers smokebox.

The following things will be installed:

  App::SmokeBox::Mini               # provides minismokebox
  App::SmokeBox::Mini::Plugin::IRC

  App::SmokeBrew                    # provides smokebrew

  App::Metabase::Relayd             # provides metabase-relayd

These should be installed into the system perl on a potential smokebox and not the perls
that will be used for CPAN testing.

=head1 AUTHOR

Chris C<BinGOs> Williams <chris@bingosnet.co.uk>

=head1 LICENSE

Copyright E<copy> Chris Williams

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=cut

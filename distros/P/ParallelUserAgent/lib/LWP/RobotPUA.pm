# -*- perl -*-
# $Id: RobotPUA.pm,v 1.6 2004/02/10 15:19:19 langhein Exp $

package LWP::RobotPUA;
use Exporter();
use LWP::Parallel::RobotUA qw(:CALLBACK);

require 5.004;
@ISA = qw(LWP::Parallel::RobotUA Exporter);
@EXPORT = qw(); 
@EXPORT_OK = @LWP::Parallel::RobotUA::EXPORT_OK;
%EXPORT_TAGS = %LWP::Parallel::RobotUA::EXPORT_TAGS;

1;

__END__

=head1 NAME

LWP::RobotPUA - Parallel LWP::RobotUA

=head1 SYNOPSIS

  require LWP::RobotPUA;
  $ua = new LWP::RobotPUA 'my-robot/0.1', 'me@foo.com';

  (see description of LWP::Parallel::RobotUA)

=head1 DESCRIPTION

RobotPUA is a simple frontend to the LWP::Parallel::RobotUA
module. It is here in order to maintain the compatibility with
previous releases. However, in order to prevent the previous need for
changing the original LWP sources, all extension files have been moved
to the LWP::Parallel subtree.

If you start from scratch, maybe you should start using LWP::Parallel
and its submodules directly.

See the L<LWP::Parallel::RobotUA> for the documentation on this
module.

=head1 AUTHOR

Marc Langheinrich, marclang@cpan.org

=head1 SEE ALSO

L<LWP::Parallel::RobotUA>, L<LWP::Parallel::UserAgent>, L<LWP::RobotUA>

=head1 COPYRIGHT

Copyright 1997-2004 Marc Langheinrich E<lt>marclang@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


#! /usr/bin/perl
#
#
# $Id: Dump.pm 75 2009-08-12 22:08:28Z lem $

package Net::Radius::Server::Dump;

use 5.008;
use strict;
use warnings;
use IO::File;
use File::Spec;
use Time::HiRes qw/gettimeofday/;

our $VERSION = do { sprintf "%0.3f", 1+(q$Revision: 75 $ =~ /\d+/g)[0]/1000 };

use Net::Radius::Server::Base qw/:set/;
use base qw/Net::Radius::Server::Set/;
__PACKAGE__->mk_accessors(qw/basepath basename result/);

sub set_basepath
{
    my $self = shift;
    my $r_data = shift;

    $self->basename('packet-') unless $self->basename;
    my $time = join('-', gettimeofday);
    my $file = File::Spec->catfile($self->basepath, $self->basename . $time);

    if (-f $file)
    {
	$self->log(2, "$file already exists. Won't overwrite");
	return;
    }

    my $fh = new IO::File($file, "w");
    
    unless ($fh)
    {
	$self->log(2, "Can't create $file: $!");
	return;
    }
    
    print $fh "*** RADIUS Request:\n";
    print $fh $r_data->{request}->str_dump, "\n\n";
    print $fh "*** RADIUS Response:\n";
    print $fh $r_data->{response}->str_dump, "\n\n";
    close $fh;
    $self->log(4, "Packet dump stored at $file");
}

42;

__END__

=head1 NAME

Net::Radius::Server::Dump - Produce a dump of the RADIUS packets

=head1 SYNOPSIS
    
  use Net::Radius::Base qw/:set/;
  use Net::Radius::Server::Dump;

  my $set = Net::Radius::Server::Dump->new
    ({
       basepath => '/var/log/radius-packets/',
       basename => 'packet-dump-',
       result => NRS_SET_DISCARD,
     });
  my $set_sub = $set->mk;

=head1 DESCRIPTION

C<Net::Radius::Server::Dump> implements a simple debugging aid that
dumps RADIUS packets into the B<basepath> directory, using a file
whose name is formed by the contatenation of the B<basename> property
and the current number of seconds and microseconds since the epoch.

B<basename> defaults to 'packet-'. This method returns whatever is
specified by the B<result> property.

B<basepath> is mandatory. This module will only be activated if this
property is specified.

Please see Net::Radius::Server::Set(3) for more information.

=head2 EXPORT

None by default.


=head1 HISTORY

  $Log$
  Revision 1.3  2006/12/14 15:52:25  lem
  Fix CVS tags


=head1 SEE ALSO

Perl(1), Net::Radius::Server(3), Net::Radius::Server::Set(3).

=head1 AUTHOR

Luis E. Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Luis E. Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.8.6 itself.

=cut



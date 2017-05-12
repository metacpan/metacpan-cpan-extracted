package SMS::Handler::Blackhole;

require 5.005_62;

use Carp;
use strict;
use warnings;
use SMS::Handler;
use vars qw(@ISA);
use Net::SMPP::XML;
use Params::Validate qw(:all);

# $Id: Blackhole.pm,v 1.3 2002/12/22 19:03:02 lem Exp $

(our $VERSION = q$Revision: 1.3 $) =~ s/Revision //;

our $Debug = 0;

=pod

=head1 NAME

SMS::Handler::Blackhole - Collect any unhandled message

=head1 SYNOPSIS

  use SMS::Handler::Blackhole;

  my $h = SMS::Handler::Blackhole->new();

 $h->handle({ ... });

=head1 DESCRIPTION

This module implements a simple responder class which simply collects
any message received. Normally, it should be included as the last
object in a handler list.

The following methods are provided:

=over 4

=item C<-E<gt>new()>

Creates a new C<SMS::Handler::Blackhole> object. 

=cut

sub new 
{
    my $name	= shift;
    my $class	= ref($name) || $name;

    return bless {}, $class;
}

=pod

=item C<-E<gt>handle()>

Collects the given SMS.

=cut

sub handle { SMS_STOP | SMS_DEQUEUE; }

1;
__END__

=pod

=head2 EXPORT

None by default.

=head1 LICENSE AND WARRANTY

This code comes with no warranty of any kind. The author cannot be
held liable for anything arising of the use of this code under no
circumstances.

This code is released under the terms and conditions of the
GPL. Please see the file LICENSE that accompains this distribution for
more specific information.

This code is (c) 2002 Luis E. Muñoz.

=head1 HISTORY

$Log: Blackhole.pm,v $
Revision 1.3  2002/12/22 19:03:02  lem
Set license GPL

Revision 1.2  2002/12/20 01:25:57  lem
Changed emails for redistribution

Revision 1.1  2002/12/09 22:04:28  lem
Added ::Blackhole


=head1 AUTHOR

Luis E. Muñoz <luismunoz@cpan.org>

=head1 SEE ALSO

L<SMS::Handler>, L<Queue::Dir>, perl(1).

=cut



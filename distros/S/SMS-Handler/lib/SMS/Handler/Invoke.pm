package SMS::Handler::Invoke;

require 5.005_62;

use Carp;
use strict;
use warnings;
use SMS::Handler;
use vars qw(@ISA);

# $Id: Invoke.pm,v 1.2 2002/12/22 19:03:02 lem Exp $

(our $VERSION = q$Revision: 1.2 $) =~ s/Revision //;

our $Debug = 0;

=pod

=head1 NAME

SMS::Handler::Invoke - Invoke a user-supplied method on a SMA

=head1 SYNOPSIS

  use SMS::Handler::Invoke;

  my $h = new SMS::Handler::Invoke sub { ... };

 $h->handle({ ... });

=head1 DESCRIPTION

Invokes the method passed as the only argument to the C<-E<gt>new()>
method, passing the SMS sent to its C<-E<gt>handle()> method. This is
useful to implement quick transforms in the source or destination
numbers, or implementing custom message handling.

The supplied sub will receive as its only argument, the SMS reference
passed to the C<-E<gt>handle()> method. Its return value will be
returned by the C<-E<gt>handle()> method.

=over 4

=item C<-E<gt>new()>

Creates a new C<SMS::Handler::Invoke> object. 

=cut

sub new 
{
    my $name	= shift;
    my $class	= ref($name) || $name;
    my $method	= shift;

    if (defined $method and ref($method) eq 'CODE')
    {
	return bless { sub => $method }, $class;
    }

    return undef;
}

=pod

=item C<-E<gt>handle()>

Invokes the user supplied sub on the SMS reference. Returns whatever
the user-supplied sub returns.

=cut

sub handle { return $_[0]->{sub}->($_[1]); }

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

$Log: Invoke.pm,v $
Revision 1.2  2002/12/22 19:03:02  lem
Set license GPL

Revision 1.1  2002/12/22 18:43:03  lem
Added ::Invoke and its tests


=head1 AUTHOR

Luis E. Muñoz <luismunoz@cpan.org>

=head1 SEE ALSO

L<SMS::Handler>, L<Queue::Dir>, perl(1).

=cut



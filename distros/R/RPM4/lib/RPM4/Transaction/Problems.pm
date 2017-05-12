##- Nanar <nanardon@zarb.org>
##-
##- This program is free software; you can redistribute it and/or modify
##- it under the terms of the GNU General Public License as published by
##- the Free Software Foundation; either version 2, or (at your option)
##- any later version.
##-
##- This program is distributed in the hope that it will be useful,
##- but WITHOUT ANY WARRANTY; without even the implied warranty of
##- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##- GNU General Public License for more details.
##-
##- You should have received a copy of the GNU General Public License
##- along with this program; if not, write to the Free Software
##- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# $Id$

use strict;
use warnings;

use RPM4;
use RPM4::Transaction;

package RPM4::Transaction::Problems;

sub new {
    my ($class, $ts) = @_;
    my $pbs = {
        _problems => $ts->_transpbs() || undef,
        _counter => -1,
    };

    $pbs->{_problems} or return undef;
    bless($pbs, $class);
}

sub count {
    my ($self) = @_;
    return $self->{_problems}->count();
}

sub init {
    my ($self) = @_;
    $self->{_counter} = -1;
}

sub hasnext {
    my ($self) = @_;
    return ++$self->{_counter} < $self->{_problems}->count();
}

sub problem {
    my ($self) = @_;
    return $self->{_problems}->fmtpb($self->{_counter});
}

sub is_ignore {
    my ($self) = @_;
    return $self->{_problems}->isignore($self->{_counter});
}

sub print_all {
    my ($self, $handle) = @_;
    $handle ||= *STDOUT;
    $self->{_problems}->print($handle);
}

1;

__END__

=head1 NAME

RPM4::Transaction::Problems

RPM4::Transaction

=head1 DESCRIPTION

This module an object for a collection of problems return by the rpmlib
when trying to install or removing rpms from the system. 

=head1 METHODS

=head2 new(ts)

Create a new problems collection from transaction. Return undef if now
problems has been found in the transaction.

=head2 $pbs->count

Return the count of problems in the object

=head2 $pbs->init

Reset internal index and set it to -1, see L<$deps-\\>hasnext()>

=head2 $pbs->hasnext

Advance to next dependency in the set.
Return FALSE if no further problem availlable, TRUE otherwise.

=head2 $pbs->problem

Return a format string about current problem in the set

=head2 $pbs->is_ignore

Return True if the problem should be ignored

=head2 $pbs->print_all($handle)

Print all error problems into the given handle, STDOUT if not specified.

=head1 SEE ALSO

L<RPM4>
L<RPM4::Db>

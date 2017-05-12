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

package RPM4::Header::Changelogs;

use strict;
use warnings;

sub new {
    my ($class, $header) = @_;

    my $changelogs = {
        changelogtext => [ $header->tag("changelogtext") ],
        changelogname => [ $header->tag("changelogname") ],
        changelogtime => [ $header->tag("changelogtime") ],
        _counter => -1,
    };
    bless($changelogs, $class);
}

sub init {
    my ($self) = @_;
    $self->{_counter} = -1;
}

sub hasnext {
    my ($self) = @_;
    $self->{_counter}++;
    return $self->{_counter} <= $#{$self->{changelogname}};
}

sub text {
    my ($self) = @_;
    return ${$self->{changelogtext}}[$self->{_counter}];
}

sub name {
    my ($self) = @_;
    return ${$self->{changelogname}}[$self->{_counter}];
}

sub time {
    my ($self) = @_;
    return ${$self->{changelogtime}}[$self->{_counter}];
}

1;

__END__

=head1 NAME

Hdlist::Header::Changelogs - A set of changelogs

=head1 SYNOPSIS

    use RPM4::Header;

    my $header RPM4::Header->new("foo.rpm");
    my $changelog = RPM4::Header::Changelog->new($header);
    $changelog->init; # not need here
    while ($changelog->hasnext) {
        print "* ", $changelog->name, "\n";
        print $changelog->text, "\n";
    }

=head1 METHODS

=head2 new(header)

Create a new changlelog set object from a rpm header.

=head2 init

Reset internal counter and prepare object for a first L<hasnext> call.

=head2 hasnext

Increase internal counter, return false if last entry has been reached.

=head2 name

Return the CHANGELOGNAME tag of current changelog entry.

=head2 time

Return the CHANGELOGTIME tag of current changelog entry.

=head2 text

Return the CHANGELOGTEXT tag of current changelog entry.

=head1 SEE ALSO

L<RPM4::Header>

L<Hdlist>


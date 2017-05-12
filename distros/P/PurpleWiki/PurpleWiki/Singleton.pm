# PurpleWiki::Singleton.pm
# vi:ai:sm:et:sw=4:ts=4
#
# $Id$
#
# Copyright (c) Matthew O'Connor 2004.  All rights reserved.
#
# This file is part of PurpleWiki.  PurpleWiki is derived from:
#
#   UseModWiki v0.92          (c) Clifford A. Adams 2000-2001
#   AtisWiki v0.3             (c) Markus Denker 1998
#   CVWiki CVS-patches        (c) Peter Merel 1997
#   The Original WikiWikiWeb  (c) Ward Cunningham
#
# PurpleWiki is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the
#    Free Software Foundation, Inc.
#    59 Temple Place, Suite 330
#    Boston, MA 02111-1307 USA
#
package PurpleWiki::Singleton;
use strict;
use warnings;
use Carp;

######## Package Globals ########

use vars qw($VERSION);
$VERSION = "0.9.1";


######## Public Class Methods ########

sub new {
    croak "PurpleWiki::Singleton can not be instantiated.";
}

sub instance {
    my $class = shift;
    croak "instance() is a class method." if ref $class or not $class;

    if ($ENV{MOD_PERL}) {
        require mod_perl;
        ($mod_perl::VERSION >= 1.99) ? require Apache::compat : require Apache;
        return Apache->request->pnotes("purplewiki_singleton_$class");
    } else {
        no strict 'refs';
        my $classGlobal = "$class\::_singletonObjectInstance";
        return $$classGlobal;
    }
}

sub setInstance {
    my ($class, $instance) = @_;
    croak "setInstance() is a class method." if ref $class or not $class;

    if ($ENV{MOD_PERL}) {
        require mod_perl;
        ($mod_perl::VERSION >= 1.99) ? require Apache::compat : require Apache;
        Apache->request->pnotes("purplewiki_singleton_$class" => $instance);
    } else {
        no strict 'refs';
        my $classGlobal = "$class\::_singletonObjectInstance";
        $$classGlobal = $instance;
    }
}
1;
__END__

=head1 NAME

PurpleWiki::Singleton - Enables the Singleton Pattern.

=head1 SYNOPSIS

    #!/usr/bin/perl
    use strict;
    use warnings;

    package PurpleWiki::SomeClass;
    use strict;
    use warnings;
    use base qw(PurpleWiki::Singleton);

    sub new {
        my $prototype = shift;
        my $class = ref($prototype) || $prototype;
        my $self = bless({ @_ }, $class);

        $class->setInstance($self);
        return $self;
    }

    sub test {
        my $self = shift;
        print $self->{test}, "\n";
    }
    1;

    package main;
    use strict;
    use warnings;

    my $obj = new PurpleWiki::SomeClass(test => "hello world");
    my $obj2 = PurpleWiki::SomeClass->instance();

    $obj->test();    # Prints hello world
    $obj2->test();   # Prints hello world


=head1 DESCRIPTION

PurpleWiki::Singleton is a virtual base class for enabling the Singleton 
pattern in classes that derive from it.  It is safe to use both for stand
alone modules and ones which persist in memory via mod_perl.

=head1 OBJECT STATE

=over

=item _singletonObjectInstance

If used without mod_perl then the derived class will have the global variable
_singletonObjectInstance inserted into its namespace.  Nothing is inserted in a
class's namespace if its used under mod_perl, so don't rely on this being there
and don't be surprised if it is there.

=back

=head1 CLASS METHODS

Class methods can only be called on the class and not on an object instance.
This means you must provide the full package name followd by -> and then the
method name.  For example:  PurpleWiki::Singleton->instance();

=over

=item instance()

Returns the last instance of the class saved by setInstance().  If no
such instance exists then undef is returned.

=item setInstance()

Sets the current instance of the class to be returned by instance().

=back

=head1 AUTHORS

Matthew O'Connor, E<lt>matthew@canonical.orgE<gt>

=head1 SEE ALSO

=over

=item L<Apache::Singleton>

L<PurpleWiki::Singleton> was derived in large part on the equivalent Apache
module.  However, the simplicity of the task and the burden of a module
dependancy ruled out using L<Apache::Singleton>.

=back

=cut

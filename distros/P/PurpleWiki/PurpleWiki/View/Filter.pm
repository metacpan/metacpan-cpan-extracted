# PurpleWiki::View::Filter.pm
#
# $Id: Filter.pm 366 2004-05-19 19:22:17Z eekim $
#
# Copyright (c) Blue Oxen Associates 2002-2004.  All rights reserved.
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

package PurpleWiki::View::Filter;
use 5.005;
use strict;
use warnings;
use Carp;
use PurpleWiki::View::Driver;

######## Package Globals ########

our $VERSION;
$VERSION = sprintf("%d", q$Id: Filter.pm 366 2004-05-19 19:22:17Z eekim $ =~ /\s(\d+)\s/);

our @ISA = qw(PurpleWiki::View::Driver);


######## Public Methods ########

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);

    # Object state.
    $self->{useOO} = 0 if not defined $self->{useOO};

    bless($self, $class);
    return $self;
}

sub process { 
    my $self = shift;
    $self->start(@_);
    $self->view(@_);
    $self->end(@_);
}

sub setFilter { shift->setFilters(@_) }

sub setFilters { 
    my ($self, %filters) = @_;
    map { $self->{$_} = $filters{$_} } keys %filters;
}


######## Private Methods ########

sub AUTOLOAD {
    our $AUTOLOAD;
    my $self = shift;
    my $method = $AUTOLOAD;

    # Remove all but the method name
    $method =~ s/(.*)://g;  # Reduces Foo::Bar::Baz::Quz::method to "method"

    # Bail on DESTROY, otherwise we'll cause an infinite loop when our object
    # is garbage collected.
    return if $method =~ /DESTROY/;

    if (defined $self->{$method}) {
        if ($self->{useOO}) {
            return $self->{$method}->($self, @_);
        } else {
            return $self->{$method}->(@_);
        }
    } elsif ($method eq "start" or $method eq "end") {
        return $self->noop(@_);
    }

    eval '$self->SUPER::'.$method.'(@_);';
    croak "Could not find method: $AUTOLOAD\n" if $@;
}
1;
__END__

=head1 NAME

PurpleWiki::View::Filter - A Quick Access View Filter.

=head1 SYNOPSIS

    #!/usr/bin/perl
    #
    # This program prints out all the image links on a page.
    # 
    use strict;
    use warnings;
    use PurpleWiki::Config;
    use PurpleWiki::Database::Page;
    use PurpleWiki::Parser::WikiText;
    use PurpleWiki::View::Filter;
    use Data::Dumper;

    my $pageName = shift || die "Usage: $0 page\n";

    my $config = new PurpleWiki::Config('/path/to/wikidb');
    my $parser = new PurpleWiki::Parser::WikiText;
    my $filter = new PurpleWiki::View::Filter();

    my $page = new PurpleWiki::Database::Page(id => $pageName);
                                              

    die "$page does not exist!\n" if not $page->pageExists();
    $page->openPage();

    my $tree = $parser->parse($page->getText()->getText(), 'add_node_ids'=>0);

    $filter->setFilter(imageMain => sub {print shift->content."\n"});
    $filter->process($tree);

=head1 DESCRIPTION

Filter allows the creation of quick, on the fly, view drivers without
the hassle of defining a new class and doing OO stuff.  You simply pass
in the name of the method you're "overloading" followed by the subroutine to
call for it. 

=head1 METHODS

=head2 new(useOO => $boolean, start => $subRef, stop => $subRef, methodName =>
           $subRef, ...)

Returns a new PurpleWiki::View::Filter object.

useOO is a boolean variable, if it's true then the subroutines are called with
$self as their first argument, otherwise they're called like normal functions.
The default is 0.

start and stop are special subroutines to be called before processing
beings and after, respectively.  The default is a noop().

The remainder of the arguments are methodName/suboutine reference pairs.  If
methodName is called then the corresponding subroutine is called instead
of the real method.

=head2 process($tree)

Causes the PurpleWiki::Tree $tree to be traversed.  This is the main access
point to the object.  Call the view() method, like on a normal view driver,
would cause the special start and stop methods not to be called.

=head2 setFilter(methodName => $subRef)

Adds a filter for methodName with subroutine reference $subRef

=head2 setFilters(methodName => $subRef, ...)

Like setFilter() but allows multiple definitions.

=head1 AUTHORS

Matthew O'Connor, E<lt>matthew@canonical.orgE<gt>

=head1 SEE ALSO

L<PurpleWiki::View::Driver>

=cut

# BEGIN BPS TAGGED BLOCK {{{
# COPYRIGHT:
# 
# This software is Copyright (c) 2003-2008 Best Practical Solutions, LLC
#                                          <clkao@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of either:
# 
#   a) Version 2 of the GNU General Public License.  You should have
#      received a copy of the GNU General Public License along with this
#      program.  If not, write to the Free Software Foundation, Inc., 51
#      Franklin Street, Fifth Floor, Boston, MA 02110-1301 or visit
#      their web page on the internet at
#      http://www.gnu.org/copyleft/gpl.html.
# 
#   b) Version 1 of Perl's "Artistic License".  You should have received
#      a copy of the Artistic License with this package, in the file
#      named "ARTISTIC".  The license is also available at
#      http://opensource.org/licenses/artistic-license.php.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of the
# GNU General Public License and is only of importance to you if you
# choose to contribute your changes and enhancements to the community
# by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with SVK,
# to Best Practical Solutions, LLC, you confirm that you are the
# copyright holder for those contributions and you grant Best Practical
# Solutions, LLC a nonexclusive, worldwide, irrevocable, royalty-free,
# perpetual, license to use, copy, create derivative works based on
# those contributions, and sublicense and distribute those contributions
# and any derivatives thereof.
# 
# END BPS TAGGED BLOCK }}}
package SVK::Command::Depotmap;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command );
use SVK::XD;
use SVK::I18N;
use SVK::Logger;
use SVK::Util qw( get_buffer_from_editor abs_path move_path );
use YAML::Syck;
use File::Path;

sub options {
    ('l|list' => 'list',
     'i|init' => 'init',
     'd|delete|detach' => 'detach',
     'relocate' => 'relocate');
}

sub parse_arg {
    my ($self, @arg) = @_;

    ++$self->{hold_giant};
    $self->rebless ('depotmap::add')->{add} = 1 if @arg >= 2 and !$self->{relocate};

    return undef
	unless $self->{add} or $self->{detach} or $self->{relocate};

        @arg or die loc("Need to specify a depot name.\n");

        my $depot = shift(@arg);
        @arg or die loc("Need to specify a path name for depot.\n")
            unless $self->{detach};

        my $map = $self->{xd}{depotmap};
        my $path = $depot;
        my $abs_path = abs_path($path);
        $depot =~ s{/}{}go;

        return ($depot, @arg) if $self->{add} or $map->{$depot} or !$abs_path;

        # Translate repospath into depotname
        foreach my $name (sort keys %$map) {
            (abs_path($map->{$name}) eq $abs_path) or next;
            move_path($path => $arg[0]) if $self->{relocate} and -d $path;
            return ($name, @arg);
        }

        return ($depot, @arg);
}

sub run {
    my ($self) = @_;
    my $sep = '===edit the above depot map===';
    my $map = YAML::Syck::Dump ($self->{xd}{depotmap});
    my $new;
    if ( !$self->{'init'} ) {
        do {
            $map =
              get_buffer_from_editor( loc('depot map'), $sep, "$map\n$sep\n",
                'depotmap' );
            $new = eval { YAML::Syck::Load($map) };
            $logger->info("$@") if $@;
        } while ($@);
        $logger->info( loc("New depot map saved."));
        $self->{xd}{depotmap} = $new;
    }
    $self->{xd}->create_depots;
    return;
}

package SVK::Command::Depotmap::add;
use base qw(SVK::Command::Depotmap);
use SVK::Logger;
use SVK::I18N;

sub run {
    my ($self, $depot, $path) = @_;

    die loc("Depot '%1' already exists; use 'svk depotmap --detach' to remove it first.\n", $depot)
        if $self->{xd}{depotmap}{$depot};

    $self->{xd}{depotmap}{$depot} = $path;

    $logger->info(loc("New depot map saved."));
    $self->{xd}->create_depots;
}

package SVK::Command::Depotmap::relocate;
use base qw(SVK::Command::Depotmap);
use SVK::Logger;
use SVK::I18N;

sub run {
    my ($self, $depot, $path) = @_;

    die loc("Depot '%1' does not exist in the depot map.\n", $depot)
        if !$self->{xd}{depotmap}{$depot};

    $self->{xd}{depotmap}{$depot} = $path;

    $logger->info( loc("Depot '%1' relocated to '%2'.\n", $depot, $path));
    $self->{xd}->create_depots;
}

package SVK::Command::Depotmap::detach;
use base qw(SVK::Command::Depotmap);
use SVK::Logger;
use SVK::I18N;

sub run {
    my ($self, $depot) = @_;
    delete $self->{xd}{depotmap}{$depot}
        or die loc("Depot '%1' does not exist in the depot map.\n", $depot);

    $logger->info( loc("Depot '%1' detached.\n", $depot));
    return;
}

package SVK::Command::Depotmap::list;
use base qw(SVK::Command::Depotmap);
use SVK::Logger;
use SVK::I18N;

sub parse_arg { undef }

sub run {
    my ($self) = @_;
    my $map = $self->{xd}{depotmap};
    my $fmt = "%-20s\t%-s\n";
    $logger->info(sprintf $fmt, loc('Depot'), loc('Path'));
    $logger->info( '=' x 60, "\n");
    $logger->info(sprintf $fmt, "/$_/", $map->{$_}) for sort keys %$map;
    return;
}

1;

__DATA__

=head1 NAME

SVK::Command::Depotmap - Create or edit the depot mapping configuration

=head1 SYNOPSIS

 depotmap [OPTIONS]
 depotmap DEPOTNAME /path/to/repository

 depotmap --list
 depotmap --detach [DEPOTNAME | PATH]
 depotmap --relocate [DEPOTNAME | PATH] PATH

=head1 OPTIONS

 -i [--init]            : initialize a default depot
 -l [--list]            : list current depot mappings
 -d [--detach]          : remove a depot from the mapping
 --relocate             : relocate the depot to another path

=head1 DESCRIPTION

Run this command without any options would bring up your C<$EDITOR>,
and let you edit your depot-directory mapping.

Each line contains a map entry, the format is:

 depotname: '/path/to/repos'

The depotname may then be used as part of a DEPOTPATH:

 /depotname/path/inside/repos

Depot creation respects $ENV{SVNFSTYPE}, which is default to fsfs for
svn 1.1 or later, and bdb for svn 1.0.x.


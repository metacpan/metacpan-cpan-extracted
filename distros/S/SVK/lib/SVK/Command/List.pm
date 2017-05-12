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
package SVK::Command::List;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command );
use constant opt_recursive => 0;
use SVK::XD;
use SVK::I18N;
use SVK::Util qw( to_native get_encoder reformat_svn_date );
use SVK::Logger;

sub options {
    ('r|revision=s'  => 'rev',
     'v|verbose'	   => 'verbose',
     'f|full-path'      => 'fullpath',
     'd|depth=i'      => 'depth');
}

sub parse_arg {
    my ($self, @arg) = @_;
    @arg = ('') if $#arg < 0;
    return map {$self->arg_co_maybe ($_)} @arg;
}

sub run {
    my ($self, @arg) = @_;
    my $exception = '';

    my $enc = get_encoder;
    if ( $self->{recursive} ) {
        $self->{depth}++ if $self->{depth};
    } else {
        $self->{recursive}++;
        $self->{depth} = 1;
    }
    my $errs = [];
    $self->run_command_recursively(
        $self->apply_revision($_),
        sub {
            my ( $target, $kind, $level ) = @_;
            if ( $level == -1 ) {
                return if $kind == $SVN::Node::dir;
                die loc( "Path %1 is not versioned.\n", $target->path_anchor )
                    unless $kind == $SVN::Node::file;
            }
            $self->_print_item( $target, $kind, $level, $enc );
        }, $errs, $#arg
    ) for map { $_->as_depotpath } @arg;

    return scalar @$errs;
}

sub _print_item {
    my ( $self, $target, $kind, $level, $enc ) = @_;
    my $root = $target->root;
    my $info_msg = '';
    if ( $self->{verbose} ) {
        my $rev = $root->node_created_rev( $target->path );
        my $fs  = $target->repos->fs;

        my $svn_date = $fs->revision_prop( $rev, 'svn:date' );

        # The author name may be undef
        no warnings 'uninitialized';

        # Additional fields for verbose: revision author size datetime
        $info_msg .= sprintf ("%7ld %-8.8s %10s %12s ", $rev,
            $fs->revision_prop( $rev, 'svn:author' ),
            ($kind == $SVN::Node::dir) ? "" : $root->file_length( $target->path ),
            reformat_svn_date( "%b %d %H:%M", $svn_date ));
    }

    my $output_path;
    if ( $self->{'fullpath'} ) {
        $output_path = $target->report;
    }
    else {
        $info_msg .= " " x ($level-1);
        $output_path = Path::Class::File->new_foreign( 'Unix', $target->path )
            ->basename;
    }
    to_native( $output_path, 'path', $enc );
    $info_msg .= $output_path. ( $kind == $SVN::Node::dir ? '/' : '' ); 
    $logger->info( $info_msg );
}

1;

__DATA__

=head1 NAME

SVK::Command::List - List entries in a directory from depot

=head1 SYNOPSIS

 list [DEPOTPATH | PATH...]

=head1 OPTIONS

 -r [--revision] REV    : act on revision REV instead of the head revision
 -R [--recursive]       : descend recursively
 -d [--depth] LEVEL     : recurse at most LEVEL levels deep; use with -R
 -f [--full-path]       : show pathname for each entry, instead of a tree
 -v [--verbose]         : print extra information


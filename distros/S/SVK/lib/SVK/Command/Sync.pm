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
package SVK::Command::Sync;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command );
use SVK::I18N;
use SVK::Logger;

sub options {
    ('s|skipto=s'	=> 'skip_to',
     'a|all'		=> 'sync_all',
     'follow-anchor-copy' => 'follow_anchor_copy',
     't|torev=s'	=> 'torev');
}

sub parse_arg {
    my ($self, @arg) = @_;
    return (@arg ? @arg : undef) if $self->{sync_all};

    return map {$self->arg_uri_maybe ($_)} @arg;
}

sub run {
    my ( $self, @arg ) = @_;

    my @mirrors;
    die loc("argument skipto not allowed when multiple target specified")
        if $self->{skip_to} && ( $self->{sync_all} || $#arg > 0 );

    if ( $self->{sync_all} ) {
        my %explicit = defined $arg[0] ? ( map { $_ => 1 } @arg ) : ();
        @arg = sort keys %{ $self->{xd}{depotmap} }
            unless defined $arg[0];
        for my $orig_arg (@arg) {
            my ( $arg, $path ) = $orig_arg =~ m{^/?([^/]*)/?(.*)?$};
            my ($depot) = eval { $self->{xd}->find_depot($arg) };
            unless ( defined $depot ) {
                $logger->error(loc( "%1 does not contain a valid depotname",
                    $orig_arg ));
                next;
           }

            my @tempnewarg = grep { SVK::Path->_to_pclass( "/$path", 'Unix' )->subsumes($_) }
                $depot->mirror->entries;

            if ( $path && $explicit{$orig_arg} && !@tempnewarg ) {
                $logger->warn(loc( "no mirrors found underneath %1", $orig_arg ));
                next;
            }
            push @mirrors, map { $depot->mirror->get($_) } @tempnewarg;
        }
    } else {
        @mirrors = map { $_->mirror->get( $_->path ) } @arg;
    }

    my $error;
    for my $m (@mirrors) {
        # XXX: in svk::mirrorcatalog, mirror objects are cached. we
        # might want per-instance options applied when using ->get.
        $m->follow_anchor_copy(1) if $self->{follow_anchor_copy};
	my $run_sync = sub {
	    $m->sync_snapshot($self->{skip_to}) if $self->{skip_to};
	    $m->run( $self->{torev} );
	    1;
	};
        if ( $self->{sync_all} ) {
            $logger->info(loc( "Starting to synchronize %1", $m->get_svkpath->depotpath ));
            eval { $run_sync->() };
            if ($@) {
		++$error;
                warn $@;
                last if ( $@ =~ /^Interrupted\.$/m );
            }
            next;
        }
        else {
	    $run_sync->();
        }
    }
    return $error ? 1 : 0;
}

1;

__DATA__

=head1 NAME

SVK::Command::Sync - Synchronize a mirrored depotpath

=head1 SYNOPSIS

 sync DEPOTPATH
 sync --all [DEPOTNAME|DEPOTPATH...]

=head1 OPTIONS

 -a [--all]             : synchronize all mirrored paths under
                          the DEPOTNAME/DEPOTPATH(s) provided
 -s [--skipto] REV      : start synchronization at revision REV
 -t [--torev] REV       : stop synchronization at revision REV


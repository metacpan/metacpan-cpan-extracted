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
package SVK::Command::Help;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command );
use SVK::I18N;
use SVK::Logger;
use SVK::Util qw( get_encoder can_run );
use autouse 'File::Find' => qw(find);

sub parse_arg { shift; @_ ? @_ : 'index'; }

# Note: lock is not called for help, as it's invoked differently from
# other commands.

sub run {
    my $self = shift;

    if($ENV{SVKPAGER} && can_run($ENV{SVKPAGER})){
        eval '$ENV{PAGER}=$ENV{SVKPAGER};use IO::Pager;IO::Pager->new(*STDOUT)';
    }

    foreach my $topic (@_) {
        if ($topic eq 'commands') {
            my @cmd;
            my $dir = $INC{'SVK/Command.pm'};
            $dir =~ s/\.pm$//;
            $logger->info( loc("Available commands:"));
            find (
                sub { push @cmd, $File::Find::name if m/\.pm$/ }, $dir,
            );
            $self->brief_usage ($_) for sort @cmd;
        }
        elsif (my $cmd = eval { SVK::Command->get_cmd ($topic) }) {
            $cmd->usage(1);
        }
        elsif (my $file = $self->_find_topic($topic)) {
            open my $fh, '<:utf8', $file or die $!;
            my $parser = Pod::Simple::Text->new;
            my $buf;
            $parser->output_string(\$buf);
            $parser->parse_file($fh);

            $buf =~ s/^NAME\s+SVK::Help::\S+ - (.+)\s+DESCRIPTION/    $1:/;

            $logger->info( get_encoder->encode($buf));
        }
        else {
            die loc("Cannot find help topic '%1'.\n", $topic);
        }
    }
    return;
}

my ($inc, @prefix);
sub _find_topic {
    my ($self, $topic) = @_;

    if (!$inc) {
        my $pkg = __PACKAGE__;
        $pkg =~ s{::}{/};
        $inc = substr( __FILE__, 0, -length("$pkg.pm") );

        @prefix = (loc("SVK::Help"));
        $prefix[0] =~ s{::}{/}g;
        push @prefix, 'SVK/Help' if $prefix[0] ne 'SVK/Help';
    }

    foreach my $dir ($inc, @INC) {
        foreach my $prefix (@prefix) {
            foreach my $basename (ucfirst(lc($topic)), uc($topic)) {
                foreach my $ext ('pod', 'pm') {
                    my $file = "$dir/$prefix/$basename.$ext";
                    return $file if -f $file;
                }
            }
        }
    }

    return;
}

1;

__DATA__

=head1 NAME

SVK::Command::Help - Show help

=head1 SYNOPSIS

 help COMMAND

=head1 OPTIONS

Optionally, svk help can pipe output through a pager, which is
easier to read if the output is long. To use this feature, set the
environmental variable SVKPAGER to some pager program.

For example:

    # bash, zsh users
    export SVKPAGER='/usr/bin/less'

    # tcsh users
    setenv SVKPAGER '/usr/bin/less'


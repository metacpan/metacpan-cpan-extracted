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
package SVK::Resolve::Emacs;
use strict;
use base 'SVK::Resolve';
use SVK::I18N;
use SVK::Util qw( devnull );
use SVK::Logger;

sub commands { 'gnuclient-emacs' }

sub arguments {
    my $self = shift;
    my $lisp = "(require 'svk-ediff)";

    # set up the signal handlers
    $self->{signal} ||= 'USR1';

    if ($self->{base} eq devnull()) {
        $lisp .= qq(
(ediff-files-internal
 "$self->{yours}" "$self->{theirs}" nil
 nil 'ediff-merge-files)
);
    } else {
        $lisp .= qq(
(ediff-files-internal
 "$self->{yours}" "$self->{theirs}" "$self->{base}"
 nil 'ediff-merge-files-with-ancestor)
)
    }

    $lisp .= qq(
(svk-merge-startup '((working-file . "$self->{yours}")
                       (selected-file . "$self->{theirs}")
                       (common-file . "$self->{base}")
                       (working-label . "$self->{label_yours}")
                       (selected-label . "$self->{label_theirs}")
                       (common-label . "$self->{label_base}")
                       (output-file . "$self->{merged}")
                       (process . $$)
                       (signal . SIG$self->{signal})))
'OK!
);

    return ('--eval' => $lisp);
}

sub run_resolver {
    my ($self, $cmd, @args) = @_;

    local $SIG{$self->{signal}} = sub {
        $logger->info(loc("Emerge %1 done."));
        $self->{finished} = 1;
    };

    my $pid;
    if (!defined($pid = fork)) {
        die loc("Cannot fork: %1", $!);
    }
    elsif ($pid) {
        $logger->warn(loc(
            "Started %1, Try 'kill -%2 %3' to terminate if things mess up.",
            $pid, $self->{signal}, $$,
        ));
        sleep 1 until $self->{finished};
    }
    else {
        exec($cmd, @args) or die loc("Could not run %1: %2", $cmd, $!);
    }

    return $self->{finished};
}

1;

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
package SVK::Resolve::TkDiff;
use strict;
use base 'SVK::Resolve';

sub xfind_command {
    my $self = shift;
    $self->{diff3} = $self->SUPER::find_command('diff3') or return;
    return $self->SUPER::find_command(@_);
}

sub arguments {
    my $self = shift;

    open my $in, '<', $self->{merged} or die $!;
    open my $out, '>', "$self->{merged}.tkdiff" or die $!;

    while (<$in>) {
        if (m/==== .*$self->{marker}/) {
            print $out "=======\n";
            while (<$in>) {
                last if m/==== .*$self->{marker}/;
            }
            next;
        }

        if (/^([<>])(?=.*$self->{marker})/) {
            if ($1 eq '<') {
                print $out ">>>>>>> YOURS $self->{marker}\n";
            }
            else {
                print $out "<<<<<<< THEIRS $self->{marker}\n";
            }
            next;
        }
        print $out $_;
    }
    
    return (
        -conflict => "$self->{merged}.tkdiff",
        -o        => $self->{merged},
    );
}

sub run_resolver {
    my $self = shift;
    $self->SUPER::run_resolver(@_);
    return -e $self->{merged};
}

sub DESTROY {
    my $self = shift;
    unlink "$self->{merged}.tkdiff";
}

1;

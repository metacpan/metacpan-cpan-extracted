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
package SVK;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

# Load classes on demand.
use Class::Autouse qw(SVK::Command);

use SVN::Core;
BEGIN {
    # autouse hates Devel::DProf. If we're running with DProf,
    # we need to emasculate autouse by blowing a new import sub into its
    # package at runtime.
    if($main::INC{'Devel/DProf.pm'})  {
	no strict 'refs';
	$main::INC{'autouse.pm'} = __FILE__;
	*{'autouse::import'} = sub {
	    require UNIVERSAL::require;
	    shift; # get rid of $CLASS
	    my $class = shift;
	    $class->require or die "$class: $!";
	    my @arg = @_;
	    $class->export_to_level(1, undef, map {s/\(.*\)//g;$_} @arg);
        }
    }
}

sub import {
    return unless ref ($_[0]);
    our $AUTOLOAD = 'import';
    goto &AUTOLOAD;
}

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    %$self = @_;
    return $self;
}

sub AUTOLOAD {
    my $cmd = our $AUTOLOAD;
    $cmd =~ s/^SVK:://;
    return if $cmd =~ /^[A-Z]+$/;

    no strict 'refs';
    no warnings 'redefine';
    *$cmd = sub {
        my $self = shift;
        my ($buf, $output, $ret) = ('');
        open $output, '>', \$buf if $self->{output};
        eval { $ret = SVK::Command->invoke ($self->{xd}, $cmd, $output, @_) };
        if ($output) {
            close $output;
            ${$self->{output}} = $buf;
        }
        return $ret;
    };
    goto &$cmd;
}

1;

__DATA__

=head1 NAME

SVK - A Distributed Version Control System

=head1 SYNOPSIS

  use SVK;
  use SVK::XD;
  $xd = SVK::XD->new (depotmap => { '' => '/path/to/repos'});

  $svk = SVK->new (xd => $xd, output => \$output);
  # serialize the $xd object for future use.

  $svk->ls ('//'); # check $output for its output
  ...

=head1 DESCRIPTION

C<SVK> is the class that loads L<SVK::Command> and invokes them. You can
use it in your program to do what you do with the L<svk> command line
interface.

=head1 CONSTRUCTOR

Options to C<new>:

=over

=item xd

L<SVK::XD> object that handles depot and checkout copy mapping.

=item output

A scalar reference. After command invocation the output will be stored
in the scalar. By default the output is not held in any scalar and
will be printed to STDOUT.

=back

=head1 METHODS

All methods are autoloaded and deferred to
C<SVK::Command-E<gt>invoke>.

=head1 SEE ALSO

L<svk>, L<SVK::XD>, L<SVK::Command>.

=cut


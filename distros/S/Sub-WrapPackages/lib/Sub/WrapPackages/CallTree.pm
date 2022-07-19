package Sub::WrapPackages::CallTree;

use strict;
use warnings;

use Sub::WrapPackages ();

our $VERSION = '2.02';

sub import {
    my $indent = '';
    Sub::WrapPackages->import(
        packages => [@_[1 .. $#_]],
        wrap_inherited => 1,
        pre => sub {
            print STDERR "${indent}Called $_[0] with: [".join(', ', @_[1..$#_])."]\n";
            $indent .= '  ';
        },
        post => sub {
            $indent = substr($indent, 2);
            print STDERR "${indent}Return from $_[0] with: [".join(', ', @_[1 .. $#_])."]\n";
        }
    );
}

1;

=head1 NAME

Sub::WrapPackages::CallTree

=head1 DESCRIPTION

Tool that uses Sub::WrapPackages to show on STDERR a tree of function calls as
your code runs, including arguments and a list of return values

=head1 SYNOPSIS

In your code - in a test file, perhaps:

    use Sub::WrapPackages::CallTree qw(My::App::* And::Another::Namespace)

Or in your environment:

    PERL5OPT=-MSub::WrapPackages::CallTree=My::App::*,And::Another::Namespace

The results will look something like this:

    Called Sub::WrapPackages::Tests::Victim::foo with: [Sub::WrapPackages::Tests::Victim]
      Called Sub::WrapPackages::Tests::Victim::bar with: [1]
        Called Sub::WrapPackages::Tests::Victim::baz with: [OMG, ROBOTS, 5]
        Return from Sub::WrapPackages::Tests::Victim::baz with: [OMG, ROBOTS, 5]
      Return from Sub::WrapPackages::Tests::Victim::bar with: [OMG, ROBOTS, 5]
    Return from Sub::WrapPackages::Tests::Victim::foo with: [2, OMG, ROBOTS, 5]

NB that all arguments and return values are stringified for display, as there
is no way of nicely displaying a tree of function calls as well as complex data
structures, and the tree of function calls is more important.

=head1 PARAMETERS

The arguments are the same as those you would pass as the C<packages> option
to L<Sub::WrapPackages>. The other options have sensible defaults and can not
(currently) be set. If you would like to be able to over-ride the defaults
please submit a pull request with tests.

=head1 BUGS and IMPROVEMENTS

Please report bugs and submit improvements via Github.

=head1 THANKS TO

Thanks to Will Shepherd, who berated me for cut n pasting the code that
implements this all over the place while debugging, and prompting me to wrap it
up into a much smaller piece of code that I can splatter all over the place
while debugging.

=head1 COPYRIGHT and LICENCE

Copyright 2022 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used, distributed, and
modified under the terms of either the GNU General Public Licence version 2 or
the Artistic Licence. It's up to you which one you use. The full text of the
licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This code is also free-as-in-mason.

=cut


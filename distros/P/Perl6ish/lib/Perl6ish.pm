package Perl6ish;

use strict;
use warnings;
our $VERSION = '0.02';

sub import {
    my $caller = caller;

    eval <<CODI;
package $caller;
use Perl6::Perl 'perl';
use Perl6::Slurp;
use Perl6::Caller;
use Perl6::Take;
use Perl6::Say;
use Perl6::Contexts;
use Perl6::Junction qw/all any one none/;
use Perl6ish::Syntax::temp;
use Perl6ish::Syntax::state;
use Perl6ish::Syntax::constant;
use Perl6ish::Array;
use Perl6ish::Hash;
use Perl6ish::String;
use Perl6ish::Syntax::DotMethod;

use Perl6ish::Autobox;

CODI

    return 1;
}

1;
__END__

=head1 NAME

Perl6ish - Some Perl6 programming in Perl5 code.

=head1 SYNOPSIS

  use Perl6ish;

=head1 DESCRIPTION

Perl6ish allows you to write Perl5 code some Perl6 look-n-feel. It
uses many good evil techniques to extend Perl5 syntax. Many of which
has been already done in the C<Perl6::*> namespace, some of them are
coded only in the Perl6ish distrition.

When you say C<use Perl6ish> in your code, it's exactualy the same
as saying this:

    use Perl6::Perl 'perl';
    use Perl6::Slurp;
    use Perl6::Caller;
    use Perl6::Take;
    use Perl6::Say;
    use Perl6::Contexts;
    use Perl6::Junction qw/all any one none/;
    use Perl6ish::Syntax::temp;
    use Perl6ish::Syntax::state;
    use Perl6ish::Syntax::constant;
    use Perl6ish::Array;
    use Perl6ish::Hash;
    use Perl6ish::String;
    use Perl6ish::Syntax::DotMethod;

C<Perl6ish::Syntax::*> modules are syntax extensions. Variable
declarators, C<temp>, C<state> and C<constant>, are implemented under
this namespace. They can be used alone if you prefer not to load all
those moduels above all at once.

=head1 AUTHOR

Kang-min Liu E<lt>gugod@gugod.orgE<gt>

=head1 SEE ALSO

L<Rubyish>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

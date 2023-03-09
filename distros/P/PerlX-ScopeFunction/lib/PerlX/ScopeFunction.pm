package PerlX::ScopeFunction;
use v5.36;

our $VERSION = "0.01";

use Keyword::Simple;
use Text::Balanced qw( extract_bracketed extract_codeblock );

sub import {
    Keyword::Simple::define 'with', \&__rewrite_with;
}

sub unimport {
    Keyword::Simple::undefine 'with';
}

sub __rewrite_with {
    my ($ref) = @_;
    my $remainder;
    (my $expr, $remainder) = extract_bracketed($$ref, '()');
    (my $codeBlock, $remainder) = extract_codeblock( $remainder );
    $codeBlock =~ s/\{/\{ local \$_ = \$_[-1];/;
    my $code = '(sub ' . $codeBlock . ')->' . $expr . ";";
    $$ref = $code . $remainder;
}

1;

__END__

=head1 NAME

PerlX::ScopeFunction -- new keywords for creating scopes.

=head1 SYNOPSIS

Use C<with> keyword to constraint the result of the given expression
to a smaller lexical scope.

    with ( grep { $_ % 2 == 0 } @input ) {
        my @even_nums = @_;

        say "There are " . scalar(@even_nums) . " even numbers";
    }

=head1 DESCRIPTION

Scope functions can be used to create small lexical scope, inside
which the results of an given expression are used, but not outside.

=head2 C<with> (EXPR) BLOCK

The C<with> keyword can be used to bring the result of an given EXPR
to a smaller scope (code block):

    with ( EXPR ) BLOCK

The EXPR are evaluated in list context, and the result (a list) is
available inside BLOCK as C<@_>. The conventional topic variable C<$_>
is also assigned the last value of the list (C<$_[-1]>).

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>

=head1 LICENCE

The MIT License

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

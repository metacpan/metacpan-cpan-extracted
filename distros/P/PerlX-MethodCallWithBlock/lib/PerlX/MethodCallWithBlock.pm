package PerlX::MethodCallWithBlock;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.05';

use Devel::Declare ();
use B::Hooks::EndOfScope ();
use B::OPCheck ();

use PPI;
use PPI::Document;

sub inject_close_paren {
    my $linestr = Devel::Declare::get_linestr;
    my $offset = Devel::Declare::get_linestr_offset;
    substr($linestr, $offset, 0) = ')';
    Devel::Declare::set_linestr($linestr);
}

sub checker {
    my ($op, @args) = @_;
    my $offset = Devel::Declare::get_linestr_offset;
    $offset += Devel::Declare::toke_skipspace($offset);
    my $linestr = Devel::Declare::get_linestr;

    return if $offset > length($linestr);

    my $code = substr($linestr, $offset);

    my $doc = PPI::Document->new(\$code);
    return unless $doc;

    # find the structure of "->method(...) {"
    my $found = $doc->find(
        sub {
            my $el = $_[1];
            return 0 unless $el->class eq 'PPI::Token::Operator' && $el->content eq '->';
            my $word = $el->snext_sibling or return 0;
            return 0 unless $word->class eq 'PPI::Token::Word';

            my $args = $word->snext_sibling or return 0;
            if ($args->class eq 'PPI::Structure::List') {
                my $block = $args->snext_sibling or return 0;
                return 0 unless $block->class eq 'PPI::Structure::Block';
            }
            elsif ($args->class ne 'PPI::Structure::Block') {
                return 0
            }

            return 1;
        }
    );
    return unless $found;

    my $injected_code = 'sub { BEGIN { B::Hooks::EndOfScope::on_scope_end(\&PerlX::MethodCallWithBlock::inject_close_paren); }';

    my $pnode;
    $code = "";
    for my $node (@$found) {
        $pnode = $node;

        while($pnode) {
            my $prev_node = $pnode;
            while ($prev_node = $prev_node->previous_sibling) {
                $code = $prev_node->content . $code;
            }
            $pnode = $pnode->parent;
        }

        $code .= join "", map { $_->content } ($node, $node->snext_sibling);
        my $word = $node->snext_sibling;
        if ($word->snext_sibling->class eq 'PPI::Structure::Block') {
            my $block = $word->snext_sibling;
            my @block_elements = $block->elements;
            # one-line block, we see the whole thing here.
            if ($block_elements[0] eq '{' && $block_elements[-1] eq '}') {
                my $block_code = $node->snext_sibling->snext_sibling->content;
                $code .= "(sub $block_code)";

                # There might be something more after the block...
                my $next_node = $block->next_sibling;
                while ($next_node) {
                    $code .= $next_node->content;
                    $next_node = $next_node->next_sibling;
                }
            } else {
                $code .= "($injected_code";
            }
        }
        else {
            my $args = $word->snext_sibling->content;
            $args =~ s/\)$/,$injected_code/;
            $code .= $args;
        }
        substr($linestr, $offset) = $code;
        Devel::Declare::set_linestr($linestr);
    }
}

sub import {
    my $caller = caller;
    my $offset  = Devel::Declare::get_linestr_offset();
    my $linestr = Devel::Declare::get_linestr();

    substr($linestr, $offset, 0) = q[BEGIN { B::OPCheck->import($_ => check => \&PerlX::MethodCallWithBlock::checker) for qw(const pushmark lineseq refgen sassign); }];
    Devel::Declare::set_linestr($linestr);
}

1;
__END__

=head1 NAME

PerlX::MethodCallWithBlock - A Perl extension to allow a bare block after method call

=head1 SYNOPSIS

    use PerlX::MethodCallWithBlock;

    Foo->bar(1, 2, 3) {
      say "and a block";
    };

=head1 DESCRIPTION

PerlX::MethodCallWithBlock is A Perl extension that extends Perl
syntax to allow one bare block follows normal methods calls.

It translate:

    Foo->bar(1, 2, 3) {
      say "and a block";
    };

Into:

    Foo->bar(1, 2, 3, sub {
      say "and a block";
    });

The body of the C<Foo::bar> method sees it as the very last argument.

=head1 NOTICE

This version is released as a proof that it can be done. However, the
internally parsing code for translating codes are very fragile at this
moment.

It's very possible that your code breaks after you re-indent it. You
should send me that piece of code as a failing test if you find such
cases.

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

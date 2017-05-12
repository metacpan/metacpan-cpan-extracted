package Regexp::Optimizer;

use 5.008001;
use strict;
use warnings FATAL => 'all';
use Regexp::Assemble;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.23 $ =~ /(\d+)/g;

my $re_nested;
$re_nested = qr{
  \(                   # open paren
  ((?:                 # start capture  
    (?>[^()]+)       | # Non-parens w/o backtracking or ...
    (??{ $re_nested }) # Group with matching parens
  )*)                  # end capture
  \)                   # close paren
}msx;

my $re_optimize = qr{(?<=[^\\])\|}ms;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub _assemble {
    my $str = shift;
    return $str if $str !~ $re_optimize;
    if ( $str !~ m/[(]/ms ) {
        my $ra = Regexp::Assemble->new();
        $ra->add( split m{[|]}, $str );
        return $ra->as_string;
    }
    $str =~ s{$re_nested}{
        no warnings 'uninitialized';
        my $sub = $1;
        if ($sub =~ m/\A\?(?:[\?\{\(PR]|[\+\-]?[0-9])/ms) {
            "($sub)";  # (?{CODE}) and like ruled out
        }else{
            my $mod = ($sub =~ s/\A\?//) ? '?' : '';
            if ($mod) {
                $sub =~ s{\A(
                              [\w\^\-]*: | # modifier
                              [<]?[=!]   | # assertions
                              [<]\w+[>]  | # named capture
                              [']\w+[']  | # ditto
                              [|]          # branch reset
                          )
                     }{}msx;
                $mod .= $1;
            }
            '(' . $mod . _assemble($sub) . ')'
        }
    }msxge;
    $str;
}

sub as_string {
    my ( $self, $str ) = @_;
    return $str if $str !~ $re_optimize;
    my ($mod) = ($str =~ m/\A\(\?(.*?):/);
    if ( $mod =~ /x/ ) {
        $str =~ s{^\s+}{}mg;
        $str =~ s{(?<=[^\\])\s*?#.*?$}{}mg;
        $str =~ s{\s+[|]\s+}{|}mg;
        $str =~ s{(?:\r\n?|\n)}{}msg;
        $str =~ s{[ ]+}{ }msgx;
        # warn $str;
    }
    # escape all occurance of '\(' and '\)'
    $str =~ s/\\([\(\)])/sprintf "\\x%02x" , ord $1/ge;
    _assemble($str);
}

sub optimize {
    my $self = shift;
    my $re   = $self->as_string(shift);
    qr{$re};
}

1; # End of Regexp::Optimizer

__END__

=head1 NAME

Regexp::Optimizer - optimizes regular expressions

=head1 VERSION

$Id: Optimizer.pm,v 0.23 2013/02/26 05:47:41 dankogai Exp dankogai $

=head1 SYNOPSIS

  use Regexp::Optimizer;
  my $o  = Regexp::Optimizer->new->optimize(qr/foobar|fooxar|foozap/);
  # $re is now qr/foo(?:[bx]ar|zap)/

=head1 EXPORT

none.

=head1 SUBROUTINES/METHODS

=head2 new

Makes a new optimizer instance.

  my $ro = Regexp::Optimizer->new;

=head2 optimize

Does the optimization.

  my $re = qr/foobar|fooxar|foozap/;
  $re = $ro->optimize($re);

If it is already optimized -- no alteration in the regexp, it is
practically an identity function which simply returns an argument.

If not, it dissasembles the regexp, feeds it to L<Regexp::Assemble>,
and reassembles the result.

=head2 as_string

Same as C<optimize()> but returns a string instead of regexp object.

=head1 CAVEAT

=head2 ??{CODE} used

This module depends on the C<??{CODE}> regexp construct which is still
considered experimental as of Perl 5.16.

=head2 not idempotent

If you feed the regexp that is already optimized, the resulting regexp
may not necessarily the same -- usually you get duplicate C<(?:)>:

    my $re = qr/foobar|fooxar|foozap/;
    $re = $ro->optimize($re); # qr/foo(?:[bx]ar|zap)/
    $re = $ro->optimize($re); # qr/foo(?:(?:[bx]ar|zap))/

=head1 SEE ALSO

L<Regexp::Assemble>, L<perlre>

=head1 AUTHOR

Dan Kogai, C<< <dankogai+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-regexp-optimizer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Regexp-Optimizer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Regexp::Optimizer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Regexp-Optimizer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Regexp-Optimizer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Regexp-Optimizer>

=item * Search CPAN

L<http://search.cpan.org/dist/Regexp-Optimizer/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dan Kogai.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

# ABSTRACT: Op tree analysis for perl 5.36
# PODNAME: Pod::Coverage::More::Analyzer::Perl5_36

package Pod::Coverage::More::Analyzer::Perl5_36 0.003;

use 5.036;
use warnings FATAL => q{all};

use parent 'Pod::Coverage::More::Analyzer';


sub op_handlers {
    my ($self) = @_;
    return {
        %{ $self->SUPER::op_handlers() },
        argcheck => \&_on_argcheck,
        argelem  => \&_on_argelem,
    };
}

# A placeholder parameter ($ or $=) has no argelem op, so only argcheck's count shows it.
sub finish_sub {
    my ( $self, $record ) = @_;
    my $signature = $self->{signature} or return;
    my %seen      = map { $_->{index} => 1 } @{ $record->{params} };
    foreach my $index ( 0 .. $signature->{params} - 1 ) {
        next if $seen{$index};
        $self->_add_param(
            name     => undef,
            index    => $index,
            source   => 'signature',
            optional => ( $index >= $signature->{mandatory} ) ? 1 : 0,
        );
    }
    return;
}

sub _on_argcheck {
    my ( $self, $op ) = @_;
    my ( $params, $optional, $slurpy ) = $op->aux_list( $self->{cv} );
    $self->{rec}{signature} = 1;
    $self->{signature} = { params => $params, mandatory => $params - $optional, slurpy => $slurpy };
    return;
}

sub _on_argelem {
    my ( $self, $op ) = @_;
    my $index = $op->string( $self->{cv} );
    my $name  = $self->_padname( $op->targ );
    my %param = (
        name     => $name,
        index    => $index,
        source   => 'signature',
        optional => ( $index >= ( $self->{signature}{mandatory} // 0 ) ) ? 1 : 0,
    );

    my ($default) = $self->op_kids($op);
    if ( $default && $default->name eq 'argdefelem' ) {
        $param{default} = { mode => $self->default_mode($default), value => [ $self->classify( $default->first ) ] };
    }
    $self->_add_param(%param);
    return;
}

# How the default of a signature parameter applies, from its C<argdefelem> op.
# 5.36 has only C<=>, a default for a missing argument.  Later version sets read the flags of the op.
# @param   argdefelem  B::UNOP  the op of the default
# @returns Str  C<=>, C<//=> or C<||=>
# @example my $mode = $self->default_mode($argdefelem);
sub default_mode {
    return '=';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Coverage::More::Analyzer::Perl5_36 - Op tree analysis for perl 5.36

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Adds the ops that this version set compiles signatures into:
one C<argcheck> op with the counts of parameters,
then one C<argelem> op per named parameter, with an C<argdefelem> kid when it has a default.

See C<deparse_argops> in the L<B::Deparse> of these perls for the reference reading of these ops.

5.38 to 5.42 compile signatures the same way, so L<Pod::Coverage::More::Analyzer::Perl5_38> inherits this.
In 5.36, C<my $x = EXPR> is always an C<sassign> op, which the base class reads.

=head1 METHODS

=head2 default_mode(argdefelem)

How the default of a signature parameter applies, from its C<argdefelem> op. 5.36 has only C<=>, a default for a missing argument.  Later version sets read the flags of the op.

=over 4

=item argdefelem - InstanceOf["B::UNOP"] - the op of the default

=back

Returns Str, C<=>, C<//=> or C<||=>.

    my $mode = $self->default_mode($argdefelem);

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Pod::Coverage::More|Pod::Coverage::More>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/Pod-Coverage-More/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2026 George S. Baugh


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

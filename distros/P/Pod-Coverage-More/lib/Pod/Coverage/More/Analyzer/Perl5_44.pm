# ABSTRACT: Op tree analysis for perl 5.44 and later
# PODNAME: Pod::Coverage::More::Analyzer::Perl5_44

package Pod::Coverage::More::Analyzer::Perl5_44 0.005;

use 5.036;
use warnings FATAL => q{all};

use B ();

use parent 'Pod::Coverage::More::Analyzer::Perl5_38';


sub op_handlers {
    my ($self) = @_;
    my %handlers = %{ $self->SUPER::op_handlers() };
    delete @handlers{qw{argcheck argelem}};
    return {
        %handlers,
        multiparam => \&_on_multiparam,
        paramtest  => \&_on_paramtest,
    };
}

# The placeholders that Perl5_36 fills in from argcheck are listed in multiparam itself,
# and so is the implicit $self of a method of the core class feature.
sub finish_sub {
    my ( $self, $record ) = @_;
    return if !( $self->{cv}->CvFLAGS & B::CVf_IsMETHOD );
    $record->{method} = 1;
    $self->_add_invocant($record);
    return;
}

sub _on_multiparam {
    my ( $self, $op ) = @_;
    my ( $min, $max, $slurpy, @rest ) = $op->aux_list( $self->{cv} );
    $self->{rec}{signature} = 1;
    my @padix = splice( @rest, 0, $max );
    my ($slurpy_padix) = @rest;

    foreach my $index ( 0 .. $#padix ) {
        $self->_add_param(
            name     => $self->_padname( $padix[$index] ),
            index    => $index,
            source   => 'signature',
            optional => ( $index >= $min ) ? 1 : 0,
        );
    }
    if ($slurpy) {
        $self->_add_param(
            name     => $self->_padname($slurpy_padix),
            index    => $max,
            source   => 'signature',
            slurpy   => 1,
            optional => 1,
        );
    }
    return;
}

# The default of the parameter whose pad entry is the op's own.
sub _on_paramtest {
    my ( $self, $op ) = @_;
    my ($store) = $self->op_kids($op);
    return unless $store && $store->name eq 'paramstore';

    my $mode = '=';
    $mode = '//=' if $op->private == B::OPpPARAM_IF_UNDEF;
    $mode = '||=' if $op->private == B::OPpPARAM_IF_FALSE;

    my ($expr) = $self->op_kids($store);
    my $default = { mode => $mode, value => ( $expr && $expr->name ne 'stub' ) ? [ $self->classify($expr) ] : [] };

    my $name = $self->_padname( $op->targ );
    foreach my $param ( @{ $self->{rec}{params} } ) {
        $param->{default} = $default if defined $param->{name} && defined $name && $param->{name} eq $name;
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Coverage::More::Analyzer::Perl5_44 - Op tree analysis for perl 5.44 and later

=head1 VERSION

version 0.005

=head1 DESCRIPTION

Keeps the ops of L<Pod::Coverage::More::Analyzer::Perl5_38>, and replaces the ops that signatures compile into.
This version set compiles a signature into
one C<multiparam> op that lists every parameter,
then one C<paramtest> op, with a C<paramstore> kid, per parameter that has a default.

See C<deparse_multiparam> in the L<B::Deparse> of these perls for the reference reading of these ops.

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

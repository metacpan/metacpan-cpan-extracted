use strict;
use warnings;
package Test::Deep::YAML; # git description: v0.003-2-g42e13ef
# ABSTRACT: A Test::Deep plugin for comparing YAML-encoded data
# KEYWORDS: testing tests plugin YAML data
# vim: set ts=8 sts=4 sw=4 tw=78 et :

our $VERSION = '0.004';

use Exporter 'import';

our @EXPORT = qw(yaml);

sub yaml
{
    my ($expected) = @_;
    return Test::Deep::YAML::Object->new($expected);
}

package # hide from PAUSE
    Test::Deep::YAML::Object;

our $VERSION = '0.004';

use parent 'Test::Deep::Cmp';
use Try::Tiny ();
use YAML ();

sub init
{
    my ($self, $expected) = @_;
    $self->{val} = $expected;
}

sub descend
{
    my ($self, $got) = @_;

    my $data = Try::Tiny::try
    {
        YAML::Load($got);
    }
    Try::Tiny::catch
    {
        chomp($self->{error_message} = $_);
        undef;
    };

    return 0 if not $data or $self->{error_message};

    return Test::Deep::wrap($self->{val})->descend($data);
}

sub diagnostics
{
    my ($self, $where, $last) = @_;
    return $self->{error_message}
        || $self->{val}->diagnostics($where, $last);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Deep::YAML - A Test::Deep plugin for comparing YAML-encoded data

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Test::More;
    use Test::Deep;
    use Test::Deep::YAML;

    cmp_deeply(
        "---\nfoo: bar\n",
        yaml({ foo => 'bar' }),
        'YAML-encoded data is correct',
    );

=head1 DESCRIPTION

=for stopwords yaml

This module provides the C<yaml> function to indicate that the target can be
parsed as a YAML string, and should be decoded before being compared to the
indicated expected data.

=head1 FUNCTIONS

=for Pod::Coverage descend diagnostics init

=head2 yaml

Contains the data which should match corresponding data in the "got" structure
after it has been YAML-decoded.

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Deep-YAML>
(or L<bug-Test-Deep-YAML@rt.cpan.org|mailto:bug-Test-Deep-YAML@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=over 4

=item *

L<Test::Deep>

=item *

L<Test::Deep::JSON>

=back

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

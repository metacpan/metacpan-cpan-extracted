package Tangerine::hook::use;
$Tangerine::hook::use::VERSION = '0.23';
use 5.010;
use strict;
use warnings;
use parent 'Tangerine::Hook';
use Tangerine::HookData;
use Tangerine::Occurence;
use Tangerine::Utils qw(any $vre);

sub run {
    my ($self, $s) = @_;
    if (scalar(@$s) > 1 && (any { $s->[0] eq $_ } qw(use no))) {
        return if $s->[1] eq ';';
        my $module = $s->[1];
        my ($version) = $s->[2] && $s->[2] =~ $vre;
        $version //= '';
        return Tangerine::HookData->new(
            modules => {
                $module => Tangerine::Occurence->new(
                    version => $version,
                    ),
                },
            ) unless $module =~ /^v?5(?:\..*)?$/;
    }
    return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tangerine::hook::use - Process C<use> statements

=head1 DESCRIPTION

This is a basic C<compile> type hook, simply looking for C<use> statements,
not doing anything fancy.

=head1 SEE ALSO

L<Tangerine>

=head1 AUTHOR

Petr Šabata <contyk@redhat.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016 Petr Šabata.

See LICENSE for licensing details.

=cut

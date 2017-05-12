package Tangerine::hook::package;
$Tangerine::hook::package::VERSION = '0.23';
use strict;
use warnings;
use parent 'Tangerine::Hook';
use Tangerine::HookData;
use Tangerine::Occurence;

sub run {
    my ($self, $s) = @_;
    if ($s->[0] eq 'package' && scalar(@$s) > 1) {
        return if $s->[1] eq ';';
        return Tangerine::HookData->new(
            modules => {
                $s->[1] => Tangerine::Occurence->new,
                },
            );
    }
    return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tangerine::hook::package - Process C<package> statements

=head1 DESCRIPTION

This is a basic C<package> type hook, simply looking for C<package> statements.

=head1 SEE ALSO

L<Tangerine>

=head1 AUTHOR

Petr Šabata <contyk@redhat.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016 Petr Šabata

See LICENSE for licensing details.

=cut

package Tangerine::hook::moduleload;
$Tangerine::hook::moduleload::VERSION = '0.23';
use strict;
use warnings;
use parent 'Tangerine::Hook';
use Tangerine::HookData;
use Tangerine::Utils qw(any stripquotelike);

sub run {
    my ($self, $s) = @_;
    my @routines = qw(load autoload load_remote autoload_remote);
    if ((any { $s->[0] eq $_ } qw(use no)) && scalar(@$s) > 1 &&
        $s->[1] eq 'Module::Load') {
        return Tangerine::HookData->new( hooks => [
                Tangerine::hook::moduleload->new(type => 'runtime') ] );
    }
    if ($self->type eq 'runtime' && (any { $s->[0] eq $_ } @routines) &&
        scalar(@$s) > 2)
    {
        return Tangerine::HookData->new(
            children => [ 'use', stripquotelike($s->[1]), @$s[2..$#$s] ],
            type => 'runtime',
        );
    }
    return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tangerine::hook::moduleload - Process L<Module::Load> statements.

=head1 DESCRIPTION

This hook translates L<Module::Load> statements into regular C<use>
statements and re-reads them in runtime context.

This hook currently understands C<load>, C<autoload>, C<load_remote>,
and C<autoload_remote> calls.

=head1 SEE ALSO

L<Tangerine>, L<Module::Load>

=head1 AUTHOR

Petr Šabata <contyk@redhat.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015-2016 Petr Šabata

See LICENSE for licensing details.

=cut

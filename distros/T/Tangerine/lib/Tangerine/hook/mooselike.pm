package Tangerine::hook::mooselike;
$Tangerine::hook::mooselike::VERSION = '0.23';
use 5.010;
use strict;
use warnings;
use parent 'Tangerine::Hook';
use Tangerine::Hook;
use Tangerine::HookData;
use Tangerine::Utils qw(any none stripquotelike);

sub run {
    my ($self, $s) = @_;
    if ($self->type eq 'compile' && $s->[0] eq 'use' &&
        scalar(@$s) > 1 && (any { $s->[1] eq $_ }
        qw(Moose Mouse Moo Mo Role::Tiny::With))) {
        return Tangerine::HookData->new(
                hooks => [
                    Tangerine::hook::mooselike->new(type => 'runtime'),
                ],
            );
    } elsif ($self->type eq 'runtime' && any { $s->[0] eq $_ } qw(extends with)) {
        if (scalar(@$s) > 2 && none { $s->[2] eq $_ } ('=>', ',', ';')) {
            # Bail out; most likely an indirect object method call
            return
        }
        my %modules;
        my $last;
        for (my $i = 1; $i < scalar(@$s); $i++) {
            next if any { $s->[$i] eq $_ } ('=>', ',');
            last if $s->[$i] eq ';';
            $s->[$i] = substr($s->[$i], 1, -1) if substr($s->[$i], 0, 1) eq '(';
            if (substr($s->[$i], 0, 1) ne '{') {
                my @parents = stripquotelike($s->[$i]);
                $last = $parents[-1];
                $modules{$_} = undef for @parents;
            } else {
                next unless $last;
                $modules{$last} = $+{version} if
                    $s->[$i] =~ /^\{.*-version\s*?(?:=>|,)\s*?(?:(?:qq?\s*?[^\w]\s*)|'|")?v?
                        (?<version>\d+?(?:\.\d+)*)(?:(?:\s*?[^\w])|'|")?.*\}\s*$/xso;
                $last = undef;
            }
        }
        return Tangerine::HookData->new(
                modules => {
                    map {
                        ( $_ => Tangerine::Occurence->new(version => $modules{$_}) )
                        } keys %modules,
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

Tangerine::hook::mooselike - Detect Moose-like modules being loaded and
checks for C<extends> and C<with> statements

=head1 DESCRIPTION

This hook catches various Moose-like modules and watches for their
specific module-loading keywords, such as C<extends> and C<with>.

Currently this hook knows about L<Moose>, L<Mouse>, L<Moo>, L<Mo> and
L<Role::Tiny::With>.

=head1 SEE ALSO

L<Tangerine>, L<Moose>, L<Mouse>, L<Moo>, L<Mo>, L<Role::Tiny::With>

=head1 AUTHOR

Petr Šabata <contyk@redhat.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016 Petr Šabata

See LICENSE for licensing details.

=cut

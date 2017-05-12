package Tangerine::hook::xxx;
$Tangerine::hook::xxx::VERSION = '0.23';
use 5.010;
use strict;
use warnings;
use parent 'Tangerine::Hook';
use Tangerine::HookData;
use Tangerine::Occurence;
use Tangerine::Utils qw/any stripquotelike/;

sub run {
    my ($self, $s) = @_;
    if ((any { $s->[0] eq $_ } qw(use no)) &&
        scalar(@$s) > 2 && $s->[1] eq 'XXX') {
        my $module;
        if ($s->[2] eq '-dumper') {
            $module = 'Data::Dumper';
        } elsif ($s->[2] eq '-yaml') {
            $module = 'YAML';
        } elsif ($s->[2] eq '-with' && $s->[4]) {
            $module = stripquotelike($s->[4]);
        }
        return Tangerine::HookData->new( modules => {
                $module => Tangerine::Occurence->new } )
            if $module;
        }
    return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tangerine::hook::xxx - Detect L<XXX> module loading

=head1 DESCRIPTION

This hook checks what parameters are passed to L<XXX> and loads additional
modules, if applicable.

=head1 SEE ALSO

L<Tangerine>, L<XXX>

=head1 AUTHOR

Petr Šabata <contyk@redhat.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016 Petr Šabata

See LICENSE for licensing details.

=cut

package Tangerine::hook::prefixedlist;
$Tangerine::hook::prefixedlist::VERSION = '0.23';
use 5.010;
use strict;
use warnings;
use parent 'Tangerine::Hook';
use Tangerine::HookData;
use Tangerine::Occurence;
use Tangerine::Utils qw(any stripquotelike $vre);

sub run {
    my ($self, $s) = @_;
    if ((any { $s->[0] eq $_ } qw(use no)) && scalar(@$s) > 2 &&
        (any { $s->[1] eq $_ } qw(Mo POE Tk::widgets))) {
        my ($version) = $s->[2] =~ $vre;
        $version //= '';
        my $voffset = $version ? 3 : 2;
        my @args;
        if (scalar(@$s) > $voffset) {
            return if $s->[$voffset] eq ';';
            @args = @$s;
            @args = @args[($voffset) .. $#args];
            @args = stripquotelike(@args);
        }
        my $prefix;
        if ($s->[1] eq 'Tk::widgets') {
            $prefix = 'Tk'
        } else {
            $prefix = $s->[1]
        }
        return Tangerine::HookData->new(
            modules => {
                map {
                    ( $prefix.'::'.$_ => Tangerine::Occurence->new() )
                    } @args,
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

Tangerine::hook::prefixedlist - Process simple sub-module lists

=head1 DESCRIPTION

This hook catches C<use> statements with modules loading more modules
listed as their arguments.  The difference from L<Tangerine::hook::list>
is these modules use the same namespace as the module loading them.

Currently this hook knows about L<Mo> and L<POE>.

=head1 AUTHOR

Petr Šabata <contyk@redhat.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016 Petr Šabata

See LICENSE for licensing details.

=cut

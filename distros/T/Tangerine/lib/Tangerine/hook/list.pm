package Tangerine::hook::list;
$Tangerine::hook::list::VERSION = '0.23';
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
        (any { $s->[1] eq $_ }
            qw(aliased base mixin mixin::with Mojo::Base ok parent superclass
               Test::Class::Most))) {
        my ($version) = $s->[2] =~ $vre;
        $version //= '';
        my $voffset = $version ? 3 : 2;
        my @args;
        if (scalar(@$s) > $voffset) {
            return if $s->[$voffset] eq ';';
            @args = @$s;
            @args = @args[($voffset) .. $#args];
            @args = stripquotelike(@args);
            @args = grep { !/^-norequire$/ } @args
                if any { $s->[1] eq $_ } qw/parent superclass/;
            @args = grep { !/^-(base|strict)$/ } @args
                if $s->[1] eq 'Mojo::Base';
        }
        @args = $args[0]
            if $args[0] && any { $s->[1] eq $_ }
                qw/aliased mixin mixin::with Mojo::Base ok/;
        if ($s->[1] eq 'Test::Class::Most') {
            my $tcmparent;
            my @results;
            for my $arg (@args) {
                if ($tcmparent) {
                    if (any { $arg eq $_ } qw/attributes is_abstract/) {
                        undef $tcmparent;
                        next
                    }
                    push @results, $arg
                } else {
                    if ($arg eq 'parent') {
                        $tcmparent++;
                        undef @results
                    }
                }
            }
            @args = @results
        }
        my %found;
        for (my $i = 0; $i < scalar(@args); $i++) {
            $found{$args[$i]} = '';
            if ($args[$i+1] && $args[$i+1] =~ /^v?\d+(?:\.\d+)*$/) {
                $found{$args[$i]} = $args[$i+1];
                $i++
            }
        }
        return Tangerine::HookData->new(
            modules => {
                map {
                    ( $_ => Tangerine::Occurence->new(version => $found{$_}) )
                    } keys %found,
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

Tangerine::hook::list - Process simple module lists

=head1 DESCRIPTION

This hook catches C<use> statements with modules loading more modules
listed as their arguments.

Currently this hook knows about L<aliased>, L<base>, L<mixin>, L<mixin::with>,
L<Mojo::Base>, L<Test::use::ok>, L<parent>, L<superclass> and
L<Test::Class::Most>.

=head1 SEE ALSO

L<Tangerine>, L<aliased>, L<base>, L<mixin>, L<mixin::with>, L<Mojo::Base>,
L<Test::use::ok>, L<parent>, L<superclass>, L<Test::Class::Most>

=head1 AUTHOR

Petr Šabata <contyk@redhat.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016 Petr Šabata

See LICENSE for licensing details.

=cut

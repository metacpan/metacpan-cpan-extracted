package Tangerine::hook::moduleruntime;
$Tangerine::hook::moduleruntime::VERSION = '0.23';
use 5.010;
use strict;
use warnings;
use parent 'Tangerine::Hook';
use Tangerine::HookData;
use Tangerine::Occurence;
use Tangerine::Utils qw(any none stripquotelike);

sub run {
    my ($self, $s) = @_;
    my @routines = qw(require_module use_module use_package_optimistically);
    if ((any { $s->[0] eq $_ } qw(use no)) && scalar(@$s) > 1 &&
        $s->[1] eq 'Module::Runtime') {
        return Tangerine::HookData->new( hooks => [
                Tangerine::hook::moduleruntime->new(type => 'runtime') ] );
    }
    # NOTE: For the sake of simplicity, we only check for one subroutine
    #       call per statement.
    if ($self->type eq 'runtime' && any { my $f = $_; any { $_ eq $f } @$s }
        @routines) {
        while (none { $s->[0] eq $_ } @routines) {
            shift @$s;
        }
        for (my $clip = 0; $clip <= $#$s && $clip < 3; $clip++) {
            if (any { $s->[$clip] eq $_ } qw(-> ;)) {
                @$s = @$s[0..$clip-1];
                last
            }
        }
        my @args = stripquotelike(@$s[1..$#$s]);
        return Tangerine::HookData->new(
            modules => {
                    $args[0] => Tangerine::Occurence->new(
                        version => $args[1]
                    ),
                },
            );
    }
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tangerine::hook::moduleruntime - Process runtime module loading functions.

=head1 DESCRIPTION

This hook parses L<Module::Runtime> module loading functions -
C<require_module>, C<use_module> and C<use_package_optimistically>.

=head1 SEE ALSO

L<Module::Runtime>

=head1 AUTHOR

Petr Šabata <contyk@redhat.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015-2016 Petr Šabata

See LICENSE for licensing details.

=cut

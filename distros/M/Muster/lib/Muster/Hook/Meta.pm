package Muster::Hook::Meta;
$Muster::Hook::Meta::VERSION = '0.62';
use Mojo::Base 'Muster::Hook::Directives';
use Muster::LeafFile;
use Muster::Hooks;

use Carp 'croak';

=head1 NAME

Muster::Hook::Meta - Muster meta directive

=head1 VERSION

version 0.62

=head1 DESCRIPTION

L<Muster::Hook::Meta> processes the meta directive.

=head1 METHODS

L<Muster::Hook::Meta> inherits all methods from L<Muster::Hook::Directives>.

=head2 register

Do some intialization.

=cut
sub register {
    my $self = shift;
    my $hookmaster = shift;
    my $conf = shift;

    my $callback = sub {
        my %args = @_;

        my $leaf = $args{leaf};
        my $phase = $args{phase};
        my @p = @{$args{params}};
        my %params = @p;

        if ($phase eq $Muster::Hooks::PHASE_SCAN)
        {
            foreach my $key (keys %params)
            {
                $leaf->{meta}->{$key} = $params{$key};
            }
        }
        return "";
    };
    $hookmaster->add_hook('meta' => sub {
            my %args = @_;

            return $self->do_directives(
                no_scan=>0,
                directive=>'meta',
                call=>$callback,
                %args,
            );
        },
    );
    return $self;
} # register

1;

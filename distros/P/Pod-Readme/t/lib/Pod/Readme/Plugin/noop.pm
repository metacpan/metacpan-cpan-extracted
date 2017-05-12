package Pod::Readme::Plugin::noop;

use Moo::Role;
use Types::Standard qw/ Bool Str /;

=head1 NAME

Pod::Readme::Plugin::noop - do nothing

=head1 SYNOPSIS

  =pod

  =for readme plugin noop

=head1 DESCRIPTION

This is a no-op plugin.

=cut

requires 'parse_cmd_args';

has noop_bool => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    default => 0,
);

has noop_str => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => '',
);

sub cmd_noop {
    my ( $self, @args ) = @_;

    my $res = $self->parse_cmd_args( [qw/ bool str /], @args );
    foreach my $key ( keys %{$res} ) {
        if ( my $method = $self->can("noop_${key}") ) {
            $self->$method( $res->{$key} );
        }
        else {
            die "Invalid key: '${key}'";
        }
    }
}

use namespace::autoclean;

1;

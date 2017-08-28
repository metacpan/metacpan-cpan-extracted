package Pcore::WebDriver::Window;

use Pcore -class;
use overload    #
  q[bool] => sub {
    return 1;
  },
  q[0+] => sub {
    return $_[0]->{id};
  },
  q[""] => sub {
    return $_[0]->{id};
  },
  q[<=>] => sub {
    return !$_[2] ? $_[0]->{id} <=> $_[1] : $_[1] <=> $_[0]->{id};
  },
  fallback => undef;

has wds => ( is => 'ro', isa => InstanceOf ['Pcore::WebDriver::Session'], required => 1 );
has id => ( is => 'ro', isa => Str, required => 1 );

has is_closed => ( is => 'ro', isa => Bool, default => 0, init_arg => undef );

sub TO_DATA ($self) {
    return $self->{id};
}

sub close ( $self, $cb = undef ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms NamingConventions::ProhibitAmbiguousNames]
    $self->{wds}->push_cmd(
        'switch_win',
        $self,
        sub ( $wds, $stat ) {
            if ( !$stat ) {
                $cb->( $wds, $stat ) if $cb;
            }
            else {
                $wds->unshift_cmd(
                    'close_win',
                    sub ( $wds, $stat ) {
                        $self->{is_closed} = 1 if $stat;

                        $cb->( $wds, $stat ) if $cb;

                        return;
                    }
                );
            }

            return;
        }
    );

    return;
}

sub switch ( $self, $cb = undef ) {
    $self->{wds}->push_cmd( 'switch_win', $self, $cb );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::WebDriver::Window

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut

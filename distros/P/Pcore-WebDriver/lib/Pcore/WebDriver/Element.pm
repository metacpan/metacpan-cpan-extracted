package Pcore::WebDriver::Element;

use Pcore -class;
use Pcore::WebDriver qw[:CONST];
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

sub TO_DATA ($self) {
    return $self->{id};
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::WebDriver::Element

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut

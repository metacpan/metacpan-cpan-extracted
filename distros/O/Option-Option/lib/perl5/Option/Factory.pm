package Option::Factory;

=pod

=head1 NAME

Option::Factory

=head1 SYNOPSIS

Generates new objects that encode Option::Option objects

    use Option::Factory;

    my $opts = Option::Factory->new();

=head1 AUTHOR

Lee Katz

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw/confess croak/;
use Exporter qw/import/;
use File::Basename qw/dirname/;
  #use FindBin;
  #use lib dirname($INC{"Option/Factory.pm"})."..";
  #use Option::Option;


our $VERSION = $Option::Option::VERSION;

=pod

=over

=item new()

Creates a new factory

=cut

sub new{
  my($class) = @_;

  my $self = {
  };

  bless($self, $class);

  return $self;
}

=pod

=item scalar()

returns a scalar with a value

=back

=cut

sub scalar{
  my($self, $var) = @_;

  my $opt = Option::Option->new($var);

  return $opt;
}

sub hash{
  ...;
}
sub array{
  ...;
}

1;


package QWizard::Storage::Memory;

use strict;
use QWizard::Storage::Base;

our @ISA = qw(QWizard::Storage::Base);

our $VERSION = '3.15';

sub new {
    my $class = shift;
    bless {}, $class;
}

sub get_all {
    my $self = shift;
    return $self->{'vars'};
}

sub set {
    my ($self, $it, $value) = @_;
    $self->{'vars'}{$it} = $value;
    return $value;
}

# faster than the parent iterative method
sub set_all {
    my $self = shift;
    %{$self->{'vars'}} = %{$_[0]};
}

sub get {
    my ($self, $it, $value) = @_;
    return $self->{'vars'}{$it};
}

sub reset {
    my $self = shift;
    %{$self->{'vars'}} = ();
}

1;

=pod

=head1 NAME

QWizard::Storage::Memory - Stores data in CGI variables

=head1 SYNOPSIS

  my $st = new QWizard::Storage::Memory();
  $st->set('var', 'value');
  $st->get('var');

=head1 DESCRIPTION

Stores data passed to it inside of CGI parameters.

=head1 AUTHOR

Wes Hardaker, hardaker@users.sourceforge.net

=head1 SEE ALSO

perl(1)

Net-Policy: http://net-policy.sourceforge.net/

=cut

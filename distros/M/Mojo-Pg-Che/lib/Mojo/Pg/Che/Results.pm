package Mojo::Pg::Che::Results;

use Mojo::Base 'Mojo::Pg::Results';

my $PKG = __PACKAGE__;

sub fetchcol_arrayref {
  my $self = shift;
  my ($columns, $maxrows) = @_;
  $columns ||= [0];
  map $columns->[$_]--, 0..$#$columns;
  [map @$_, @{$self->sth->fetchall_arrayref($columns, $maxrows)}];
}

sub do {
  my $self = shift;
  my $rows = $self->sth->rows;
  ($rows == -1) ? "0E0" : $rows; # always return true if no error
}

my @STH_METHODS = qw(
fetchrow_arrayref
fetchrow_array
fetchrow_hashref
fetchall_arrayref
fetchall_hashref
);

for my $method (@STH_METHODS) {
  no strict 'refs';
  no warnings 'redefine';
  *{"${PKG}::$method"} = sub {
    my $self = shift;
    my $sth = $self->sth;
    return $sth->$method(@_);
  };
  
}

#~ our $AUTOLOAD;
#~ sub  AUTOLOAD {
  #~ my ($method) = $AUTOLOAD =~ /([^:]+)$/;
  #~ my $self = shift;
  #~ my $sth = $self->sth;
  
  #~ if ($sth->can($method) && scalar grep $_ eq $method, @STH_METHODS) {
    #~ return $sth->$method(@_);
  #~ }
  
  #~ die sprintf qq{Can't locate autoloaded object method "%s" (%s) via package "%s" at %s line %s.\n}, $method, $AUTOLOAD, ref $self, (caller)[1,2];
  
#~ }

1;
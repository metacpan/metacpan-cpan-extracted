# Object to handle data communication between domain logic and presentation
# it will stash the input in a hash that the presentation can retrieve

package RWDE::Web::Helper;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 509 $ =~ /(\d+)/;

sub new {
  my ($proto, $params) = @_;

  my $class = ref($proto) || $proto;

  my $self = { _STASH => {}, };

  bless $self, $class;

  return $self;
}

=pod

=head2 FIELDNAME($field[,$value])

All field names of the record are accessible via the field name.  If a
second parameter is provided, that value is stored as the data,
otherwise the existing value if any is returned.  Throws an 'undef'
exception on error.  It is intended to be called by an F<AUTOLOAD()>
method from the subclass.

Example:

 $rec->owner_email('new@add.ress');
 $rec->user_addr2(undef);
 print $rec->user_fname();

Would be converted by F<AUTOLOAD()> in the subclass to calls like

 $rec->FIELDNAME('owner_email','new@add.ress');

and so forth.

=cut

sub FIELDNAME {
  my $self = shift;
  my $name = shift;

  $name =~ s/.*://;    # strip fully-qualified portion

  unless (exists $self->{_STASH}->{$name}) {
    my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
    my $info = " for $package=>$subroutine";

    throw RWDE::DevelException({ info => "Sorry, RWDE::Web::Helper does not have '$name' in class $self $info" });
  }

  return $self->{_STASH}->{$name};
}

use vars qw($AUTOLOAD);

sub AUTOLOAD {
  my ($self, @args) = @_;
  if (not ref $self) {
    my ($package, $filename, $line) = caller();
    throw RWDE::DevelException(
      { info => "Record::AUTOLOAD invoked with the fieldname: $AUTOLOAD; probably static access to an undefined field/method from $filename Line: $line " . join(':', @args) . "\n" });
  }

  return $self->FIELDNAME($AUTOLOAD, @args);
}

# do nothing.  here just to shut up TT when AUTOLOAD is present
sub DESTROY {

}

sub get_stash {
  my ($self, $params) = @_;
  return $self->{_STASH};
}

sub get_session {
  my ($self, $params) = @_;
  return $self->{_STASH}->{s};
}

sub get_req {
  my ($self, $params) = @_;
  return $self->{_STASH}->{req};
}

sub get_uri {
  my ($self, $params) = @_;
  return $self->{_STASH}->{uri};
}

sub get_pagetype {
  my ($self, $params) = @_;

  $self->{_STASH}->{uri} =~  m/\.(\w+)$/;

  return $1;
}

sub get_formdata {
  my ($self, $params) = @_;
  return $self->{_STASH}->{formdata};
}

sub set_stash {
  my ($self, $params) = @_;
  foreach my $key (keys %{$params}) {
    $self->{_STASH}->{$key} = $$params{$key};
  }

  return ();
}

1;

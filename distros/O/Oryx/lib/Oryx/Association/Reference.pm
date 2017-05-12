package Oryx::Association::Reference;

use base qw(Oryx::Association);

sub new {
    my ($class, $proto) = @_;
    return bless $proto, $class;
}

#=============================================================================
# TIE MAGIC
sub id { $_[0]->{oid} }

# meta in this case is a reference to the owning Association instance
sub TIESCALAR {
    my $class = shift;
    my ($meta, $idOrObject) = @_;

    my $self = bless {
        meta    => $meta,
        oid     => ref($idOrObject) ? $idOrObject->{id} : $idOrObject,
        changed => 0,
    }, $class;

    eval "use ".$meta->class; $self->_croak($@) if $@;
    return $self;
}

sub STORE {
    my ($self, $object) = @_;
    return unless defined $object;
    if (ref($object)) {
	$self->{oid} = $object->id;
    } else {
	$self->{oid} = $object;
    }
    $self->{changed}++;
    $self->{TARGET} = $object;
}

sub FETCH {
    my $self = shift;
    if (defined $self->{oid}) {
	unless (defined $self->{TARGET}) {
	    $self->{TARGET} = $self->{meta}->class->retrieve($self->{oid});
	}
    } else {
	return undef;
    }
    $self->{TARGET};
}

sub changed {$_[0]->{changed} = $_[1] if $_[1]; $_[0]->{changed}}

1;
__END__

=head1 NAME

Oryx::Association::Reference - Abstract base class for reference associations

=head1 SYNOPSIS

  package CMS::Document;

  use base qw( Oryx::Class );

  our $schema = {
      associations => [ {
          role  => 'author',
          type  => 'Reference',
          class => 'CMS::Person',
      } ],
  };

  $x = CMS::Person->create({ name => 'Richard Hundt' });
  $y = CMS::Document->create({});
  $y->author($x);
  $y->update;
  $y->commit;

=head1 DESCRIPTION

Provides the structure for linking two Oryx classes together using a simple references.

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut

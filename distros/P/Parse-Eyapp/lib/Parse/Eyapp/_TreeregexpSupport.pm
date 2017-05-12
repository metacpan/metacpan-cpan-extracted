# (c) Parse::Eyapp Copyright 2006-2008 Casiano Rodriguez-Leon, all rights reserved.
package Parse::Eyapp::_TreeregexpSupport;
use strict;
use Carp;
use Parse::Eyapp::Node;
use base qw (Exporter);
our @EXPORT_OK = qw(until_first_match checknumchildren);

################### Support routines #########################

# used whith array patterns
# index of the children to start
# $b recognizer treereg
# $r reference to an array where children that don't match are pushed
sub until_first_match {
  my ($father, $order, $b, $r) = @_;

  return undef unless UNIVERSAL::can($father, 'children');
  for ($order..0+$father->children()) {
    my $t = $father->child($_);
    return $t if ($b->($t));
    push @$r, $t;
  }
  return undef;
}

sub checknumchildren {
  my ($self, $numexpected, $line, $filename, $there_are_lists, $severity) = @_;
 
	my $numchildren = $self->children;
  return 1 if ($numchildren == $numexpected) or ($there_are_lists and $numchildren >= $numexpected);

  return 0 unless ($severity > 1);
  my $class = ref($self);
  my $clause = $there_are_lists? ' at least' : '';
	my $warnmessage =<<"END_OF_WARN_MESSAGE";
found node $class with $numchildren children.
Expected$clause $numexpected children (see line $line of $filename)"
END_OF_WARN_MESSAGE
  croak "Error! $warnmessage" if $severity > 2;
	warn "Warning! $warnmessage";

  return 0;
}

1;


__END__




# Copyright 1999-2001 Gabor Herr. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself

# Modified 29dec2000 by Jean-Louis Leroy
# replaced save() by get_exporter()
# fixed reschema(): $def->{dumper} was not set when using abbreviated forms

use strict;

use Tangram::Type::Scalar;

package Tangram::Type::Dump::Perl;

use Tangram::Type::Dump qw(flatten unflatten);

use vars qw(@ISA);
 @ISA = qw( Tangram::Type::String );
use Data::Dumper;
use Set::Object qw(reftype);

$Tangram::Schema::TYPES{perl_dump} = Tangram::Type::Dump::Perl->new;

my $DumpMeth = (defined &Data::Dumper::Dumpxs) ? 'Dumpxs' : 'Dump';

sub reschema {
  my ($self, $members, $class, $schema) = @_;

  if (ref($members) eq 'ARRAY') {
    # XXX - not tested by test suite
    # short form
    # transform into hash: { fieldname => { col => fieldname }, ... }
    $_[1] = map { $_ => { col => $schema->{normalize}->($_, 'colname') } } @$members;
  }
    
  for my $field (keys %$members) {
    my $def = $members->{$field};
    my $refdef = reftype($def);
    
    unless ($refdef) {
      # not a reference: field => field
      $def = $members->{$field} = { col => $schema->{normalize}->(($def || $field), 'colname') };
	  $refdef = reftype($def);
    }

    die ref($self), ": $class\:\:$field: unexpected $refdef"
      unless $refdef eq 'HASH';
	
    $def->{col} ||= $schema->{normalize}->($field, 'colname');
    $def->{sql} ||= 'VARCHAR(255)';
    $def->{indent} ||= 0;
    $def->{terse} ||= 1;
    $def->{purity} ||= 0;
    $def->{dumper} ||= sub {
      local($Data::Dumper::Indent) = $def->{indent};
      local($Data::Dumper::Terse)  = $def->{terse};
      local($Data::Dumper::Purity) = $def->{purity};
      local($Data::Dumper::Useqq) = 1;
      local($Data::Dumper::Varname) = '_t::v';
      Data::Dumper->$DumpMeth([@_], []);
    };
  }

  return keys %$members;
}

sub get_importer
{
	my ($self, $context) = @_;
	return("\$obj->{$self->{name}} = eval shift \@\$row;"
	       ."Tangram::Type::Dump::unflatten(\$context->{storage}, "
	       ."\$obj->{$self->{name}})");
  }

sub get_exporter
  {
	my ($self, $context) = @_;
	my $field = $self->{name};

	return sub {
	  my ($obj, $context) = @_;
	  flatten($context->{storage}, $obj->{$field});
	  my $text = $self->{dumper}->($obj->{$field});
	  unflatten($context->{storage}, $obj->{$field});
	  return $text;
	};
  }

# XXX - not tested by test suite
sub save {
  my ($self, $cols, $vals, $obj, $members, $storage) = @_;
  
  my $dbh = $storage->{db};
  
  foreach my $member (keys %$members) {
    my $memdef = $members->{$member};
    
    next if $memdef->{automatic};
    
    push @$cols, $memdef->{col};
    Tangram::Type::Dump::flatten($storage, $obj->{$member});
    push @$vals, $dbh->quote(&{$memdef->{dumper}}($obj->{$member}));
    Tangram::Type::Dump::unflatten($storage, $obj->{$member});
  }
}

1;

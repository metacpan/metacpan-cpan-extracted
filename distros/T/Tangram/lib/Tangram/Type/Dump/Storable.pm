
# (c) Sam Vilain, 2004.  All Rights Reserved.
# This program is free software; you may use it and/or distribute it
# under the same terms as Perl itself.

package Tangram::Type::Dump::Storable;

use strict;

use Tangram::Type::Scalar;
use Tangram::Type::Dump qw(flatten unflatten);

use Storable qw(freeze thaw);

use Set::Object qw(reftype);

use vars qw(@ISA);
 @ISA = qw( Tangram::Type::String );

$Tangram::Schema::TYPES{storable} = __PACKAGE__->new;

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
    $def->{sql} ||= 'BLOB';
    $def->{deparse} ||= 0;
    $def->{dumper} ||= sub {
	local($Storable::Deparse) = $def->{deparse};
	my $ent = [@_];
	my $dumped = freeze($ent);
	$Data::Dumper::Purity = 1;
	$Data::Dumper::Useqq = 1;
	#print STDERR "Dumped: ".Data::Dumper::Dumper($ent, $dumped);
	$dumped;
    };
  }

  return keys %$members;
}

sub get_importer
{
	my ($self, $context) = @_;
	return("
my \$data = shift \@\$row;
print \$Tangram::TRACE \"THAWING (length = \".(length(\$data)).\":\".Data::Dumper::Dumper(\$data)
   if \$Tangram::TRACE and \$Tangram::DEBUG_LEVEL > 2;
my \$ref = Storable::thaw(\$context->{storage}->from_dbms('blob', \$data)) or die \"thaw failed on data (\".(length(\$data)).\") = \".Data::Dumper::Dumper(\$data);
\$obj->{$self->{name}} = \$ref->[0];\n"
	       ."Tangram::Type::Dump::unflatten(\$context->{storage}, "
	       ."\$obj->{$self->{name}});\n");
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
	  return $context->{storage}->to_dbms('blob', $text);
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
    flatten($storage, $obj->{$member});
    push @$vals, $dbh->quote(&{$memdef->{dumper}}($obj->{$member}));
    unflatten($storage, $obj->{$member});
  }
}

1;

# SystemC - SystemC Perl Interface
# See copyright, etc in below POD section.
######################################################################

package SystemC::Coverage::Item;
use Carp;

use SystemC::Coverage::ItemKey;
use strict;
use vars qw($VERSION $Debug $AUTOLOAD);

######################################################################
#### Configuration Section

$VERSION = '1.344';

######################################################################
######################################################################
######################################################################
#### Creation

sub new {
    my $class = shift;
    my $self = [shift, shift];  # Key and count value
    return bless $self, $class;
}

sub DESTROY {}

sub _dehash {
    # Convert a hash to a pair of elements suitable for new()
    my @args = @_;

    my $count = 0;
    my %keys;
    for (my $i=0; $i<=$#args; $i+=2) {
	my $key = $args[$i];
	my $val = $args[$i+1];
	if ($key eq "c" || $key eq "count") {
	    $count = $val;
	    next;
	}
	# Compress keys
	$key = $SystemC::Coverage::ItemKey::CompressKey{$key} || $key;
	$keys{$key} = $val;
    }

    my $string = "";
    foreach my $key (sort (keys %keys)) {
	my $val = $keys{$key};
	$string .= "\001".$key."\002".$val;
	#print "Set $key $val\n" if $Debug;
    }
    #print "RR $string $count\n" if $Debug;
    return ($string, $count);
}

######################################################################
#### Special accessors

sub count {
    return $_[0]->[1];
}

sub key {
    # Sort key
    return $_[0]->[0];
}

sub hash {
    # Return hash of all keys and values
    my %hash;
    while ($_[0]->[0] =~ /\001([^\002]+)\002([^\001]*)/g) {
	my $key=$SystemC::Coverage::ItemKey::DecompressKey{$1}||$1;
	$hash{$key}=$2;
    }
    return \%hash;
}

######################################################################
#### Special methods

sub count_inc {
    $_[0]->[1] += $_[1];
}

sub write_string {
    my $self = shift;
    my $str = "inc(";
    my $comma = "";
    while ($self->[0] =~ /\001([^\002]+)\002([^\001]*)/g) {
	my $key = $1;
	my $val = $2;
	$key = "'".$key."'" if length($key)!=1;
	$str .= "${comma}${key}=>'$val'";
	$comma = ",";
    }
    $str .= $comma."c=>".$self->count;
    $str .= ");";
    return $str;
}

######################################################################
#### Normal accessors

# This makes functions that look like:
sub AUTOLOAD {
    my $func = $AUTOLOAD;
    if ($func =~ s/^SystemC::Coverage::Item:://) {
	my $key = $SystemC::Coverage::ItemKey::CompressKey{$func}||$func;
	my $def = SystemC::Coverage::ItemKey::default_value($func);
	if (!defined $def) { $def = 'undef'; }
	elsif ($def =~ /^\d+$/) { $def = $def; }
	else { $def = "'$def'"; }
	my $f = ("package SystemC::Coverage::Item;"
		 ."sub $func {"
		 ."  if (\$_[0]->[0] =~ /\\001${key}\\002([^\\001]*)/) {"
		 ."    return \$1;"
		 ."  } else {"
		 ."    return ".$def.";"
		 ."  }"
		 ."}; 1;");
	#print "DEF $func $f\n";
	eval $f or die;
	goto &$AUTOLOAD;
    } else {
	croak "Undefined SystemC::Coverage::Item subroutine $func called,";
    }
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Coverage::Item - Coverage analysis item

=head1 SYNOPSIS

  use SystemC::Coverage;

  $Coverage = new SystemC::Coverage;
  foreach my $item ($Coverage->items()) {
      print $item->count;
  }

=head1 DESCRIPTION

SystemC::Coverage::Item provides data on a single coverage point.

=head1 METHODS

=over 4

=item count_inc (inc)

Increment the item's count by the specified value.

=item hash

Return a reference to a hash of key/value pairs.

=item key

Return a key suitable for sorting.

=back

=head1 ACCESSORS

=over 4

=item col[0-9]

The (enumeration) value name for this column in a table cross.

=item col[0-9]_name

The column title for the header line of this column.

=item column

Column number for the item.  Used to disambiguate multiple coverage points
on the same line number.

=item comment

Textual description for the item.

=item count

The numerical count for this point.

=item filename

Filename of the item.

=item groupdesc

Description of the covergroup this item belongs to.

=item groupname

Group name of the covergroup this item belongs to.

=item hier

Hierarchy path name for the item.

=item lineno

Line number for the item.

=item per_instance

True if every hierarchy is independently counted; otherwise all hierarchies
will be combined into a single count.

=item row[0-9]

The (enumeration) value name for this row in a table cross.

=item row[0-9]_name

The row title for the header line of this row.

=item table

The name of the table for automatically generated tables.

=item type

Type of coverage (block, line, fsm, etc.)

=back

=head1 DISTRIBUTION

SystemPerl is part of the L<http://www.veripool.org/> free SystemC software
tool suite.  The latest version is available from CPAN and from
L<http://www.veripool.org/systemperl>.

Copyright 2001-2014 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License
Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<SystemC::Manual>

L<SystemC::Coverage>

=cut

######################################################################

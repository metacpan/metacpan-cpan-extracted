# SystemC - SystemC Perl Interface
# See copyright, etc in below POD section.
######################################################################

package SystemC::Coverage::ItemKey;
use Carp;

use strict;
use vars qw($VERSION %CompressKey %DecompressKey %GroupKey);

######################################################################
#### Configuration Section

$VERSION = '1.344';

our %_Keys =
    (
     # Group attributes
     "col0_name" => { compressed=>"C0", group=>1, default=>undef, },
     "col1_name" => { compressed=>"C1", group=>1, default=>undef, },
     "col2_name" => { compressed=>"C2", group=>1, default=>undef, },
     "col3_name" => { compressed=>"C3", group=>1, default=>undef, },
     "column"	 => { compressed=>"n",	group=>1, default=>0, },
     "filename"	 => { compressed=>"f",	group=>1, default=>undef, },
     "groupdesc" => { compressed=>"d",	group=>1, default=>"", },
     "groupname" => { compressed=>"g",	group=>1, default=>"", },
     "groupcmt"	 => { compressed=>"O",	group=>1, default=>"", },
     "per_instance"=>{compressed=>"P",	group=>1, default=>0,	},
     "row0_name" => { compressed=>"R0", group=>1, default=>undef, },
     "row1_name" => { compressed=>"R1", group=>1, default=>undef, },
     "row2_name" => { compressed=>"R2", group=>1, default=>undef, },
     "row3_name" => { compressed=>"R3", group=>1, default=>undef, },
     "table"	 => { compressed=>"T",	group=>1, default=>undef, },
     "thresh"	 => { compressed=>"s",	group=>1, default=>undef, },
     "type"	 => { compressed=>"t",	group=>1, default=>"", },
     # Bin attributes
     "col0"	 => { compressed=>"c0", group=>0, default=>undef, },
     "col1"	 => { compressed=>"c1", group=>0, default=>undef, },
     "col2"	 => { compressed=>"c2", group=>0, default=>undef, },
     "col3"	 => { compressed=>"c3", group=>0, default=>undef, },
     "comment"	 => { compressed=>"o",	group=>0, default=>"", },
     "hier"	 => { compressed=>"h",	group=>0, default=>"", },
     "limit"	 => { compressed=>"L",	group=>0, default=>undef, },
     "lineno"	 => { compressed=>"l",	group=>0, default=>0,	},
     "row0"	 => { compressed=>"r0", group=>0, default=>undef, },
     "row1"	 => { compressed=>"r1", group=>0, default=>undef, },
     "row2"	 => { compressed=>"r2", group=>0, default=>undef, },
     "row3"	 => { compressed=>"r3", group=>0, default=>undef, },
     "weight"	 => { compressed=>"w",	group=>0, default=>undef, },
     # Count
     "count"	 => { compressed=>"c",	group=>0, default=>0, },
     );

while (my ($key, $val) = each %_Keys) { $_Keys{$key}{name} = $key; }
foreach (values %_Keys) {
    $DecompressKey{$_->{compressed}} = $_->{name};
    $CompressKey{$_->{name}} = $_->{compressed}||$_->{name};
    $GroupKey{$_->{name}} = $GroupKey{$_->{compressed}} = 1 if $_->{group};
}

######################################################################
######################################################################
######################################################################
#### Accessors

sub default_value {
    my $key = shift;
    my $self = $_Keys{$key};
    return undef if !$self;
    return $self->{default};
}

######################################################################
######################################################################
#### Methods

sub _lint_code {
    my %comp;
    my $ok = 1;
    foreach my $keyref (values %_Keys) {
	if ($comp{$keyref->{compressed}}) {
	    warn "%Error: Duplicate compress code: $keyref->{compressed},";
	    $ok = 0;
	}
	$comp{$keyref->{compressed}} = 1;
    }
    return $ok;
}

sub _edit_code {
    my $filename = shift;
    my $checkonly = shift;
    # Used for generating the SystemPerl package itself

    my $fh = IO::File->new("<$filename") or die "%Error: $! $filename\n";

    my @in;
    my @out;
    my $deleting;
    my $hit;
    while (defined(my $line = $fh->getline)) {
	push @in, $line;
	if ($line =~ /AUTO_EDIT_BEGIN_SystemC::Coverage::ItemKey/) {
	    $deleting = 1;
	    push @out, $line;
	    $hit = 1;
	    foreach my $keyref (sort {$a->{name} cmp $b->{name}} values %_Keys) {
		push @out, sprintf("\tif (key == \"%s\") return \"%s\";\n",
				   $keyref->{name}, $keyref->{compressed});
	    }
	    foreach my $keyref (sort {$a->{name} cmp $b->{name}} values %_Keys) {
		push @out, sprintf("#define SP_CIK_%s \"%s\"\n",
				   uc $keyref->{name}, $keyref->{compressed});
	    }
	}
	elsif ($line =~ /AUTO_EDIT_END_SystemC::Coverage::ItemKey/) {
	    $deleting = 0;
	    push @out, $line;
	}
	elsif ($deleting) {
	}
	else {
	    push @out, $line;
	}
    }
    $fh->close;

    my $ok = join("", @out) eq join("", @in);
    if (!$ok && !$checkonly) {
	my $fh = IO::File->new(">$filename") or die "%Error: $! writing $filename\n";
	$fh->print(join "", @out);
	$fh->close;
    }

    return _lint_code() && $ok;
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Coverage::ItemKey - Coverage analysis item key values

=head1 SYNOPSIS

  use SystemC::Coverage::ItemKey;
  # $SystemC::Coverage::Item::CompressKey{...}
  # $SystemC::Coverage::Item::DecompressKey{...}

=head1 DESCRIPTION

SystemC::Coverage::ItemKey provides details on each datum key that is
attached to each coverage item.  This is a low level class used by
SystemC::Coverage::Item; direct usage is unlikely to be desirable.

=head1 METHODS

=over 4

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

L<SystemC::Coverage::Item>

=cut

######################################################################

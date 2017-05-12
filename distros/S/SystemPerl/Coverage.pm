# See copyright, etc in below POD section.
######################################################################

package SystemC::Coverage;
use IO::File;
use Carp;

require Exporter;
@ISA = ('Exporter');
@EXPORT = qw( inc );

use strict;
use SystemC::Coverage::Item;
use vars qw($VERSION $Debug);

use vars qw($_Default_Self);

######################################################################
#### Configuration Section

$VERSION = '1.344';

use constant DEFAULT_FILENAME => 'logs/coverage.pl';

######################################################################
######################################################################
######################################################################
#### Creation

sub new {
    my $class = shift;
    my $self = {
	filename => DEFAULT_FILENAME,
	strings => {},  # value/key = id#
	coverage => {},	# {coverage_key}=count
	filedata => {},	# {filename} = {counts => {line}=count, needed},
    };
    bless $self, $class;
    $_Default_Self = $self;
    $self->clear();
    return $self;
}

######################################################################
#### Reading

sub read {
    my $self = shift;
    my %params = ( filename => $self->{filename},
		   @_
		   );
    $_Default_Self = $self;
    # Read in the coverage file

    print "SystemC::Coverage::read $params{filename}\n" if $Debug;
    $params{filename} or croak "%Error: Undefined filename,";

    my $fh = IO::File->new("<$params{filename}") or croak "%Error: $! $params{filename},";
    my $fmt = $fh->getline;
    if ($fmt =~ /Mode:perl/) {
	$! = $@ = undef;
	my $rtn = do $params{filename};
	(!$@) or die "%Error: $params{filename}: $@,";
	(!$!) or die "%Error: $params{filename}: $!,";
    } elsif ($fmt =~ /SystemC::Coverage-3\b/) {
	my $cref = $self->{coverage};
	while (defined(my $line = $fh->getline)) {
	    if ($line =~ /^C\s+'([^']*)'\s+(\d+)$/) { #')
		$cref->{$1} += $2;
	    }
	}
    } else {
	croak "%Error: $params{filename}: Unknown Coverage format,";
    }
    $fh->close;
}

######################################################################
#### Saving

sub write {
    my $self = shift;
    my %params = ( filename => $self->{filename},
		   binary => 1,	# Which format type
		   edit_key_cb => undef,	# Edit callback routine
		   @_
		   );
    # Write out the coverage array
    # Use a temp file, so it's less likely a abort in the middle of writing will trash data.

    $params{filename} or croak "%Error: Undefined filename,";
    my $tempfilename = $params{filename}.".tmp";
    unlink $tempfilename;
    my $fh = IO::File->new(">$tempfilename") or croak "%Error: $! writing $tempfilename,";

    if ($params{binary}) {
	print $fh "# SystemC::Coverage-3\n";
	# Format choices and % speedup
	#	100%	Below perl code, ~0.368851
	#	551%	Require raw $c->{#}, then rehash into {coverage}
	#	629%	Require Dumper hash, then rehash into {coverage}
	#	660%	Storable, then rehash into {coverage}
	#	696%	Read file
	foreach my $key (sort keys %{$self->{coverage}}) {
	    my $nkey = $key;
	    my $value = $self->{coverage}{$key};
	    if ($params{edit_key_cb}) {
		$nkey = &{$params{edit_key_cb}}($nkey);
	    }
	    printf $fh "C '%s' %d\n", $nkey, $value;
	}
    } else {
	print $fh "# SystemC::Coverage-2 -*- Mode:perl -*-\n";
	foreach my $key (sort keys %{$self->{coverage}}) {
	    my $nkey = $key;
	    if ($params{edit_key_cb}) {
		$nkey = &{$params{edit_key_cb}}($nkey);
	    }
	    my $item = SystemC::Coverage::Item->new($nkey, $self->{coverage}{$key});
	    printf $fh $item->write_string."\n";
	}
	printf $fh "\n1;\n";	# So eval will succeed
    }
    $fh->close();

    rename $tempfilename, $params{filename};
}

######################################################################
#### Incrementing utilities

sub inc {
    my $self = (ref $_[0] ? shift : $_Default_Self);
    my ($string,$count) = SystemC::Coverage::Item::_dehash(@_);
    $self->{coverage}{$string} += $count;
}

######################################################################
#### Clearing

sub clear {
    my $self = shift;
    # Clear the coverage array
    $self->{strings} = {};
    $self->{coverage} = {};
    $self->{filedata} = {};
}

######################################################################
#### Accessors

sub items {
    my $self = shift;
    my @items;
    foreach my $key (keys %{$self->{coverage}}) {
	my $item = SystemC::Coverage::Item->new($key, $self->{coverage}{$key});
	push @items, $item;
    }
    return @items;
}

sub items_sorted {
    my $self = shift;
    return sort {$a->[0] cmp $b->[0]} $self->items;
}

sub delete_item {
   my $self = shift;
   my $itemref = shift;
   delete $self->{coverage}{$itemref->key()};
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Coverage - Coverage analysis utilities

=head1 SYNOPSIS

  use SystemC::Coverage;

  $Coverage = new SystemC::Coverage;
  $Coverage->read (filename=>'cov1');
  $Coverage->read (filename=>'cov2');
  $Coverage->write (filename=>'cov_together');

=head1 DESCRIPTION

SystemC::Coverage provides utilities for reading and writing coverage data,
usually produced by the SP_COVER_INSERT or SP_AUTO_COVER function of the
SystemPerl package.

The coverage data is stored in a global hash called %Coverage, thus
subsequent reads will increment the same global structure.

=head1 METHODS

=over 4

=item clear

Clear the coverage variables


=item delete_item

Delete specified coverage item.

=item inc (args..., count=>value)

Increment the coverage statistics, entering keys for every value.  The last
value is the increment amount.  See SystemC::Coverage::Item for the list of
standard named parameters.

=item items

Return all coverage items, as a list of SystemC::Coverage::Item objects.

=item items_sorted

Return all coverage items in sorted order, as a list of
SystemC::Coverage::Item objects.

=item new  ([filename=>I<filename>])

Make a new empty coverage container.

=item read ([filename=>I<filename>])

Read the coverage data from the file, with error checking.

=item write ([filename=>I<filename>])

Write the coverage variables to the file in a form where they can be read
back by simply evaluating the file.

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

L<vcoverage>,
L<SystemC::Coverage::Item>

=cut

######################################################################

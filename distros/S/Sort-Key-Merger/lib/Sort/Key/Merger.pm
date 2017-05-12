package Sort::Key::Merger;

our $VERSION = '0.08';

use strict;
use warnings;
use Carp;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(keymerger nkeymerger
		    filekeymerger nfilekeymerger);

require XSLoader;
XSLoader::load('Sort::Key::Merger', $VERSION);

use constant STR_SORT => 0;
use constant LOC_STR_SORT => 1;
use constant NUM_SORT => 2;
use constant INT_SORT => 3;

use constant KEY => 0;
use constant KEY1 => 1;
use constant VALUE => 2;
use constant FILE => 3;
use constant SCRATCHPAD => 4;
use constant RS => 4;

my ($int_hints, $locale_hints);
BEGIN {
    use integer;
    $int_hints = $integer::hint_bits || 0x1;

    use locale;
    $locale_hints = $locale::hint_bits || 0x4;

    # print STDERR "locale: $locale_hints, int: $int_hints\n";
}

sub _merger_maker {
    my ($cmp, $sub, @args)=@_;
    my @src;
    my $i=0;
    for (@args) {
	my $scratchpad;
	if (my ($k, $v) = &{$sub}($scratchpad)) {
	    unshift @src, [$k, $i++, $v, $_, $scratchpad];
	    _resort($cmp, \@src);
	}
    }
    my $gen;
    $gen = sub {
	if (wantarray) {
	    my @all;
	    my $next;
	    while(defined($next = &$gen)) {
		push @all, $next;
	    }
	    return @all;
	}
	else {
	    my $old_v;
	    if (@src) {
		my $src=$src[KEY];
		$old_v=$src->[VALUE];
		for ($src[0][FILE]) {
		    if (my @kv = &{$sub}($src->[SCRATCHPAD])) {
			@kv == 2 or croak 'wrong number of return values from merger callback';
			@{$src}[KEY, VALUE] = @kv;
			_resort($cmp, \@src);
		    }
		    else {
			shift @src;
		    }
		}
	    }
	    return $old_v;
	}
    };
}

sub keymerger (&@) {
    my $sort = ((caller(0))[8] & $locale_hints)
	? LOC_STR_SORT : STR_SORT;
    _merger_maker( $sort, @_ )
}

sub nkeymerger (&@) {
    my $sort = ((caller(0))[8] & $int_hints)
	? INT_SORT : NUM_SORT;
    _merger_maker( $sort, @_ )
}



sub _file_merger_maker {
    my ($cmp, $sub, @args)=@_;
    my @src;
    my $i = 0;
    for my $file (@args) {
	my $fh;
	if (UNIVERSAL::isa($file, 'GLOB')) {
	    $fh=$file;
	}
	else {
	    open $fh, '<', $file
		or croak "unable to open '$file'";
	}
	local $/ = $/;
	local $_;
	while(<$fh>) {
	    if (defined(my $k = &{$sub})) {
		unshift @src, [$k, $i++, $_, $fh, $/];
		_resort($cmp, \@src);
		last;
	    }
	}
    }

    # print Dumper(\@src);

    my $gen;
    $gen = sub {
	if (wantarray) {
	    my @all;
	    while(@src) {
		push @all, scalar(&$gen);
	    }
	    return @all;
	}
	else {
	    if (@src) {
		my $src=$src[0];
		my $old_v=$src->[VALUE];
		local *_ = \($src->[VALUE]);
		local */ = \($src->[RS]);   # emacs syntax higlighting breaks here/;
		my $fh=$src->[FILE];
		while(<$fh>) {
		    if (defined ($src->[KEY]=&{$sub})) {
			_resort($cmp, \@src);
			return $old_v;
		    }
		}
		shift @src;
		return $old_v;
	    }
	    return undef
	}
    };
}


sub filekeymerger (&@) {
    my $sort = ((caller(0))[8] & $locale_hints)
	? LOC_STR_SORT : STR_SORT;
    _file_merger_maker( $sort, @_ )
}

sub nfilekeymerger (&@) {
    my $sort = ((caller(0))[8] & $int_hints)
	? INT_SORT : NUM_SORT;
    _file_merger_maker( $sort, @_ )
}


1;
__END__

=head1 NAME

Sort::Key::Merger - Perl extension for merging sorted things

=head1 SYNOPSIS

  use Sort::Key::Merger qw(keymerger);

  sub line_key_value {

      # $_[0] is available as a scratchpad that persist
      # between calls for the same $_;
      unless (defined $_[0]) {
          # so we use it to cache the file handle when we
	  # open a file on the first read
	  open $_[0], "<", $_
	      or croak "unable to open $_";
      }

      # don't get confused by this while loop, it's only
      # used to ignore empty lines
      my $fh = $_[0];
      local $_; # break $_ aliasing;
      while (<$fh>) {
	  next if /^\s*$/;
	  chomp;
	  if (my ($key, $value) = /^(\S+)\s+(.*)$/) {
	      return ($key, $value)
	  }
	  warn "bad line $_"
      }

      # signals the end of the data by returning an
      # empty list
      ()
  }

  # create a merger object:
  my $merger = keymerger { line_key_value } @ARGV;

  # sort and write the values:
  my $value;
  while (defined($value=$merger->())) {
      print "value: $value\n"
  }



=head1 DESCRIPTION

Sort::Key::Merger allows to merge presorted collections of I<things>
based on some (calculated) key.

=head2 EXPORT

None by default.

The functions described below can be exported requesting so
explicitly, i.e.:

  use Sort::Key::Merger qw(keymerger);


=head2 FUNCTIONS

=over 4

=item keymerger { generate_key_value_pair } @sources;

merges the (presorted) generated values sorted by their keys
lexicographically.

Every item in C<@source> is aliased by $_ and then the user defined
subroutine C<generate_key_value_pair> called. The result from that
subroutine call should be a (key, value) pair. Keys are used to
determine the order in which the values are sorted and returned.

C<generate_key_value_pair> can return an empty list to indicate that a
source has become exhausted.

The result from C<keymerger> is another subroutine that works as a
generator. It can be called as:

  my $next = &$merger;

or

  my $next = $merger->();

In scalar context it returns the next value or undef if all the
sources have been exhausted. In list context it returns all the values
remaining from the sources merged in a sorted list.

NOTE: an additional argument is passed to the
C<generate_key_value_pair> callback in C<$_[0]>. It is to be used as a
scrachpad, its value is associated to the current source and will
perdure between calls from the same generator, i.e.:

  my $merger = keymerger {

      # use $_[0] to cache an open file handler:
      $_[0] or open $_[0], '<', $_
	  or croak "unable to open $_";

      my $fh = $_[0];
      local $_;
      while (<$fh>) {
	  chomp;
	  return $_ => $_;
      }
      ();
  } ('/tmp/foo', '/tmp/bar');


This function honours the C<use locale> pragma.

=item nkeymerger { generate_key_value_pair } @sources

is like C<keymerger> but compares the keys numerically.

This function honours the C<use integer> pragma.

=item filekeymerger { generate_key } @files;

returns a merger subroutine that returns lines read from C<@files>
sorted by the keys that C<generate_key> generates.

C<@files> can contain file names or handles for already open files.

C<generate_key> is called with the line just read on C<$_> and has to
return the sorting key for it. If its return value is C<undef> the
line is ignored.

The line can be modified inside C<generate_key> changing C<$_>, i.e.:

  my $merger = filekeymerger {
      chomp($_); #             <-- here
      return undef if /^\s*$/;
      substr($_, -1, 10)
  } @ARGV;


Finally, C<$/> can be changed from its default value to read the files
in chunks other than lines.

The return value from this function is a subroutine reference that on
successive calls returns the sorted elements; or all elements in one
go when called in list context, i.e.:

  my $merger = filekeymerger { (split)[0] } @ARGV;
  my @sorted = $merger->();


This function honours the C<use locale> pragma.

=item nfilekeymerger { generate_key } @files;

is like C<filekeymerger> but the keys are compared numerically.

This function honours the C<use integer> pragma.

=back

=head1 SEE ALSO

L<Sort::Key>, L<locale>, L<integer>, perl core L<sort> function.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Salvador FandiE<ntilde>o.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

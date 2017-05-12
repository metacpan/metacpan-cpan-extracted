#!/usr/bin/perl -w

package Sort::ArrayOfArrays;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT_OK $VERSION);
@ISA = qw(Exporter);
@EXPORT_OK = qw(sort_it);
$VERSION = '1.00';

sub new {
  my $type  = shift;
  my @PASSED_ARGS = (ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
  my @DEFAULT_ARGS = (
    header_row  => 0,
    results     => [],
    sort_column => '',
    sort_code   => [],
  );
  my %ARGS = (@DEFAULT_ARGS, @PASSED_ARGS);
  my $self = bless \%ARGS, $type;
  return $self;
}

sub sort_it {
  my $self = shift;

  unless(ref $self eq __PACKAGE__) {
    $self = __PACKAGE__->new({
      results     => $self,
      sort_column => $_[0],
      sort_code   => $_[1],
      header_row  => $_[2],
    });
  }

  die "\$self->{results} is required" unless($self->{results});
  die "\$self->{results} needs to be an array of arrays" unless(ref $self->{results} eq 'ARRAY' && $self->{results}->[0] && ref $self->{results}->[0] eq 'ARRAY');
  if($self->{header_row}) {
    $self->{zero_row} = shift @{$self->{results}};
  }

  $self->{rows} = (@{$self->{results}} - 1);

  $self->make_sort_code_ref;

  my $sort_method = $self->{sort_code_ref};
  my @temp = (0 .. $self->{rows});
  @temp = sort $sort_method @temp;

  my $return = [];

  for(my $i=0;$i<@temp;$i++) {
    $return->[$i] = $self->{results}->[$temp[$i]];
  }

  if($self->{header_row}) {
    unshift @{$return}, $self->{zero_row};
    delete $self->{zero_row};
  }
  $self->{results} = $return;
  return $return;
}

sub make_sort_code_text {
  my $self = shift;
  return if($self->{sort_code_text});

  my $total_sorts = 0;
  foreach my $this_sort_column (split /\s*,\s*/, $self->{sort_column}) {
    $total_sorts++;
    my $col = abs($this_sort_column);
    if($self->{sort_code} && ref $self->{sort_code}) {
      if(ref $self->{sort_code} eq 'HASH' && $self->{sort_code}->{$col}) {
        if(ref $self->{sort_code}->{$col}) {
          die "any ref for \$self->{sort_code}->{$col} needs to be an CODE ref" unless(ref $self->{sort_code}->{$col} eq 'CODE');
          $self->{sort_code_ref} = $self->{sort_code}->{$col};
          return;
        }
      } elsif(ref $self->{sort_code} eq 'ARRAY' && $self->{sort_code}->[$col]) {
        if(ref $self->{sort_code}->[$col]) {
          die "any ref for \$self->{sort_code}->[$col] needs to be an CODE ref" unless(ref $self->{sort_code}->[$col] eq 'CODE');
          $self->{sort_code_ref} = $self->{sort_code}->[$col];
          return;
        }
      }
    }
  }

  $self->{sort_code_text} = "sub {\n";#"}"
  my $this_sort = 0;
  foreach my $this_sort_column (split /\s*,\s*/, $self->{sort_column}) {
    $this_sort++;
    my $this_sort_method;
    if($self->{sort_code} && ref $self->{sort_code}) {
      if(ref $self->{sort_code} eq 'HASH' && $self->{sort_code}->{$this_sort_column}) {
        $this_sort_method = $self->{sort_code}->{$this_sort_column};
      } elsif(ref $self->{sort_code} eq 'ARRAY' && $self->{sort_code}->[$this_sort_column]) {
        $this_sort_method = $self->{sort_code}->[$this_sort_column];
      }
    }
    my $this_toggle = $this_sort_column =~ s/^\-(\d+)$/$1/;

    unless($this_sort_method) {
      $this_sort_method = 'aa';
      for(my $i=0;$i<=$self->{rows};$i++) {
        if($self->{results}->[$i]->[$this_sort_column] =~ /[^0-9.\-+ ]/) {
          last;
        } elsif($self->{results}->[$i]->[$this_sort_column] =~ /^[0-9.\-+]+$/) {
          next if($self->{results}->[$i]->[$this_sort_column] =~ /^\.+$/);
          $this_sort_method = 'na';
          last;
        }
      }
    }

    if($total_sorts == $this_sort) {
      if($this_toggle && $this_sort_method =~ /^.a$/) {
        $this_sort_method =~ s/^(.)a$/$1d/i;
      } elsif($this_toggle && $this_sort_method =~ /^.d$/) {
        $this_sort_method =~ s/^(.)d$/$1a/i;
      }
    }

    # I just change stuff of type link to stuff of type regex, with the regex below
    if ($this_sort_method =~ s/^l(.)$/r$1/i) {
      die "need regex for sort_method on column $this_sort_column" unless(exists $self->{sort_method_regex}->{$this_sort_column});
      $self->{sort_method_regex}->{$this_sort_column} = qr@<a\s+href[^>]+?>(.+?)</a>@i;
    }

    my $symbol;
    my $special_sort_method = 0;
    if($this_sort_method =~ /^a.$/i) {
      $symbol = 'cmp';
    } elsif ($this_sort_method =~ /^n.$/i) {
      $symbol = '<=>';
    } elsif ($this_sort_method =~ /^t.$/i) {
      $special_sort_method = 1;
    } elsif ($this_sort_method =~ /^r.$/i) {
      die "need regex for sort_method on column $this_sort_column" unless($self->{sort_method_regex}->{$this_sort_column});
      $symbol = $self->{sort_method_symbol}->{$this_sort_column} || 'cmp';
      $self->{sort_code_text} .= <<SORT_METHOD;
  my (\$_a) = \$self->{results}->[\$a]->[$this_sort_column] =~ /$self->{sort_method_regex}->{$this_sort_column}/;
  my (\$_b) = \$self->{results}->[\$b]->[$this_sort_column] =~ /$self->{sort_method_regex}->{$this_sort_column}/;
SORT_METHOD

      if($self->{sort_code}->[$this_sort_column] =~ /^.d$/i) {
        $self->{sort_code_text} = "{\n  $self->{sort_code_text}\n  \$_b $symbol \$_a\n}";
      } else {
        $self->{sort_code_text} = "{\n  $self->{sort_code_text}\n  \$_a $symbol \$_b\n}";
      }
      $special_sort_method = 1;
    } else {
      die "unknown sort method $this_sort_method";
    }

    if(!$special_sort_method && $this_sort_method =~ /^.a$/i) {
      $self->{sort_code_text} .= '  $self->{results}->[$a]->[' . "$this_sort_column" .'] ' . "$symbol" . ' $self->{results}->[$b]->[' . "$this_sort_column" . "] ||\n";
    } elsif ($this_sort_method =~ /^.d$/i) {
      $self->{sort_code_text} .= '  $self->{results}->[$b]->[' . "$this_sort_column" .'] ' . "$symbol" . ' $self->{results}->[$a]->[' . "$this_sort_column" . "] ||\n";
    }
  }
  # sadly, this line is to unbug vi {
  $self->{sort_code_text} =~ s/\s*\|\|\s*$/\n\}/;
}

sub make_sort_code_ref {
  my $self = shift;
  return if($self->{sort_code_ref} && ref $self->{sort_code_ref} eq 'CODE');
  $self->make_sort_code_text;
  $self->{sort_code_ref} = eval $self->{sort_code_text};
  if($@) {
    die "$self->{sort_code_text}\ndid not lead to a valid CODE ref";
  }
}

1;

__END__
=head1 NAME

Sort::ArrayOfArrays - Perl extension for sorting an array of arrays

=head1 SYNOPSIS

  use Sort::ArrayOfArrays;
  my $sort = Sort::ArrayOfArrays->new({
    results => [
      [1 .. 10],
      [10 .. 1],
    ],
    sort_column => -1,
  });
  my $sorted = $sort->sort_it;

  # several examples are in the test scripts that came with the package in the t/ directory
  
=head1 DESCRIPTION

Sort::ArrayOfArrays was written to sort an arbitrary array of arrays, in powerful, different ways.

=head1 PROPERTIES

Any of the properties below can be set in your object.  This can easily be done by passing a hash ref to new.
header_row    => set to 1 if you have a header row in $self->{results}

sort_code     => how to sort on each column, can be 
  a code ref - a code ref that gets run through sort (sorry, currently no multi-column sort of code ref)
  a hash ref - the key is the column number the value is described below, like
    sort_code => {
      0 => 'aa',
      2 => 'rd',
      4 => 'nd',
    }
  an array ref - a list of values as described below, where each position corresponds to the respective column
    sort_code => [ 
      'aa', 'la', 'da',
    ]
  the sort code values (when not a code ref) are two digits, 
  
  the first digit possibilities are
    a - alphabetical sort
    n - numerical sort
    r - regex sort, where $1 is what gets sorted on, like
        /<!--stuff-->(.+?)<!--end of stuff-->/
        use a qr if you need to use switches, like
        sort_code => {
          0 => 'ra',
        },
        sort_method_regex => {
          qr/<!--stuff-->(.+?)<!--end of stuff-->/i,
        }
        sort_method_regex is a hash ref contain where the key is the column and the value is the regex
    l - an instance of the regex type, where this regex qr@<a\s+href[^>]+?>(.+?)</a>@i attempts to match a link,
        if you wanted to match the href, you would have to use the appropriate regex

  the second digit possibilities are
    a - ascending
    d - decending

  defaults - the beginning default is 'aa', which is an alphabetical ascending sort, I keep this default if I find a value
             in the respective column that contains something that is not "a number", defined by this regex
             /[^0-9.\-+ ]/.  
             If I find a value in the respective column that is only "a number", defined by this regex /^[0-9.\-+]+$/, I use
             'na', which is a numerical ascending sort

             Note that the defaults are problematic, in that I have to look through values, performing regexes.  I stop
             as soon as I can, which in my experience is usually after just a value or two, but if this is not acceptable,
             or if you would like to perform searches in a way contrary to the default, you need to set a value yourself

  dates - initially I started to write different sort for each date format, but found it much better to do something like
          <!--1009411647-->December 26, and then just do a 'aa'.  The epoch time in the date will do a nice ascii sort,
          and not appear in any html.  If this is not acceptable, you can always use a code_ref and sort however you like.
          You likely want to sprintf out to ten digits just so old nine digit stuff will ascii sort properly

sort_method_regex => used in conjunction with sort_method of type regex (see above)
sort_column   => a zero based, column delimited, list of columns you would like to sort on,
                 where a - means to reverse the sort
  for example, 
  '0' means to sort on the zeroeth column
  '3,-1,-0', means to try and sort on the third column, 
    then (if the values from both columns are equal), sort on first column in reverse order,
    then (if the values all above colulmns are equal), sort on the zeroeth column in reverse order,

=head2 EXPORT_OK

sort_it

=head1 AUTHOR

Earl Cahill <cpan@spack.net>

=head1 THANKS

Thanks to Paul T Seamons <paul@seamons.com> for the idea of a nice, simple two letter code for sort definitions, 'aa', 'nd' and the like.  It made it pretty easy to add the regex type.  It was also Paul's idea to use <!--1234567890--> for time sorts, which saved oh, so many headaches.

=cut

###  $Id: Parser.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------

## @file
# Define Parser for Quests map language
#
## @class Parser
# Parse map and game state files
#


package OpenGL::QEng::Parser;

use base Exporter;
@EXPORT_OK = qw(records tokens make_lexer
		head tail hpop iterator_to_stream
		nothing End_of_Input lookfor
                alternate concatenate star list_of
                T two_part
                );
%EXPORT_TAGS = ('all' => \@EXPORT_OK);

#------------------------------------------------------------
sub records {
  my ($input,$terminator) = @_;
  $terminator = quotemeta($/) unless defined $terminator;

  my @records;
  my @newrecs = split /$terminator/, $input;
  # use split /($terminator)/ to keep terminators

  my $fullr;
  while (@newrecs) {
    my $rec = shift @newrecs;
    next if (substr($rec,0,1) eq '#');
    next if ($rec =~ /^\s*$/);

    while (substr($rec,-1,1) eq '\\') { # combine broken records
      chop $rec;
      if (my $r = shift @newrecs) {
	$r = '\\' if (substr($r,0,1) eq '#');
	$rec .= $r;
      }
    }
    $fullr .= $rec.' ';
  }
  push @records, $fullr;
  sub { if (@records) {shift(@records)} else {return undef} };
}

#------------------------------------------------------------
sub tokens {
  my ($input,$label,$pattern,$maketoken) = @_;
  $maketoken ||= sub { [$_[1], $_[0]] };
  my @tokens;
  my $buf = '';
  my $split = sub { split /($pattern)/, $_[0] };
  sub {
    while (@tokens == 0 && defined $buf) {
      my $i = $input->();
      if (ref $i) {
	my ($sep, $tok) = $split->($buf);
	$tok = $maketoken->($tok,$label) if defined $tok;
	{
	  no warnings 'uninitialized';
	  push @tokens, grep $_ ne '', $sep, $tok, $i;
	}
	$buf = '';
	last;
      }
      $buf .= $i if defined $i;
      my @newtoks = $split->($buf);
      while (@newtoks > 2 || @newtoks && !defined $i) {
	push @tokens, shift(@newtoks);
	push @tokens, $maketoken->(shift(@newtoks), $label) if @newtoks;
      }
      $buf = join '', @newtoks;
      undef $buf if !defined $i;
      @tokens = grep $_ ne '', @tokens;
    }
    shift @tokens;
  };
}

#------------------------------------------------------------
sub make_lexer {
  my $lexer = shift;
  while (@_) {
    my $args = shift;
    $lexer = tokens($lexer, @$args);
  }
  $lexer;
}

#------------------------------------------------------------
sub tail {
  if (ref($_[0][1]) eq 'CODE') {
    $_[0][1] = $_[0][1]->();
  }
  $_[0][1];
}

#------------------------------------------------------------
sub head {
  $_[0][0];
}
#------------------------------------------------------------
sub hpop {
  my $h = head($_[0]);
  $_[0] = tail($_[0]);
  $h;
}

#------------------------------------------------------------
sub iterator_to_stream {
  my ($it) = @_;
  my $v = $it->();
  return unless defined $v;
  [$v, sub {iterator_to_stream($it)}];
}

#------------------------------------------------------------
sub nothing {
  my $input = shift;
  return (undef, $input);
}

#------------------------------------------------------------
sub End_of_Input {
  my $input = shift;
  defined($input) ? () : (undef, undef);
}

#------------------------------------------------------------
sub aref_str {
  my ($aref) = @_;
  (defined $aref && ref($aref) eq 'ARRAY')
    ? join ',', @$aref
    : '';
}

#------------------------------------------------------------
sub lookfor {
  my $wanted = shift;
  my $value = shift || sub { $_[0][1] };
  my $u = shift;
  $wanted = [$wanted] unless ref $wanted;
  sub {
    my $input = shift;
    return unless defined $input;
    my $next = head($input);
    for my $i (0 .. $#$wanted) {
      next unless defined $wanted->[$i];
      return unless $wanted->[$i] eq $next->[$i];
    }
    my $wanted_value = $value->($next, $u);
    print STDERR "lf: got $wanted_value\n" if defined $ENV{DEBUG_TOKEN};
    return ($wanted_value, tail($input));
  };
}

#------------------------------------------------------------
sub concatenate {
  my @p = @_;
  return \&nothing if @p == 0;
  return $p[0]  if @p == 1;
  sub {
    my $input = shift;
    my $v;
    my @values;
    for (@p) {
      $i++;
      if (($v, $input) = $_->($input)) {
	push @values, $v;
      } else {
	return;
      }
    }
   return (\@values, $input);
  };
}

#------------------------------------------------------------
sub alternate {
  my @p = @_;
  return sub { return () } if @p == 0;
  return $p[0] if @p == 1;
  sub {
    my $input = shift;
    my ($v, $newinput);
    for (@p) {
      if (($v, $newinput) = $_->($input)) {
        return ($v, $newinput);
      }
    }
    return;
  };
}

#------------------------------------------------------------
sub two_part {
  my ($p0,$p1) = @_;
  return sub { return () } unless @_ == 2;
  sub {
    my $input = shift;
    my ($v0, $ni0, $v1, $ni1);

    if (($v0, $ni0) = $p0->($input)) {
      if (($v1, $ni1) = $p1->($ni0)) {
	return ([$v0,$v1], $ni1);
      }
    }
    return;
  };
}

#------------------------------------------------------------
sub star {
  my $p = shift;
  my $p_star;
  $p_star = T(alternate(T(concatenate($p, sub { $p_star->(@_) }),
			sub{my ($f,$r) = @_; defined $r ? [$f,@$r] : [$f]},),
			#sub{[@_]},),
		      \&nothing),
    sub{
      #use Data::Dumper;
      #print STDERR "star() returning :",(map{Dumper($_).' '} @_),"\n";
      [@_];
      }	     );
}

#------------------------------------------------------------
sub list_of {
  my ($element, $separator) = @_;
  $separator = lookfor('COMMA') unless defined $separator;
  T(concatenate(star(two_part($element, $separator)),
 		alternate(concatenate($element, \&nothing), \&nothing)),
    sub{
      return [@_] unless defined $_[0];
      my @out;
      if (ref($_[0]) eq 'ARRAY') {
	@out = @{$_[0]};
      } else {
	push @out, $_[0];
      }
      push @out, $_[1] if defined $_[1];
      [@out];
    });
}

#------------------------------------------------------------
sub T {
  my ($parser, $transform) = @_;
  return sub {
    my $input = shift;
    if (my ($value, $newinput) = $parser->($input)) {
      $value = $transform->(@$value);
      return ($value, $newinput);
    } else {
      return;
    }
  };
}

#-----------------------------------------------------------------------------
1;

__END__

=head1 NAME

Parser -- parses GameState and Map files

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


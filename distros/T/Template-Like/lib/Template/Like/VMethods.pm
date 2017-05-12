package Template::Like::VMethods;

use strict;

sub can {
  my $class = shift;
  my $name  = shift;
  my $val   = shift;
  my $type  = $class->getTypeByVal($val);
  my $method = $type . '_' . $name;
  
  return $class->SUPER::can($method);
}

sub exec {
  my $class = shift;
  my $name  = shift;
  my $val   = shift;
  my $type  = $class->getTypeByVal($val);
  my $method = $type . '_' . $name;
  
  return $class->$method($val, @_);
}

sub getTypeByVal {
  return !ref $_[1]             ? 'scalar'      :
          ref $_[1] ne 'SCALAR' ? lc(ref $_[1]) : '';
}

sub scalar_defined {
  my $class = shift;
  my $val  = shift;
  
  return defined $val;
}

sub scalar_length {
  my $class = shift;
  my $val  = shift;
  
  return length $val;
}

sub scalar_repeat {
  my $class = shift;
  my $val  = shift;
  my $arg  = shift;
  
  die q{VMethod USAGE [% scalar.repeat(\d+) %]} unless defined $arg && $arg=~/^\d+$/;
  
  return $val x $arg;
}

sub scalar_replace {
  my $class    = shift;
  my $val     = shift;
  my $search  = shift;
  my $replace = shift;
  
  die q{VMethod USAGE [% scalar.replace('hogge', 'hoge') %]} unless defined $search && defined $replace;
  
  $val=~s/$search/$replace/g;
  
  return $val;
}

sub scalar_match {
  my $class    = shift;
  my $val     = shift;
  my $pattern = shift;
  
  die q{VMethod USAGE [% FOREACH matchstr = scalar.match('(\w)oge') %]} unless defined $pattern;
  
  my @maches = $val=~/$pattern/g;
  
  return undef unless scalar(@maches);
  
  return \@maches;
}

sub scalar_search {
  my $class    = shift;
  my $val     = shift;
  my $pattern = shift;
  
  die q{VMethod USAGE [% IF scalar.search('(\w)oge') %]} unless defined $pattern;
  
  return $val=~/$pattern/;
}

sub scalar_split {
  my $class    = shift;
  my $val     = shift;
  my $pattern = shift;
  
  die q{VMethod USAGE [% FOREACH scalar.split(':') %]} unless defined $pattern;
  
  return [ split($pattern, $val) ];
}

sub scalar_list {
  my $class    = shift;
  my $val     = shift;
  
  return [ $val ];
}

sub scalar_hash {
  my $class    = shift;
  my $val     = shift;
  
  return { value => $val };
}

sub scalar_size {
  return 1;
}

sub scalar_substr {
  my $class  = shift;
  my $val    = shift;
  my $offset = shift;
  my $size   = shift;
  my $str    = substr $val, $offset, $size;
  
  return $str;
}

sub scalar_html {
  my $class  = shift;
  my $val    = shift;
  
  return unless length $val;
  
  $val =~ s{&}{&amp;}gso;
  $val =~ s{<}{&lt;}gso;
  $val =~ s{>}{&gt;}gso;
  $val =~ s{"}{&quot;}gso;
  
  return $val;
}

sub scalar_uri {
  my $class  = shift;
  my $val    = shift;
  
  $val =~ s/(\W)/'%' . unpack('H2', $1)/eg;
  
  return $val;
}

sub scalar_comma {
  my $class = shift;
  my $num   = shift;
  my $len   = shift;
  
  $len ||= 3;
  
  my ( $i, $j );
  if ($num =~ /^[-+]?\d\d\d\d+/g) {
    for ($i = pos($num) - $len, $j = $num =~ /^[-+]/; $i > $j; $i -= $len) {
      substr($num, $i, 0) = ',';
    }
  }
  
  return $num;
}

sub array_first {
  my $class = shift;
  my $val   = shift;
  return $val->[0];
}

sub array_last {
  my $class = shift;
  my $val   = shift;
  return $val->[ $#{ $val } ];
}

sub array_size {
  my $class = shift;
  my $val   = shift;
  return scalar( @{ $val } );
}

sub array_max {
  my $class = shift;
  my $val   = shift;
  return $#{ $val };
}

sub array_reverse {
  my $class = shift;
  my $val   = shift;
  return [ reverse @{ $val } ];
}

sub array_join {
  my $class = shift;
  my $val  = shift;
  my $sep  = shift || " ";
  return join $sep, @{ $val };
}

sub array_grep {
  my $class   = shift;
  my $val     = shift;
  my $pattern = shift;
  return [ grep /$pattern/, @{ $val } ];
}

sub array_sort {
  my $class   = shift;
  my $val     = shift;
  my $key     = shift;
  if ( defined $key ) {
    return [ sort { $a->{$key} cmp $b->{$key} } @{ $val } ];
  }
  return [ sort { $a cmp $b } @{ $val } ];
}

sub array_nsort {
  my $class   = shift;
  my $val     = shift;
  my $key     = shift;
  if ( defined $key ) {
    return [ sort { $a->{$key} <=> $b->{$key} } @{ $val } ];
  }
  return [ sort { $a <=> $b } @{ $val } ];
}

sub array_unshift {
  my $class   = shift;
  my $val     = shift;
  my $item    = shift;
  unshift @{ $val }, $item;
  return ;
}

sub array_push {
  my $class   = shift;
  my $val     = shift;
  my $item    = shift;
  push @{ $val }, $item;
  return ;
}

sub array_shift {
  my $class   = shift;
  my $val     = shift;
  shift @{ $val };
}

sub array_pop {
  my $class   = shift;
  my $val     = shift;
  pop @{ $val };
}

sub array_unique {
  my $class   = shift;
  my $val     = shift;
  my $hash_ref = {};
  
  @{ $hash_ref }{ @{ $val } } = ('1') x scalar( @{ $val } );
  return [ keys %{ $hash_ref } ];
}

sub array_merge {
  my $class   = shift;
  my $val     = shift;
  my @arrays  = @_;
  
  my @result = @{ $val };
  push @result, @{ $_ } for ( @arrays );
  
  return \@result;
}

sub array_slice {
  my $class   = shift;
  my $val     = shift;
  my $from    = shift;
  my $to      = shift;
  
  return [ @{ $val }[ $from .. $to ] ];
}

sub array_splice {
  my $class   = shift;
  my $val     = shift;
  my $offset  = shift;
  my $length  = shift;
  my @list    = ref $_[0] ? @{ $_[0] } : @_ ;
  
  return [ splice @{ $val }, $offset, $length, @list ];
}

sub array_list { $_[1] }

sub hash_keys {
  my $class = shift;
  my $val  = shift;
  return [ keys %{ $val } ];
}

sub hash_values {
  my $class = shift;
  my $val  = shift;
  return [ values %{ $val } ];
}

sub hash_each {
  my $class = shift;
  my $val  = shift;
  my @list;
  while ( my ( $key, $val ) = each %{ $val } ) { push @list, $key, $val; }
  return \@list;
}

sub hash_defined {
  my $class = shift;
  my $val  = shift;
  my $key  = shift;
  return defined $val->{$key};
}

sub hash_exists {
  my $class = shift;
  my $val  = shift;
  my $key  = shift;
  return exists $val->{$key};
}

sub hash_size {
  my $class = shift;
  my $val  = shift;
  
  return scalar( keys %{ $val } );
}

sub hash_item {
  my $class = shift;
  my $val  = shift;
  my $key  = shift;
  return $val->{$key};
}

sub hash_list {
  my $class = shift;
  my $val  = shift;
  my $type = shift;
  
  if ( defined $type && $type eq 'keys' ) {
    return $class->keys( $val );
  } elsif ( defined $type && $type eq 'values' ) {
    return $class->values( $val );
  } elsif ( defined $type && $type eq 'each' ) {
    return $class->each( $val );
  } else {
    my @list;
    while ( my ( $key, $val ) = CORE::each(%{ $val }) ) { push @list, { key => $key, value => $val }; }
    return \@list;
  }
}

1;
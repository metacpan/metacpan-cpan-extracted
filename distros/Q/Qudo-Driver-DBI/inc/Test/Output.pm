#line 1
package Test::Output;

use warnings;
use strict;

use Test::Builder;
use Test::Output::Tie;
use Sub::Exporter -setup => {
  exports => [
    qw(output_is output_isnt output_like output_unlike
      stderr_is stderr_isnt stderr_like stderr_unlike
      stdout_is stdout_isnt stdout_like stdout_unlike
      combined_is combined_isnt combined_like combined_unlike
      output_from stderr_from stdout_from combined_from
      )
  ],
  groups => {
    stdout => [
      qw(
        stdout_is stdout_isnt stdout_like stdout_unlike
        )
    ],
    stderr => [
      qw(
        stderr_is stderr_isnt stderr_like stderr_unlike
        )
    ],
    output => [
      qw(
        output_is output_isnt output_like output_unlike
        )
    ],
    combined => [
      qw(
        combined_is combined_isnt combined_like combined_unlike
        )
    ],
    functions => [
      qw(
        output_from stderr_from stdout_from combined_from
        )
    ],
    tests => [
      qw(
        output_is output_isnt output_like output_unlike
        stderr_is stderr_isnt stderr_like stderr_unlike
        stdout_is stdout_isnt stdout_like stdout_unlike
        combined_is combined_isnt combined_like combined_unlike
        )
    ],
    default => [ '-tests' ],
  },
};

my $Test = Test::Builder->new;

#line 65

our $VERSION = '0.12';

#line 115

#line 119

#line 139

sub stdout_is (&$;$$) {
  my $test        = shift;
  my $expected    = shift;
  my $options     = shift if ( ref( $_[0] ) );
  my $description = shift;

  my $stdout = stdout_from($test);

  my $ok = ( $stdout eq $expected );

  $Test->ok( $ok, $description )
    || $Test->diag("STDOUT is:\n$stdout\nnot:\n$expected\nas expected");

  return $ok;
}

sub stdout_isnt (&$;$$) {
  my $test        = shift;
  my $expected    = shift;
  my $options     = shift if ( ref( $_[0] ) );
  my $description = shift;

  my $stdout = stdout_from($test);

  my $ok = ( $stdout ne $expected );

  $Test->ok( $ok, $description )
    || $Test->diag("STDOUT:\n$stdout\nmatching:\n$expected\nnot expected");

  return $ok;
}

#line 189

sub stdout_like (&$;$$) {
  my $test        = shift;
  my $expected    = shift;
  my $options     = shift if ( ref( $_[0] ) );
  my $description = shift;

  unless ( my $regextest = _chkregex( 'stdout_like' => $expected ) ) {
    return $regextest;
  }

  my $stdout = stdout_from($test);

  my $ok = ( $stdout =~ $expected );

  $Test->ok( $ok, $description )
    || $Test->diag("STDOUT:\n$stdout\ndoesn't match:\n$expected\nas expected");

  return $ok;
}

sub stdout_unlike (&$;$$) {
  my $test        = shift;
  my $expected    = shift;
  my $options     = shift if ( ref( $_[0] ) );
  my $description = shift;

  unless ( my $regextest = _chkregex( 'stdout_unlike' => $expected ) ) {
    return $regextest;
  }

  my $stdout = stdout_from($test);

  my $ok = ( $stdout !~ $expected );

  $Test->ok( $ok, $description )
    || $Test->diag("STDOUT:\n$stdout\nmatches:\n$expected\nnot expected");

  return $ok;
}

#line 249

sub stderr_is (&$;$$) {
  my $test        = shift;
  my $expected    = shift;
  my $options     = shift if ( ref( $_[0] ) );
  my $description = shift;

  my $stderr = stderr_from($test);

  my $ok = ( $stderr eq $expected );

  $Test->ok( $ok, $description )
    || $Test->diag("STDERR is:\n$stderr\nnot:\n$expected\nas expected");

  return $ok;
}

sub stderr_isnt (&$;$$) {
  my $test        = shift;
  my $expected    = shift;
  my $options     = shift if ( ref( $_[0] ) );
  my $description = shift;

  my $stderr = stderr_from($test);

  my $ok = ( $stderr ne $expected );

  $Test->ok( $ok, $description )
    || $Test->diag("STDERR:\n$stderr\nmatches:\n$expected\nnot expected");

  return $ok;
}

#line 300

sub stderr_like (&$;$$) {
  my $test        = shift;
  my $expected    = shift;
  my $options     = shift if ( ref( $_[0] ) );
  my $description = shift;

  unless ( my $regextest = _chkregex( 'stderr_like' => $expected ) ) {
    return $regextest;
  }

  my $stderr = stderr_from($test);

  my $ok = ( $stderr =~ $expected );

  $Test->ok( $ok, $description )
    || $Test->diag("STDERR:\n$stderr\ndoesn't match:\n$expected\nas expected");

  return $ok;
}

sub stderr_unlike (&$;$$) {
  my $test        = shift;
  my $expected    = shift;
  my $options     = shift if ( ref( $_[0] ) );
  my $description = shift;

  unless ( my $regextest = _chkregex( 'stderr_unlike' => $expected ) ) {
    return $regextest;
  }

  my $stderr = stderr_from($test);

  my $ok = ( $stderr !~ $expected );

  $Test->ok( $ok, $description )
    || $Test->diag("STDERR:\n$stderr\nmatches:\n$expected\nnot expected");

  return $ok;
}

#line 362

sub combined_is (&$;$$) {
  my $test        = shift;
  my $expected    = shift;
  my $options     = shift if ( ref( $_[0] ) );
  my $description = shift;

  my $combined = combined_from($test);

  my $ok = ( $combined eq $expected );

  $Test->ok( $ok, $description )
    || $Test->diag(
    "STDOUT & STDERR are:\n$combined\nnot:\n$expected\nas expected");

  return $ok;
}

sub combined_isnt (&$;$$) {
  my $test        = shift;
  my $expected    = shift;
  my $options     = shift if ( ref( $_[0] ) );
  my $description = shift;

  my $combined = combined_from($test);

  my $ok = ( $combined ne $expected );

  $Test->ok( $ok, $description )
    || $Test->diag(
    "STDOUT & STDERR:\n$combined\nmatching:\n$expected\nnot expected");

  return $ok;
}

#line 416

sub combined_like (&$;$$) {
  my $test        = shift;
  my $expected    = shift;
  my $options     = shift if ( ref( $_[0] ) );
  my $description = shift;

  unless ( my $regextest = _chkregex( 'combined_like' => $expected ) ) {
    return $regextest;
  }

  my $combined = combined_from($test);

  my $ok = ( $combined =~ $expected );

  $Test->ok( $ok, $description )
    || $Test->diag(
    "STDOUT & STDERR:\n$combined\ndon't match:\n$expected\nas expected");

  return $ok;
}

sub combined_unlike (&$;$$) {
  my $test        = shift;
  my $expected    = shift;
  my $options     = shift if ( ref( $_[0] ) );
  my $description = shift;

  unless ( my $regextest = _chkregex( 'combined_unlike' => $expected ) ) {
    return $regextest;
  }

  my $combined = combined_from($test);

  my $ok = ( $combined !~ $expected );

  $Test->ok( $ok, $description )
    || $Test->diag(
    "STDOUT & STDERR:\n$combined\nmatching:\n$expected\nnot expected");

  return $ok;
}

#line 515

sub output_is (&$$;$$) {
  my $test        = shift;
  my $expout      = shift;
  my $experr      = shift;
  my $options     = shift if ( ref( $_[0] ) );
  my $description = shift;

  my ( $stdout, $stderr ) = output_from($test);

  my $ok = 1;
  my $diag;

  if ( defined($experr) && defined($expout) ) {
    unless ( $stdout eq $expout ) {
      $ok = 0;
      $diag .= "STDOUT is:\n$stdout\nnot:\n$expout\nas expected";
    }
    unless ( $stderr eq $experr ) {
      $diag .= "\n" unless ($ok);
      $ok = 0;
      $diag .= "STDERR is:\n$stderr\nnot:\n$experr\nas expected";
    }
  }
  elsif ( defined($expout) ) {
    $ok = ( $stdout eq $expout );
    $diag .= "STDOUT is:\n$stdout\nnot:\n$expout\nas expected";
  }
  elsif ( defined($experr) ) {
    $ok = ( $stderr eq $experr );
    $diag .= "STDERR is:\n$stderr\nnot:\n$experr\nas expected";
  }
  else {
    unless ( $stdout eq '' ) {
      $ok = 0;
      $diag .= "STDOUT is:\n$stdout\nnot:\n\nas expected";
    }
    unless ( $stderr eq '' ) {
      $diag .= "\n" unless ($ok);
      $ok = 0;
      $diag .= "STDERR is:\n$stderr\nnot:\n\nas expected";
    }
  }

  $Test->ok( $ok, $description ) || $Test->diag($diag);

  return $ok;
}

sub output_isnt (&$$;$$) {
  my $test        = shift;
  my $expout      = shift;
  my $experr      = shift;
  my $options     = shift if ( ref( $_[0] ) );
  my $description = shift;

  my ( $stdout, $stderr ) = output_from($test);

  my $ok = 1;
  my $diag;

  if ( defined($experr) && defined($expout) ) {
    if ( $stdout eq $expout ) {
      $ok = 0;
      $diag .= "STDOUT:\n$stdout\nmatching:\n$expout\nnot expected";
    }
    if ( $stderr eq $experr ) {
      $diag .= "\n" unless ($ok);
      $ok = 0;
      $diag .= "STDERR:\n$stderr\nmatching:\n$experr\nnot expected";
    }
  }
  elsif ( defined($expout) ) {
    $ok = ( $stdout ne $expout );
    $diag = "STDOUT:\n$stdout\nmatching:\n$expout\nnot expected";
  }
  elsif ( defined($experr) ) {
    $ok = ( $stderr ne $experr );
    $diag = "STDERR:\n$stderr\nmatching:\n$experr\nnot expected";
  }
  else {
    if ( $stdout eq '' ) {
      $ok   = 0;
      $diag = "STDOUT:\n$stdout\nmatching:\n\nnot expected";
    }
    if ( $stderr eq '' ) {
      $diag .= "\n" unless ($ok);
      $ok = 0;
      $diag .= "STDERR:\n$stderr\nmatching:\n\nnot expected";
    }
  }

  $Test->ok( $ok, $description ) || $Test->diag($diag);

  return $ok;
}

#line 646

sub output_like (&$$;$$) {
  my $test        = shift;
  my $expout      = shift;
  my $experr      = shift;
  my $options     = shift if ( ref( $_[0] ) );
  my $description = shift;

  my ( $stdout, $stderr ) = output_from($test);

  my $ok = 1;

  unless (
    my $regextest = _chkregex(
      'output_like_STDERR' => $experr,
      'output_like_STDOUT' => $expout
    )
    )
  {
    return $regextest;
  }

  my $diag;
  if ( defined($experr) && defined($expout) ) {
    unless ( $stdout =~ $expout ) {
      $ok = 0;
      $diag .= "STDOUT:\n$stdout\ndoesn't match:\n$expout\nas expected";
    }
    unless ( $stderr =~ $experr ) {
      $diag .= "\n" unless ($ok);
      $ok = 0;
      $diag .= "STDERR:\n$stderr\ndoesn't match:\n$experr\nas expected";
    }
  }
  elsif ( defined($expout) ) {
    $ok = ( $stdout =~ $expout );
    $diag .= "STDOUT:\n$stdout\ndoesn't match:\n$expout\nas expected";
  }
  elsif ( defined($experr) ) {
    $ok = ( $stderr =~ $experr );
    $diag .= "STDERR:\n$stderr\ndoesn't match:\n$experr\nas expected";
  }
  else {
    unless ( $stdout eq '' ) {
      $ok = 0;
      $diag .= "STDOUT is:\n$stdout\nnot:\n\nas expected";
    }
    unless ( $stderr eq '' ) {
      $diag .= "\n" unless ($ok);
      $ok = 0;
      $diag .= "STDERR is:\n$stderr\nnot:\n\nas expected";
    }
  }

  $Test->ok( $ok, $description ) || $Test->diag($diag);

  return $ok;
}

sub output_unlike (&$$;$$) {
  my $test        = shift;
  my $expout      = shift;
  my $experr      = shift;
  my $options     = shift if ( ref( $_[0] ) );
  my $description = shift;

  my ( $stdout, $stderr ) = output_from($test);

  my $ok = 1;

  unless (
    my $regextest = _chkregex(
      'output_unlike_STDERR' => $experr,
      'output_unlike_STDOUT' => $expout
    )
    )
  {
    return $regextest;
  }

  my $diag;
  if ( defined($experr) && defined($expout) ) {
    if ( $stdout =~ $expout ) {
      $ok = 0;
      $diag .= "STDOUT:\n$stdout\nmatches:\n$expout\nnot expected";
    }
    if ( $stderr =~ $experr ) {
      $diag .= "\n" unless ($ok);
      $ok = 0;
      $diag .= "STDERR:\n$stderr\nmatches:\n$experr\nnot expected";
    }
  }
  elsif ( defined($expout) ) {
    $ok = ( $stdout !~ $expout );
    $diag .= "STDOUT:\n$stdout\nmatches:\n$expout\nnot expected";
  }
  elsif ( defined($experr) ) {
    $ok = ( $stderr !~ $experr );
    $diag .= "STDERR:\n$stderr\nmatches:\n$experr\nnot expected";
  }

  $Test->ok( $ok, $description ) || $Test->diag($diag);

  return $ok;
}

#line 803

#line 807

#line 816

sub stdout_from (&) {
  my $test = shift;

  select( ( select(STDOUT), $| = 1 )[0] );
  my $out = tie *STDOUT, 'Test::Output::Tie';

  &$test;
  my $stdout = $out->read;

  undef $out;
  untie *STDOUT;

  return $stdout;
}

#line 840

sub stderr_from (&) {
  my $test = shift;

  local $SIG{__WARN__} = sub { print STDERR @_ }
    if $] < 5.008;
  
  select( ( select(STDERR), $| = 1 )[0] );
  my $err = tie *STDERR, 'Test::Output::Tie';

  &$test;
  my $stderr = $err->read;

  undef $err;
  untie *STDERR;

  return $stderr;
}

#line 867

sub output_from (&) {
  my $test = shift;

  select( ( select(STDOUT), $| = 1 )[0] );
  select( ( select(STDERR), $| = 1 )[0] );
  my $out = tie *STDOUT, 'Test::Output::Tie';
  my $err = tie *STDERR, 'Test::Output::Tie';

  &$test;
  my $stdout = $out->read;
  my $stderr = $err->read;

  undef $out;
  undef $err;
  untie *STDOUT;
  untie *STDERR;

  return ( $stdout, $stderr );
}

#line 897

sub combined_from (&) {
  my $test = shift;

  select( ( select(STDOUT), $| = 1 )[0] );
  select( ( select(STDERR), $| = 1 )[0] );

  open( STDERR, ">&STDOUT" );

  my $out = tie *STDOUT, 'Test::Output::Tie';
  tie *STDERR, 'Test::Output::Tie', $out;

  &$test;
  my $combined = $out->read;

  undef $out;
  untie *STDOUT;
  untie *STDERR;

  return ($combined);
}

sub _chkregex {
  my %regexs = @_;

  foreach my $test ( keys(%regexs) ) {
    next unless ( defined( $regexs{$test} ) );

    my $usable_regex = $Test->maybe_regex( $regexs{$test} );
    unless ( defined($usable_regex) ) {
      my $ok = $Test->ok( 0, $test );

      $Test->diag("'$regexs{$test}' doesn't look much like a regex to me.");
#       unless $ok;

      return $ok;
    }
  }
  return 1;
}

#line 975

1;    # End of Test::Output

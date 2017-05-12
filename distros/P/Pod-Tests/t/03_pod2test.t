#!/usr/bin/perl -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
	my($class, $var) = @_;
	return bless { var => $var }, $class;
}

sub PRINT  {
	my($self) = shift;
	${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}
sub BINMODE {}

my $Original_File = 't/02_tests.t';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 95 t/02_tests.t
ok(2+2 == 4);
is( __LINE__, 96 );

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 107 t/02_tests.t

my $foo = 0;  is( __LINE__, 108 );
ok( !$foo,      'foo is false' );
ok( $foo == 0,  'foo is zero'  );


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 184 t/02_tests.t
  use File::Spec;
  is( $Original_File, File::Spec->catfile(qw(t 02_tests.t)) );


  is( __LINE__, 188, 'line in =for testing' );



  is( __LINE__, 192, 'line in =begin/end testing' );


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 117 t/02_tests.t

  # This is an example.
  2+2 == 4;
  5+5 == 10;

;

  }
};
is($@, '', "example from line 117");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 127 t/02_tests.t
  sub mygrep (&@) { }


  mygrep { $_ eq 'bar' } @stuff
;

  }
};
is($@, '', "example from line 127");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 135 t/02_tests.t

  my $result = 2 + 2;




;

  }
};
is($@, '', "example from line 135");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 135 t/02_tests.t

  my $result = 2 + 2;




  ok( $result == 4,         'addition works' );
  is( __LINE__, 142 );

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 147 t/02_tests.t

  local $^W = 1;
  print "Hello, world!\n";
  print STDERR  "Beware the Ides of March!\n";
  warn "Really, we mean it\n";




;

  }
};
is($@, '', "example from line 147");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 147 t/02_tests.t

  local $^W = 1;
  print "Hello, world!\n";
  print STDERR  "Beware the Ides of March!\n";
  warn "Really, we mean it\n";




  is( $_STDERR_, <<OUT,       '$_STDERR_' );
Beware the Ides of March!
Really, we mean it
OUT
  is( $_STDOUT_, "Hello, world!\n",                   '$_STDOUT_' );
  is( __LINE__, 161 );

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 164 t/02_tests.t

  1 + 1 == 2;

;

  }
};
is($@, '', "example from line 164");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 172 t/02_tests.t

  print "Hello again\n";
  print STDERR "Beware!\n";

;

  }
};
is($@, '', "example from line 172");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 197 t/02_tests.t

  BEGIN{binmode STDOUT};

;

  }
};
is($@, '', "example from line 197");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;


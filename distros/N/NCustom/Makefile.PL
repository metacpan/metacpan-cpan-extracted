use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'NCustom',
    'VERSION_FROM'	=> 'lib/NCustom.pm', # finds $VERSION
    'EXE_FILES'		=> ['bin/ncustom'],
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/NCustom.pm', # retrieve abstract from module
       AUTHOR     => 'Bane Harbinger <bane@baneharbinger.com>') : ()),
);

# adding this stuff to integrate Test::Inline
# and to produce html doc
{
  package MY;
  sub top_targets {
    my($self) = @_;
    my($out, $testify, $htmlify) ;

    $out = "POD2TEST_EXE = pod2test\n";
    $out .= "POD2HTML_EXE = pod2html\n";
  
    $out .= $self->SUPER::top_targets(@_);
    $out =~ s/^(pure_all\b.*)/$1 testifypods/m;
    $out =~ s/^(all\b.*)/$1 htmlifypods/m;
    $testify = join " ", (	"\n\ntestifypods : ",
    				keys %{$self->{MAN1PODS}},
				keys %{$self->{MAN3PODS}},
				"\n");
    $htmlify = join " ", (	"\n\nhtmlifypods : ",
    				keys %{$self->{MAN1PODS}},
				keys %{$self->{MAN3PODS}},
				"\n");
    foreach my $pod (keys %{$self->{MAN1PODS}}, keys %{$self->{MAN3PODS}}) {
      (my $newname = $pod) =~ s/\.(pm|pod)$//;
      $newname =~ s|/|-|g;
      $newname =~ s/^lib\W//;
      $newname =~ s/\W/-/;
      (my $test) = "embedded-$newname.t";
      (my $html) = "$newname.html" ;
      $testify .= "\t-$self->{NOECHO}\$(POD2TEST_EXE) $pod t/$test\n";
      $htmlify .= "\t-$self->{NOECHO}\$(POD2HTML_EXE) $pod > html/$html\n";
      }
    $out .= $testify ;
    $out .= $htmlify ;
    return $out;
  }
}

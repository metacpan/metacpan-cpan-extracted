
use ExtUtils::MakeMaker;
use strict;
use inc::ExtUtils::MY_Metafile;

my @MLPODFILES = qw( bin/mlpod2html.mlpod
                     bin/mlpod2pod.mlpod
                     lib/Pod/MultiLang.mlpod
                     lib/Pod/MultiLang/Dict.mlpod
                     lib/Pod/MultiLang/Dict/ja.mlpod
                     lib/Pod/MultiLang/Html.mlpod
                     lib/Pod/MultiLang/Pod.mlpod
                    );

my $pod_refresh = q{
	find lib -name '*.mlpod' |
	while read f;
	do
		d=`dirname $f`/`basename $f .mlpod`;
		perl -Ilib bin/mlpod2pod --langs=ja $d.mlpod > "${d}_ja.pod";
	done
};
$pod_refresh =~ s/\$/\$\$/g;
$pod_refresh =~ tr/\n//d;

my %ATTR = 
(
  NAME         => 'Pod::MultiLang',
  VERSION_FROM => 'lib/Pod/MultiLang.pm',
  AUTHOR        => 'YAMASHINA Hio <hio@cpan.org>',
  ABSTRACT_FROM => 'lib/Pod/MultiLang.pod',
  EXE_FILES    => [qw(bin/mlpod2html bin/mlpod2pod bin/mlpod2html.mlpod bin/mlpod2pod.mlpod)],
  PREREQ_PM => {
    'Test::More' => 0,
    'Pod::Parser' => 0,
  },
  depend       => {
                   '.SUFFIXES' => '.mlpod .pod',
                   '.mlpod.pod' => ';$(PERLRUNINST) bin/mlpod2pod $*.mlpod > $*.pod',
                   'pod-refresh' => ";$pod_refresh",
                  },
);
add_mlpodconvertion(\%ATTR,@MLPODFILES);

my_metafile 'Pod::MultiLang' => {
	license => 'perl',
	requires => {
		'Pod::Parser' => 0,
	},
	build_requires => {
		'Test::More' => 0,
	},
};

WriteMakefile(%ATTR);

# -----------------------------------------------------------------------------
# 
sub add_mlpodconvertion
{
  my $ATTR = shift;
  my $CP = '$(PERLRUNINST) -MExtUtils::Command -e cp ';
  my @clean_FILES;
  defined($ATTR->{clean}{FILES}) and push(@clean_FILES,$ATTR->{clean}{FILES});
  foreach(@MLPODFILES)
  {
    # *.mlpod           (src)
    # => *.pod          (auto gen)
    #  => $(INST)*.pod  (blib)
    #   => $(INST)*.man (blib)
    
    my $mlpod = $_;
    (my $mlpod_basename = $mlpod) =~ s/\.mlpod$//;
    
    # man section.
    my ($mannum, $pod2man, $mansect)
      = /^bin\// ? (1, 'MAN1PODS', '1')
      : /^lib\// ? (3, 'MAN3PODS', '3pm')
      :            die "category unknown [$_]"
      ;
    
    # man name.
    # bin/mlpod2pod.mlpod     => mlpod2pod
    # lib/Pod/MultiLang.mlpod => Pod::MultiLang
    my $manname = $_;
    $manname =~ s/^(bin|lib)\///;
    $manname =~ s/\.\w+$//;
    $manname =~ s/\//::/g;
    
    my $instpod_base = $mlpod_basename;
    $instpod_base =~ s/bin/\$(INST_SCRIPT)/;
    $instpod_base =~ s/lib/\$(INST_LIB)/;
    
    foreach my $lang ('', 'ja')
    {
      # lib/*.mlpod ==> lib/*.pod
			my $_lang = $lang ? "_$lang" : '';
      my $pod = "${mlpod_basename}$_lang.pod";
      my $bld = $lang ? ";\$(PERLRUNINST) bin/mlpod2pod --langs=$lang $mlpod > $pod" : '';
      $ATTR->{depend}{$pod} = $mlpod . $bld;
      
      # {bin/lib}/*.pod ==> blib/{script/lib}/*.pod
      my $instpod = "${instpod_base}$_lang.pod";
      $ATTR->{depend}{$instpod} = "$pod; $CP $pod $instpod";
      
      # blib/*.pod ==> blib/man*
      my $man = "\$(INST_MAN${mannum}DIR)/${manname}$_lang.${mansect}";
      $ATTR->{$pod2man}{$instpod} = $man;
      
      #print "\n";
      #print "$mlpod ($lang)\n";
      #print "  $mlpod ==> $pod$bld\n";
      #print "  $pod ==> $instpod\n";
      #print "  $instpod ==> $man\n";
    }
  }
  $ATTR->{clean}{FILES} = join(' ',@clean_FILES);
  $ATTR;
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------

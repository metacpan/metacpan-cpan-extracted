use strict;

use 5.008008;

BEGIN {
  eval {
    require ModPerl::MM;
    require Apache::TestMM;
  };
  if( $@ ) {
    exit 0;
  }
  Apache::TestMM->import( qw(test clean) );
}

# accept the configs from command line
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

ModPerl::MM::WriteMakefile(
    NAME            => 'ModPerl2::Tools',
    VERSION_FROM    => 'lib/ModPerl2/Tools.pm',
    ABSTRACT_FROM   => 'lib/ModPerl2/Tools.pm',
    AUTHOR          => 'Torsten Foertsch <torsten.foertsch@gmx.net>',
    PREREQ_PM       => {
        'Apache2::Const'    => 0,
        'ModPerl::MM'       => 0,
        'Apache::TestMM'    => 0,
        'Test::More'        => 0,
    },
    dist => {
        COMPRESS => 'gzip -9f',
	PREOP    => './mk_README.sh',
    },
    clean        => {
	FILES=>"t/TEST",
    },
);


sub MY::postamble {
  return <<'EOF';
rpm: dist
	$(PERL) -i -pe 's/^(Version:\s*).*/$${1}$(VERSION)/' perl-ModPerl2-Tools.spec
	rpmbuild -ba perl-ModPerl2-Tools.spec

EOF
}

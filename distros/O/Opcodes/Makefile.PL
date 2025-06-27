use strict;
use ExtUtils::MakeMaker;

if  (eval {require ExtUtils::Constant; 1}) {
  my @names =
    (qw(
	OASHIFT
	OCSHIFT
	OA_CLASS_MASK

	OA_MARK
	OA_FOLDCONST
	OA_RETSCALAR
	OA_TARGET
	OA_RETINTEGER
	OA_OTHERINT
	OA_DANGEROUS
	OA_DEFGV
	OA_TARGLEX

	OA_BASEOP
	OA_UNOP
	OA_BINOP
	OA_LOGOP
	OA_LISTOP
	OA_PMOP
	OA_SVOP
	OA_PADOP
	OA_PVOP_OR_SVOP
	OA_LOOP
	OA_COP
	OA_BASEOP_OR_UNOP
	OA_FILESTATOP
	OA_LOOPEXOP

	OA_SCALAR
	OA_LIST
	OA_AVREF
	OA_HVREF
	OA_CVREF
	OA_FILEREF
	OA_SCALARREF
	OA_OPTIONAL

        OA_NOSTACK
        OA_MAYSCALAR
        OA_MAYARRAY
        OA_MAYVOID
        OA_RETFIXED
        OA_MAYBRANCH

       ));
  ExtUtils::Constant::WriteConstants
      (NAME         => 'Opcodes',
       NAMES        => \@names,
       DEFAULT_TYPE => 'IV',
      );
}

WriteMakefile(
    NAME          => 'Opcodes',
    VERSION_FROM  => 'lib/Opcodes.pm',
    ABSTRACT_FROM => 'lib/Opcodes.pm',
    AUTHOR        => 'Reini Urban',
    LICENSE       => 'perl',
    ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
     ('META_MERGE'  => {
       resources =>
       {
	 license     => 'http://dev.perl.org/licenses/',
	 repository  => 'http://github.com/rurban/Opcodes',
       },
       prereqs => {
        develop => {
          requires => {
            'Pod::Markdown' => 0,
            'Test::CPAN::Meta' => 0,
            'Test::Pod' => 0,
            'Test::Pod::Coverage' => 0,
            'Class::XSAccessor' => 0,
            'Text::CSV_XS' => 0,
            'List::MoreUtils' => 0,
            'Test::Kwalitee' => 0,
          }
        }
       }
      }
     ) : ()),
    realclean => {FILES	=> 'const-c.inc const-xs.inc'},
    SIGN          => 1,
  );

package MY;

sub dist {
  local $_ = shift->SUPER::dist(@_);
  s/DIST_DEFAULT = /DIST_DEFAULT = README.md /;
  return $_;
}

sub depend { '
README.md : $(VERSION_FROM)
	pod2markdown $(VERSION_FROM) | \
	  $(PERL) -pe\'s/png\]\(https:/png\)\](https:/; s/(Travis|Coveralls): \[/\[!\[\1]\(/;\' > $@
release : dist
	git tag \$(VERSION)
	cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
	git push
	git push --tags
test_cover :: pure_all
	$(RM_RF) cover_db
	$(PERLRUNINST) -S cover -test
test_coveralls :: pure_all
	$(PERLRUNINST) -S cover -test -report coveralls
'; }

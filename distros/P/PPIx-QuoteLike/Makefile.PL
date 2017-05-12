use 5.006;

use strict;
use warnings;

use lib qw{ inc };

use ExtUtils::MakeMaker;
use My::Module::Meta;
use My::Module::Recommend;

(my $mmv = ExtUtils::MakeMaker->VERSION) =~ s/_//g;

my $meta = My::Module::Meta->new();

my %args = (
    NAME => 'PPIx::QuoteLike',
    VERSION_FROM => 'lib/PPIx/QuoteLike.pm',
    PREREQ_PM => $meta->requires(),
    PL_FILES => {},	# Prevent old MakeMaker from running Build.PL
    'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    AUTHOR => 'Thomas R. Wyant, III F<wyant at cpan dot org>',
    ABSTRACT => 'Parse Perl string literals and string-literal-like things.',
    realclean	=> { FILES => 'cover_db xt/author/optionals' },
);

$mmv >= 6.31
    and $args{LICENSE} = 'perl';

$mmv >= 6.4501
    and $args{META_MERGE} = $meta->meta_merge();

$mmv >= 6.4701
    and $args{MIN_PERL_VERSION} = $meta->requires_perl();

$mmv >= 6.5501
    and $args{BUILD_REQUIRES} = $meta->build_requires()
    or $mmv >= 6.4501
    and $args{META_MERGE}{build_requires} = $meta->build_requires();

My::Module::Recommend->recommend();

WriteMakefile (%args);

sub MY::postamble {
    my ( $self, @args ) = @_;

    my $authortest = $self->test_via_harness(
	'$(FULLPERLRUN)', '$(AUTHORTEST_FILES)' );
    $authortest =~ s/ \s+ \z //smx;
    $authortest =~ s/ \A \s+ //smx;
    chomp $authortest;

    return <<"EOD";

AUTHORTEST_FILES = t/*.t xt/author/*.t xt/author/optionals/*.t

authortest :: pure_all
	\$(FULLPERLRUN) "-Iinc" "-MMy::Module::Recommend" "-e" "My::Module::Recommend->make_optional_modules_tests()"
	AUTHOR_TESTING=1 $authortest

testcover :: pure_all
	cover -test -ignore_re=inc/ -ignore_re=eg/
EOD
}

# ex: set textwidth=72 :

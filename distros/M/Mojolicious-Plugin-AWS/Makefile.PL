use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Mojolicious::Plugin::AWS',
    VERSION_FROM => 'lib/Mojolicious/Plugin/AWS.pm',
    AUTHOR       => 'Scott Wiersdorf <scott@perlcode.org>',
    PREREQ_PM    => {'Mojolicious' => '8.23', 'IO::Socket::SSL' => '2.066', 'Digest::SHA' => '6.01'},
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? (LICENSE => 'perl') : ()),
    test         => {TESTS => 't/aws.t'},
    realclean    => {FILES => 'cover_db'},
);

sub MY::postamble {
    return <<'MAKE_FRAG';
test-sns: AWS_REGION        := $(shell sed '1q;d' aws-user.sns-publish-beta 2>/dev/null)
test-sns: AWS_SNS_TOPIC_ARN := $(shell sed '2q;d' aws-user.sns-publish-beta 2>/dev/null)
test-sns: AWS_ACCESS_KEY    := $(shell sed '3q;d' aws-user.sns-publish-beta 2>/dev/null)
test-sns: AWS_SECRET_KEY    := $(shell sed '4q;d' aws-user.sns-publish-beta 2>/dev/null)
test-sns:
	HARNESS_PERL_SWITCHES=$(HARNESS_PERL_SWITCHES) \
	AWS_REGION=$(AWS_REGION) AWS_SNS_TOPIC_ARN=$(AWS_SNS_TOPIC_ARN) \
	AWS_ACCESS_KEY=$(AWS_ACCESS_KEY) AWS_SECRET_KEY=$(AWS_SECRET_KEY) \
	prove -lv t/sns.t

test-s3: AWS_REGION     := $(shell sed '1q;d' aws-user.s3-writer-beta 2>/dev/null)
test-s3: AWS_S3_BUCKET  := $(shell sed '2q;d' aws-user.s3-writer-beta 2>/dev/null)
test-s3: AWS_S3_OBJECT  := $(shell sed '3q;d' aws-user.s3-writer-beta 2>/dev/null)
test-s3: AWS_ACCESS_KEY := $(shell sed '4q;d' aws-user.s3-writer-beta 2>/dev/null)
test-s3: AWS_SECRET_KEY := $(shell sed '5q;d' aws-user.s3-writer-beta 2>/dev/null)
test-s3:
	HARNESS_PERL_SWITCHES=$(HARNESS_PERL_SWITCHES) \
	AWS_REGION=$(AWS_REGION) AWS_S3_BUCKET=$(AWS_S3_BUCKET) AWS_S3_OBJECT=$(AWS_S3_OBJECT) \
	AWS_ACCESS_KEY=$(AWS_ACCESS_KEY) AWS_SECRET_KEY=$(AWS_SECRET_KEY) \
	prove -lv t/s3.t

cover: HARNESS_PERL_SWITCHES=-MDevel::Cover
cover: test-sns test-s3
	HARNESS_PERL_SWITCHES=$(HARNESS_PERL_SWITCHES) prove -lv t/aws.t
	cover -ignore_re local/ -ignore_re t/

MAKE_FRAG
}

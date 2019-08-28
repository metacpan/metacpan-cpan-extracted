use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Mojolicious::Plugin::AWS::SNS',
    VERSION_FROM => 'lib/Mojolicious/Plugin/AWS/SNS.pm',
    AUTHOR       => 'Scott Wiersdorf <scott@perlcode.org>',
    PREREQ_PM    => {'Mojolicious' => '8.23', 'IO::Socket::SSL' => '2.066'},
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? (LICENSE => 'perl') : ()),
    test         => {TESTS => 't/*.t'},
);

sub MY::postamble {
    return <<'MAKE_FRAG';
cover test-sns: AWS_REGION        := $(shell sed '1q;d' aws-credentials 2>/dev/null)
cover test-sns: AWS_SNS_TOPIC_ARN := $(shell sed '2q;d' aws-credentials 2>/dev/null)
cover test-sns: AWS_ACCESS_KEY    := $(shell sed '3q;d' aws-credentials 2>/dev/null)
cover test-sns: AWS_SECRET_KEY    := $(shell sed '4q;d' aws-credentials 2>/dev/null)

test-sns:
	AWS_REGION=$(AWS_REGION) AWS_SNS_TOPIC_ARN=$(AWS_SNS_TOPIC_ARN) \
	AWS_ACCESS_KEY=$(AWS_ACCESS_KEY) AWS_SECRET_KEY=$(AWS_SECRET_KEY) \
	prove -lv t/basic.t

cover:
	AWS_REGION=$(AWS_REGION) AWS_SNS_TOPIC_ARN=$(AWS_SNS_TOPIC_ARN) \
	AWS_ACCESS_KEY=$(AWS_ACCESS_KEY) AWS_SECRET_KEY=$(AWS_SECRET_KEY) \
	HARNESS_PERL_SWITCHES=-MDevel::Cover carton exec -- prove -lv t/basic.t
	cover -ignore_re local/ -ignore_re t/

MAKE_FRAG
}

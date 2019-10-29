package Mojolicious::Plugin::CanonicalURL::Tester;
use Mojo::Base -base;
use Test::More;
use Mojo::File 'path';

use lib path(__FILE__)->dirname->to_string;

use Mojolicious::Plugin::CanonicalURL::Tester::Captures;
use Mojolicious::Plugin::CanonicalURL::Tester::EndWithSlash;
use Mojolicious::Plugin::CanonicalURL::Tester::InlineCode;
use Mojolicious::Plugin::CanonicalURL::Tester::OnlyPathChanges;
use Mojolicious::Plugin::CanonicalURL::Tester::RemoveTrailingSlashes;
use Mojolicious::Plugin::CanonicalURL::Tester::ShouldAndShouldNotCanonicalizeRequestTogether;
use Mojolicious::Plugin::CanonicalURL::Tester::ShouldCanonicalizeRequest;
use Mojolicious::Plugin::CanonicalURL::Tester::ShouldNotCanonicalizeRequest;
use Mojolicious::Plugin::CanonicalURL::Tester::StaticFilesNotCanonicalized;
use Mojolicious::Plugin::CanonicalURL::Tester::Text;

has canonicalize_before_render => sub { die 'must set should_canonicalize_requests' };

sub test {
    my $self = shift;

    if ($self->canonicalize_before_render) {
        _test_with_args('Mojolicious::Plugin::CanonicalURL::Tester::MyApp', { canonicalize_before_render => 1 });
        _test_with_args('Mojolicious::Plugin::CanonicalURL::Tester::MyTextApp', { canonicalize_before_render => 1 });
    } else {
        # test undef for canonicalize_before_render
        _test_with_args('Mojolicious::Plugin::CanonicalURL::Tester::MyApp', { canonicalize_before_render => undef });

        # test 0 for canonicalize_before_render
        _test_with_args('Mojolicious::Plugin::CanonicalURL::Tester::MyApp', { canonicalize_before_render => 0 });

        # test default canonicalize_before_render is false
        _test_with_args('Mojolicious::Plugin::CanonicalURL::Tester::MyApp', {});
    }

    return $self;
}

sub _test_with_args {
    my @args = @_;

    Mojolicious::Plugin::CanonicalURL::Tester::Captures->new->test(@args);
    Mojolicious::Plugin::CanonicalURL::Tester::EndWithSlash->new->test(@args);
    Mojolicious::Plugin::CanonicalURL::Tester::InlineCode->new->test(@args);
    Mojolicious::Plugin::CanonicalURL::Tester::OnlyPathChanges->new->test(@args);
    Mojolicious::Plugin::CanonicalURL::Tester::RemoveTrailingSlashes->new->test(@args);
    Mojolicious::Plugin::CanonicalURL::Tester::ShouldCanonicalizeRequest->new->test(@args);
    Mojolicious::Plugin::CanonicalURL::Tester::ShouldNotCanonicalizeRequest->new->test(@args);
    Mojolicious::Plugin::CanonicalURL::Tester::ShouldAndShouldNotCanonicalizeRequestTogether->new->test(@args);
    Mojolicious::Plugin::CanonicalURL::Tester::StaticFilesNotCanonicalized->new->test(@args);
    Mojolicious::Plugin::CanonicalURL::Tester::Text->new->test(@args);
}

1;

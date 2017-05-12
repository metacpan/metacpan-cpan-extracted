FROM jmmills/dist-zilla
RUN cpanm -n Net::Proxy
RUN cpanm -n Dist::Zilla::Plugin::PodWeaver              Dist::Zilla::Plugin::Test::Compile              Dist::Zilla::Plugin::Test::Kwalitee              Dist::Zilla::Plugin::Test::Perl::Critic              Dist::Zilla::Plugin::MinimumPerl              Dist::Zilla::Plugin::MetaResourcesFromGit              Test::Pod              Test::Pod::Coverage              Test::Kwalitee              Pod::Coverage::TrustPod

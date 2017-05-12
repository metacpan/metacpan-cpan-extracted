use Mojolicious::Lite;
use Getopt::Long qw{ :config posix_default no_ignore_case gnu_compat };

my $opts = +{};
GetOptions( $opts, qw{ file=s webtailrc=s } ) or exit 1;
plugin 'Webtail', file => $opts->{file}, webtailrc => $opts->{webtailrc};

app->start;

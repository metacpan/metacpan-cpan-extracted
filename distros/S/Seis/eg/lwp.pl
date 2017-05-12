use LWP::UserAgent;

my $ua = LWP::UserAgent.new();
say $ua.get('http://google.com/').content;

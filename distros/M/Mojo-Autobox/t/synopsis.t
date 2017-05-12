use Mojo::Base -strict;
use Mojo::Autobox;

use Test::More;

open my $fh, '>', \my $output or die 'cannot open output';

{
  local *STDOUT = $fh;

  # "site.com"
  '{"html": "<a href=\"http://site.com\"></a>"}'
    ->json('/html')
    ->dom->at('a')->{href}
    ->url->host
    ->byte_stream->say;
}

is $output, "site.com\n", 'correct output';

done_testing;


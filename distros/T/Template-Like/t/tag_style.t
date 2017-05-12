use Test::More tests => 9;

BEGIN { use_ok('Template::Like') };


#    template    [% ... %]               (default)
#    template1   [% ... %] or %% ... %%  (TT version 1)
#    metatext    %% ... %%               (Text::MetaText)
#    star        [* ... *]               (TT alternate)
#    php         <? ... ?>               (PHP)
#    asp         <% ... %>               (ASP)
#    mason       <% ...  >               (HTML::Mason)
#    html        <!-- ... -->            (HTML comments)

my @options = (
  { TAG_STYLE => "asp" },
  { TAG_STYLE => "template" },
  { TAG_STYLE => "template1" },
  { TAG_STYLE => "metatext" },
  { TAG_STYLE => "star" },
  { TAG_STYLE => "php" },
  { TAG_STYLE => "mason" },
  { TAG_STYLE => "html" }
);
my @inputs = (
  "<% var %>",
  "[% var %]",
  "[% var %]%% var %%",
  "%% var %%",
  "[* var *]",
  "<? var ?>",
  "<% var  >",
  "<!-- var -->",
);
my @results = (
  "hoge",
  "hoge",
  "hogehoge",
  "hoge",
  "hoge",
  "hoge",
  "hoge",
  "hoge"
);

while ( @inputs ) {
  my $input  = shift @inputs;
  my $result = shift @results;
  my $option = shift @options;
  my $output;
  my $t = Template::Like->new($option);
  $t->process(\$input, { var => "hoge" }, \$output);
  is($result, $output, $input);
}


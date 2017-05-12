use strict;
use Test::More tests => 2;
use Template;

my $tt = Template->new;

$tt->process(\<<EOF, {}, \my $html1) or die $tt->error;
[% USE VimColor -%]
[% FILTER vimcolor -%]
#!/usr/local/bin/perl
use strict;
use warnings;

print "Hello, World!";
[%- END -%]
EOF

is(<<"EOF", $html1);
<span class="synPreProc">#!/usr/local/bin/perl</span>
<span class="synStatement">use strict</span>;
<span class="synStatement">use warnings</span>;

<span class="synStatement">print</span> <span class="synConstant">&quot;Hello, World!&quot;</span>;
EOF

$tt->process(\<<EOF, {}, \my $html2) or die $tt->error;
[% USE VimColor -%]
[% FILTER vimcolor set_number => 1 -%]
#!/usr/local/bin/perl
use strict;
use warnings;

print "Hello, World!";
[%- END -%]
EOF

is( <<"EOF", $html2 );
<span class="synLinenum">    1</span> <span class="synPreProc">#!/usr/local/bin/perl</span>
<span class="synLinenum">    2</span> <span class="synStatement">use strict</span>;
<span class="synLinenum">    3</span> <span class="synStatement">use warnings</span>;
<span class="synLinenum">    4</span> 
<span class="synLinenum">    5</span> <span class="synStatement">print</span> <span class="synConstant">&quot;Hello, World!&quot;</span>;
EOF

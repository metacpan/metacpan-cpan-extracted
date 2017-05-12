use warnings;
use strict;

use Pod::Simple::DumpAsXML ();
use Test::More tests => 2;

use_ok "Pod::Simple::FromTree";

sub ignore_wsp($) {
	my($str) = @_;
	$str =~ s/[ \t\n]+/ /g;
	return $str;
}

@FromTreeAsXML::ISA = qw(Pod::Simple::DumpAsXML Pod::Simple::FromTree);
my $p = "FromTreeAsXML"->new;
my $output = "";
$p->output_string(\$output);
$p->parse_tree([
  "Document",
  {
    "start_line" => 1
  },
  [
    "head1",
    {
      "start_line" => 1
    },
    "OH HAI"
  ],
  [
    "Para",
    {
      "start_line" => 3
    },
    "The quick brown fox jumps over the lazy dog. ",
    [
      "I",
      {},
      "Italic"
    ],
    " and ",
    [
      "B",
      {},
      "bold"
    ],
    " and ",
    [
      "I",
      {},
      [
	"B",
	{},
	"bold italic"
      ]
    ],
    " with ",
    [
      "B",
      {},
      "funny ",
      [
	"I",
	{},
	"nesting"
      ]
    ],
    "."
  ],
  [
    "Para",
    {
      "start_line" => 6
    },
    "Here comes some verbatim text:"
  ],
  [
    "Verbatim",
    {
      "xml:space" => "preserve",
      "start_line" => 8
    },
    "        Here's some stuff that looks like POD but mustn't be interpreted\n        as POD.  I<Italic> and B<bold>.\n\n        =head2 Wibble"
  ],
  [
    "head2",
    {
      "start_line" => 13
    },
    "Headings ",
    [
      "C",
      {},
      "can"
    ],
    " be ",
    "<",
    "awkward",
    ">",
    " too"
  ],
  [
    "over-bullet",
    {
      "~type" => "bullet",
      "indent" => 4,
      "start_line" => 15
    },
    [
      "item-bullet",
      {
	"~orig_content" => "*",
	"~type" => "bullet",
	"start_line" => 17
      },
      "First bulleted item."
    ],
    [
      "item-bullet",
      {
	"~orig_content" => "*",
	"~type" => "bullet",
	"start_line" => 21
      },
      "Second bulleted item, with a nested itemisation."
    ],
    [
      "over-text",
      {
	"~type" => "text",
	"indent" => 4,
	"start_line" => 25
      },
      [
	"item-text",
	{
	  "~type" => "text",
	  "start_line" => 27
	},
	"foo"
      ],
      [
	"Para",
	{
	  "start_line" => 29
	},
	"First metasyntactic variable. Often used to illustrate ",
	[
	  "C",
	  {},
	  "code"
	],
	"."
      ],
      [
	"item-text",
	{
	  "~type" => "text",
	  "start_line" => 31
	},
	"bar"
      ],
      [
	"Para",
	{
	  "start_line" => 33
	},
	"Second metasyntactic variable. Could also be used as a ",
	[
	  "F",
	  {},
	  "filename"
	],
	"."
      ]
    ]
  ],
  [
    "head1",
    {
      "start_line" => 40
    },
    "KTHXBAI"
  ],
  [
    "Para",
    {
      "start_line" => 42
    },
    "Links look like ",
    [
      "L",
      {
	"to" => bless( [
			 "",
			 {},
			 "Data::Pond"
		       ], 'Pod::Simple::LinkSection' ),
	"type" => "pod",
	"content-implicit" => "yes"
      },
      "Data::Pond"
    ],
    " or ",
    [
      "L",
      {
	"to" => bless( [
			 "",
			 {},
			 "Data::Pond"
		       ], 'Pod::Simple::LinkSection' ),
	"section" => bless( [
			      "",
			      {},
			      "DESCRIPTION"
			    ], 'Pod::Simple::LinkSection' ),
	"type" => "pod",
	"content-implicit" => "yes"
      },
      "\"",
      "DESCRIPTION",
      "\" in ",
      "Data::Pond"
    ],
    " or ",
    [
      "L",
      {
	"to" => bless( [
			 "",
			 {},
			 "Data::Pond"
		       ], 'Pod::Simple::LinkSection' ),
	"section" => bless( [
			      "",
			      {},
			      "SEE ALSO"
			    ], 'Pod::Simple::LinkSection' ),
	"type" => "pod",
	"content-implicit" => "yes"
      },
      "\"",
      "SEE ALSO",
      "\" in ",
      "Data::Pond"
    ],
    " or ",
    [
      "L",
      {
	"section" => bless( [
			      "",
			      {},
			      "KTHXBAI"
			    ], 'Pod::Simple::LinkSection' ),
	"type" => "pod",
	"content-implicit" => "yes"
      },
      "\"",
      "KTHXBAI",
      "\""
    ],
    " or ",
    [
      "L",
      {
	"section" => bless( [
			      "",
			      {},
			      "OH HAI"
			    ], 'Pod::Simple::LinkSection' ),
	"type" => "pod",
	"content-implicit" => "yes"
      },
      "\"",
      "OH HAI",
      "\""
    ],
    " or ",
    [
      "L",
      {
	"to" => bless( [
			 "",
			 {},
			 "Data::Pond"
		       ], 'Pod::Simple::LinkSection' ),
	"type" => "pod"
      },
      "misleading text"
    ],
    " or ",
    [
      "L",
      {
	"to" => bless( [
			 "",
			 {},
			 "Data::Pond"
		       ], 'Pod::Simple::LinkSection' ),
	"section" => bless( [
			      "",
			      {},
			      "DESCRIPTION"
			    ], 'Pod::Simple::LinkSection' ),
	"type" => "pod"
      },
      "misleading text"
    ],
    " or ",
    [
      "L",
      {
	"to" => bless( [
			 "",
			 {},
			 "Data::Pond"
		       ], 'Pod::Simple::LinkSection' ),
	"section" => bless( [
			      "",
			      {},
			      "SEE ALSO"
			    ], 'Pod::Simple::LinkSection' ),
	"type" => "pod"
      },
      "misleading text"
    ],
    " or ",
    [
      "L",
      {
	"section" => bless( [
			      "",
			      {},
			      "KTHXBAI"
			    ], 'Pod::Simple::LinkSection' ),
	"type" => "pod"
      },
      "misleading text"
    ],
    " or ",
    [
      "L",
      {
	"section" => bless( [
			      "",
			      {},
			      "OH HAI"
			    ], 'Pod::Simple::LinkSection' ),
	"type" => "pod"
      },
      "misleading text"
    ],
    " or ",
    [
      "L",
      {
	"to" => bless( [
			 "",
			 {},
			 "http://www.perl.org"
		       ], 'Pod::Simple::LinkSection' ),
	"type" => "url",
	"content-implicit" => "yes"
      },
      "http://www.perl.org"
    ],
    "."
  ],
  [
    "Para",
    {
      "start_line" => 55
    },
    [
      "X",
      {},
      "accent"
    ],
    " L",
    "\351",
    "on (L",
    "\351",
    "on) is not just orange but also a useful example of an accent",
    "ed word. Donald ",
    [
      "S",
      {},
      "E. Knuth"
    ],
    " is a stickler for line breaks. ",
    [
      "C",
      {},
      "<=",
      ">"
    ],
    " is a tricky operator to write about in POD."
  ]
]);
is ignore_wsp($output), ignore_wsp(<<\EOF);
<Document start_line="1">
  <head1 start_line="1">
    OH HAI
  </head1>
  <Para start_line="3">
    The quick brown fox jumps over the lazy dog. 
    <I>
      Italic
    </I>
     and 
    <B>
      bold
    </B>
     and 
    <I>
      <B>
        bold italic
      </B>
    </I>
     with 
    <B>
      funny 
      <I>
        nesting
      </I>
    </B>
    .
  </Para>
  <Para start_line="6">
    Here comes some verbatim text:
  </Para>
  <Verbatim start_line="8" xml:space="preserve">
            Here&#39;s some stuff that looks like POD but mustn&#39;t
    be interpreted
        as POD.  I&#60;Italic&#62; and B&#60;bold&#62;.

        =head2 Wibble
  </Verbatim>
  <head2 start_line="13">
    Headings 
    <C>
      can
    </C>
     be 
    &#60;
    awkward
    &#62;
     too
  </head2>
  <over-bullet indent="4" start_line="15">
    <item-bullet start_line="17">
      First bulleted item.
    </item-bullet>
    <item-bullet start_line="21">
      Second bulleted item, with a nested itemisation.
    </item-bullet>
    <over-text indent="4" start_line="25">
      <item-text start_line="27">
        foo
      </item-text>
      <Para start_line="29">
        First metasyntactic variable. Often used to illustrate 
        <C>
          code
        </C>
        .
      </Para>
      <item-text start_line="31">
        bar
      </item-text>
      <Para start_line="33">
        Second metasyntactic variable. Could also be used as a 
        <F>
          filename
        </F>
        .
      </Para>
    </over-text>
  </over-bullet>
  <head1 start_line="40">
    KTHXBAI
  </head1>
  <Para start_line="42">
    Links look like 
    <L content-implicit="yes" to="Data::Pond" type="pod">
      Data::Pond
    </L>
     or 
    <L content-implicit="yes" section="DESCRIPTION" to="Data::Pond" type="pod">
      &#34;
      DESCRIPTION
      &#34; in 
      Data::Pond
    </L>
     or 
    <L content-implicit="yes" section="SEE ALSO" to="Data::Pond" type="pod">
      &#34;
      SEE ALSO
      &#34; in 
      Data::Pond
    </L>
     or 
    <L content-implicit="yes" section="KTHXBAI" type="pod">
      &#34;
      KTHXBAI
      &#34;
    </L>
     or 
    <L content-implicit="yes" section="OH HAI" type="pod">
      &#34;
      OH HAI
      &#34;
    </L>
     or 
    <L to="Data::Pond" type="pod">
      misleading text
    </L>
     or 
    <L section="DESCRIPTION" to="Data::Pond" type="pod">
      misleading text
    </L>
     or 
    <L section="SEE ALSO" to="Data::Pond" type="pod">
      misleading text
    </L>
     or 
    <L section="KTHXBAI" type="pod">
      misleading text
    </L>
     or 
    <L section="OH HAI" type="pod">
      misleading text
    </L>
     or 
    <L content-implicit="yes" to="http://www.perl.org" type="url">
      http://www.perl.org
    </L>
    .
  </Para>
  <Para start_line="55">
    <X>
      accent
    </X>
     L
    &#233;
    on (L
    &#233;
    on) is not just orange but also a useful example of an accent
    ed word. Donald 
    <S>
      E. Knuth
    </S>
     is a stickler for line breaks. 
    <C>
      &#60;=
      &#62;
    </C>
     is a tricky operator to write about in POD.
  </Para>
</Document>
EOF

1;

#!/usr/local/bin/perl -w

require 5.004; 
use strict;
use Parse::Template;

my %template = ('DOC' => <<'END_OF_DOC;', 'SECTION_PART' => <<'END_OF_SECTION_PART;');
<HTML>
<HEAD></HEAD>
<body>
%%
my $content;
for (my $i = 0; $i <= $#section_content; $i++) {
  $content .= SECTION_PART($i);
} 
$content;
%%
</body>
</html>
END_OF_DOC;
%%
$section_content[$_[0]]->{Content} =~ s/^/<p>/mg;
join '', '<H1>', $section_content[$_[0]]->{Title}, '</H1>', 
          $section_content[$_[0]]->{Content};
%%
END_OF_SECTION_PART;

my $tmplt = new Parse::Template (%template);

$tmplt->env('section_content' => [
			 {
			  Title => 'First Section', 
			  Content => 'Nothing to write'
			 }, 
			 {
			  Title => 'Second section', 
			  Content => 'Nothing else to write'
			 }
			]
	   );

print $tmplt->eval('DOC'), "\n";

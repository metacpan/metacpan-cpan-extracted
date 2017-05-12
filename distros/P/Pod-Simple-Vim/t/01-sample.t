#!perl -T

use Test::More tests => 1;
use Test::Differences;

use Pod::Simple::Vim;

my $pod = <<ENDofPOD;

=head1 THIS IS A SAMPLE HEAD1

This is some sample text

=head2 THIS IS A SAMPLE HEAD2

  # This is some sample code
  use Pod::Simple::Vim;
	

=head3 This is a sample text list

=over

=item Test text item

=item Test text item

=back 

=head3 This is a sample bullet list

=over

=item *

Test bullet item

=item *

Test bullet item

=back 

=head3 This is a sample number list

=over

=item 1

Test number item

=item 2

Test number item

=back 

ENDofPOD

my $vim = <<ENDofVIM;
THIS IS A SAMPLE HEAD1 ~

This is some sample text

THIS IS A SAMPLE HEAD2 ~
>
  # This is some sample code
  use Pod::Simple::Vim;
        
<
 This is a sample text list ~

	Test text item

	Test text item

 This is a sample bullet list ~

  * Test bullet item

  * Test bullet item

 This is a sample number list ~

 1. Test number item

 2. Test number item


vim:nonu:ts=4:syn=perldoc:noet:lbr:bt=nofile:noma:bh=delete:noswf
ENDofVIM

chomp($vim);

my $parser = Pod::Simple::Vim->new;
  
my $output;
$parser->output_string(\$output);
$parser->parse_string_document($pod); 

eq_or_diff($output, $vim);

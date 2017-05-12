
package test;

use strict;
use warnings;
use Ravenel;
use Ravenel::Block;
use Ravenel::Document;
use Data::Dumper;

use Ravenel::Tag::Replace;

sub get_html_content {
	my $class           = shift if ( $_[0] eq 'test' );
	my $args            = shift;
	my $dynamic_content = [];
	my $content_type    = 'html';

	$dynamic_content->[0] = Ravenel::Document->scan("r:", 'html', Ravenel::Tag::Replace->render( new Ravenel::Block( { 
		'tag_arguments'    => { }, 
		'blocks_by_name'   => { 'default' => "
		<p>{a} {b} {c} {a}</p>
		<r:replace name=\"d\">
		<p>{e}</p>
		</r:replace>
	", }, 
		'arguments'        => $args, 
		'content_type'     => $content_type, 
		'format_arguments' => { },
	} ) ), undef, 'test', $args);

	my $body = <<HERE_I_AM_DONE

<html>
	$dynamic_content->[0]
</html>

HERE_I_AM_DONE
;

	chomp($body);
	return $body;
}


1;


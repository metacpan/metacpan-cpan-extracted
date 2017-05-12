package Module::AnyEvent::Helper::PPI::Transform::Test;

use strict;
use warnings;

use parent qw(PPI::Transform);

sub document
{
	my ($self, $doc) = @_;
	my $count = 0;
	my $numbers = $doc->find('PPI::Token::Number');
	foreach my $number (@$numbers) {
		my $content = $number->content;
		if(ref($number->parent->parent) ne 'PPI::Document') {
			$number->set_content($content + 1);
			++$count;
		}
	}
	return $count;
}

1;

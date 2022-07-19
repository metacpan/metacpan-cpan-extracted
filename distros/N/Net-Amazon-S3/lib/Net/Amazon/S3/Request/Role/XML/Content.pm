package Net::Amazon::S3::Request::Role::XML::Content;
# ABSTRACT: Role providing XML content
$Net::Amazon::S3::Request::Role::XML::Content::VERSION = '0.991';
use Moose::Role;

with 'Net::Amazon::S3::Request::Role::HTTP::Header::Content_length';
with 'Net::Amazon::S3::Request::Role::HTTP::Header::Content_type' => { content_type => 'application/xml' };

sub _build_xml {
	my ($self, $root_name, $root_content) = @_;

	my $ns = Net::Amazon::S3::Constants->S3_NAMESPACE_URI;

	my $xml_doc = XML::LibXML::Document->new ('1.0','UTF-8');
	my $root_element = $xml_doc->createElementNS ($ns, $root_name);
	$xml_doc->setDocumentElement ($root_element);

	my @queue = ([ $root_element, $root_content ]);
	while (my $node = shift @queue) {
		my ($parent, $content) = @$node;

		for my $tag (@$content) {
			my ($tag_name, $tag_content) = %$tag;
			my $tag_node = $parent->addNewChild ($ns, $tag_name);

			if (ref $tag_content) {
				push @queue, [$tag_node, $tag_content];
				next;
			}

			if (defined $tag_content && length $tag_content) {
				$tag_node->addChild ($xml_doc->createTextNode ($tag_content));
				next;
			}
		}
	}

	$xml_doc->toString;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::XML::Content - Role providing XML content

=head1 VERSION

version 0.991

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

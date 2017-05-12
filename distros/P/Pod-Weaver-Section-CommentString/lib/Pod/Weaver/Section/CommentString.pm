package Pod::Weaver::Section::CommentString 0.01;
# ABSTRACT: Add Pod::Weaver section with content extracted from comment with specified keyword
$Pod::Weaver::Section::CommentString::VERSION = '0.01';

use strict;
use warnings;

use Moose;

with 'Pod::Weaver::Role::Section';
with 'Pod::Weaver::Role::StringFromComment';

use aliased 'Pod::Elemental::Element::Nested';
use aliased 'Pod::Elemental::Element::Pod5::Command';

# All attributes are private only
has comment => (
	is 	=> 'ro',
	isa	=> 'Str',
	default => 'KEYWORD',
);

has header => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	required => 1,
	default => sub { $_[0]->plugin_name },
);

has extra_args => (
	is	=> 'rw',
	isa	=> 'HashRef',
);

sub BUILD {
    my $self = shift;
    my ($args) = @_;
    my $copy = {%$args};
    delete $copy->{$_}
        for map { $_->init_arg } $self->meta->get_all_attributes;
    $self->extra_args($copy);
}

sub _get_comment {
	my ( $self, $input ) = @_;

	my $keyword = $self->comment;

	my $comment = $self->_extract_comment_content( $input->{ppi_document}, $keyword );
	
	return $comment if $comment;
	
	( $comment ) = $input->{ppi_document}->serialize =~ /^\s*#+\s*$keyword:\s*(.+)$/m;
	
	return $comment;
}

# This is implicit method of plugin for extending Pod::Weaver, cannot be called directly
sub weave_section {
    my ( $self, $doc, $input ) = @_;

    my $filename = $input->{filename};

	my $comment = $self->_get_comment( $input );
	
	my $keyword = $self->comment;
	
	$self->log([ "couldn't find comment $keyword in %s", $filename ]) unless $comment;

    push @{ $doc->children },
		Nested->new( {
            type     => 'command',
            command  => 'head1',
            content  => $self->header,
            children => [
				Pod::Elemental::Element::Pod5::Ordinary->new( { content => $comment } )
			]
        } );
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::CommentString - Add Pod::Weaver section with content extracted from comment with specified keyword

=head1 VERSION

version 0.01

=head1 SYNOPSIS

In your C<weaver.ini>:

	[CommentString / SECTIONNAME]
	header = SECTIONNAME
	comment = KEYWORD

=head1 DESCRIPTION

This L<Pod::Weaver> section plugin creates a "SECTIONNAME" section in your POD
which contains a string extracted from selected keyword in your comments (like ABSTRACT for Name).

=head1 SEE ALSO

L<Pod::Weaver::Section::Name> 

=head1 AUTHOR

Milan Sorm <sorm@is4u.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Milan Sorm.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

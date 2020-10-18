use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::JacquardCanvas::Role::MousePageTooltip;
# ABSTRACT: Role for tooltip on hover
$Renard::Curie::Component::JacquardCanvas::Role::MousePageTooltip::VERSION = '0.005';
use Role::Tiny;
use Glib qw(TRUE FALSE);

after do_pointer_data => sub {
	my ($self, $event_point, $pointer_data, $text_data ) = @_;

	my @intersects = @{ $pointer_data->{intersects} };
	my @pages = @{ $pointer_data->{pages} };
	my $point = $pointer_data->{point};

	if( @pages) {
		$self->set_tooltip_text("@pages");
	} else {
		$self->set_has_tooltip(FALSE);
	}

	return TRUE;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::JacquardCanvas::Role::MousePageTooltip - Role for tooltip on hover

=head1 VERSION

version 0.005

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

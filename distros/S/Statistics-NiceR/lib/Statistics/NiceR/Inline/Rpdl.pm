package Statistics::NiceR::Inline::Rpdl;
$Statistics::NiceR::Inline::Rpdl::VERSION = '0.03';
use strict;
use warnings;
use PDL::LiteF;
use PDL::Core::Dev;

sub Inline {
	return unless $_[-1] eq 'C';
	+{
		INC           => &PDL_INCLUDE,
		TYPEMAPS      => &PDL_TYPEMAP,
		AUTO_INCLUDE  => &PDL_AUTO_INCLUDE('PDL'), # declarations
		BOOT          => &PDL_BOOT('PDL'),         # code for the XS boot section
	};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::NiceR::Inline::Rpdl

=head1 VERSION

version 0.03

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

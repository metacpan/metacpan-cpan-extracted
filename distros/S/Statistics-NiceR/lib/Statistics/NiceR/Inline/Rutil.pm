package Statistics::NiceR::Inline::Rutil;
$Statistics::NiceR::Inline::Rutil::VERSION = '0.03';
use strict;
use warnings;
use File::Basename;
use File::Spec;

sub Inline {
	return unless $_[-1] eq 'C';
	my $dir = File::Spec->rel2abs( dirname(__FILE__) );
	+{
		INC => "-I$dir",
		TYPEMAPS => File::Spec->catfile( $dir, 'typemap' ),
	};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::NiceR::Inline::Rutil

=head1 VERSION

version 0.03

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

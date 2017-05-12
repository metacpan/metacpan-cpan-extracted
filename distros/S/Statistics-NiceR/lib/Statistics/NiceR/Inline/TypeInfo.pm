package Statistics::NiceR::Inline::TypeInfo;
$Statistics::NiceR::Inline::TypeInfo::VERSION = '0.03';
use strict;
use warnings;
use Storable;

my $info = {
	CHARSXP => { sexptype => 'CHARSXP', r_macro => 'CHARACTER',                      },
	INTSXP =>  { sexptype => 'INTSXP',  r_macro => 'INTEGER',   r_NA => 'NA_INTEGER' },
	REALSXP => { sexptype => 'REALSXP', r_macro => 'REAL',      r_NA => 'NA_REAL'    },
};
# NA_REAL, NA_INTEGER, NA_LOGICAL, NA_STRING
#
# NA_COMPLEX, NA_CHARACTER?

sub get_type_info {
	my ($klass, $type ) = @_;
	# make a copy of hash so that changes made by callers do not affect our data
	return Storable::dclone( $info->{$type} );
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::NiceR::Inline::TypeInfo

=head1 VERSION

version 0.03

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

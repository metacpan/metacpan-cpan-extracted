use v5.012;
use strict;
use warnings;

package Missing::XS;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';

use constant { true => !!1, false => !!0 };

use Module::Runtime qw( module_notional_filename require_module );

our $CPANM = false;
our @RECOMMENDATIONS;
sub import {
	my $class = shift;
	$CPANM = !! ( "@_" =~ /cpanm/i );
}

our @CHECKS = (
	sub { shift->basic_check_or_warning( 'Class::C3' ) },
	sub { shift->basic_check_or_warning( 'Class::Load' ) },
	sub { shift->basic_check_or_warning( 'Date::Calc' ) },
	sub { shift->basic_check_or_warning( 'Directory::Iterator' ) },
	sub { shift->basic_check_or_warning( 'Heap::Simple' ) },
	sub { shift->basic_check_or_warning( 'JSON' ) },
	sub { shift->basic_check_or_warning( 'JSON::MaybeXS', 'Cpanel::JSON::XS' ) },
	sub { shift->basic_check_or_warning( 'List::MoreUtils' ) },
	sub { shift->basic_check_or_warning( 'List::SomeUtils' ) },
	sub { shift->basic_check_or_warning( 'match::simple' ) },
	sub { shift->basic_check_or_warning( 'Moo', 'Class::XSAccessor' ) },
	sub {
		my $class = shift;
		return true if !$INC{'Mouse/Util.pm'};
		Mouse::Util::MOUSE_XS()
			or warn "Mouse is installed without its XS backend.\n";
	},
	sub { shift->basic_check_or_warning( 'Object::Accessor' ) },
	sub { shift->basic_check_or_warning( 'Object::Adhoc', 'Class::XSAccessor' ) },
	sub { shift->basic_check_or_warning( 'Package::Stash' ) },
	sub { shift->basic_check_or_warning( 'Params::Validate' ) },
	sub { shift->basic_check_or_warning( 'PerlX::ArraySkip' ) },
	sub { shift->basic_check_or_warning( 'PerlX::Maybe' ) },
	sub { shift->basic_check_or_warning( 'PPI' ) },
	sub { shift->basic_check_or_warning( 'Readonly' ) },
	sub { shift->basic_check_or_warning( 'Ref::Util' ) },
	sub { shift->basic_check_or_warning( 'Set::Product' ) },
	sub { shift->basic_check_or_warning( 'String::Numeric' ) },
	sub { shift->basic_check_or_warning( 'Text::CSV', 'Text::CSV_XS' ) },
	sub { shift->basic_check_or_warning( 'Time::Format', 'Time::Format_XS' ) },
	sub { shift->basic_check_or_warning( 'Type::Params', 'Class::XSAccessor' ) },
	sub { shift->basic_check_or_warning( 'Type::Tiny' ) },
	sub { shift->basic_check_or_warning( 'URL::Encode' ) },
);

sub all_checks {
	my $class = shift;
	for my $check ( @CHECKS ) {
		$class->$check;
	}
	if ( $CPANM and @RECOMMENDATIONS ) {
		warn "\n";
		warn "You may wish to run:\n";
		warn qq|cpanm @{[ map qq{"$_"}, @RECOMMENDATIONS ]}\n|;
	}
}

sub basic_check_or_warning {
	my ( $class, $frontend, $xs_backend ) = ( shift, @_ );
	$xs_backend //= "$frontend\::XS";
	$class->basic_check( $frontend, $xs_backend )
		or $class->basic_warning( $frontend, $xs_backend );
}

sub basic_check {
	my ( $class, $frontend, $xs_backend ) = ( shift, @_ );
	
	# If this module is not being used at all, everything is okay.
	my $frontend_filename = module_notional_filename( $frontend );
	return true if !$INC{$frontend_filename};
	
	return !!eval { require_module($xs_backend) };
}

sub basic_warning {
	my ( $class, $frontend, $xs_backend ) = ( shift, @_ );
	warn sprintf( "%s loaded but %s is not available.\n", $frontend, $xs_backend );
	push @RECOMMENDATIONS, $xs_backend;
}

END {
	__PACKAGE__->all_checks unless $ENV{PERL_MISSING_XS_NO_END};
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Missing::XS - print warnings about XS modules you should probably install

=head1 SYNOPSIS

  perl -Missing::XS "path/to/your/script.pl"

=head1 DESCRIPTION

This module provides an C<< END {} >> block which will run I<after> your
script and print warnings about modules your script used which are being
forced to use their pure Perl backend instead of a faster XS backend which
is available on CPAN.

For example, if your script loads L<Package::Stash> but you don't have
L<Package::Stash::XS> installed, then you will see a warning.

The following will provide a quick copy-and-paste command for installing the
missing XS modules with C<cpanm>:

  perl -Missing::XS=cpanm "path/to/your/script.pl"

=head1 ENVIRONMENT

The C<PERL_MISSING_XS_NO_END> environment variable suppresses the printing
of the warnings in the C<< END {} >> block.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-missing-xs/issues>.

=head1 SEE ALSO

L<Acme::CPANModules::XSVersions>: I stole some data from here.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

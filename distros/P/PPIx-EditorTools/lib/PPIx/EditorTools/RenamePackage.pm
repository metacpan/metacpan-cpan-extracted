package PPIx::EditorTools::RenamePackage;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Change the package name
$PPIx::EditorTools::RenamePackage::VERSION = '0.20';
use strict;

BEGIN {
	$^W = 1;
}
use base 'PPIx::EditorTools';

use Class::XSAccessor accessors => { 'replacement' => 'replacement' };

use PPI;
use Carp;


sub rename {
	my ( $self, %args ) = @_;
	$self->process_doc(%args);
	my $replacement = $args{replacement} || croak "replacement required";

	my $doc = $self->ppi;

	# TODO: support MooseX::Declare
	my $package = $doc->find_first('PPI::Statement::Package')
		or die "no package found";
	my $namespace = $package->schild(1) or croak "package name not found";
	$namespace->isa('PPI::Token::Word') or croak "package name not found";
	$namespace->{content} = $replacement;

	return PPIx::EditorTools::ReturnObject->new(
		ppi     => $doc,
		element => $package
	);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PPIx::EditorTools::RenamePackage - Change the package name

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    my $munged = PPIx::EditorTools::RenamePackage->new->rename(
        code        => <<'END_CODE',
            package TestPackage;
            use strict;

            BEGIN { $^W = 1; }
            1;
    END_CODE
        replacement => 'NewPackage'
    );

    my $new_code_as_string = $munged->code;
    my $package_ppi_element = $munged->element;

=head1 DESCRIPTION

This module uses PPI to change the package name of code.

=head1 METHODS

=over 4

=item new()

Constructor. Generally shouldn't be called with any arguments.

=item rename( ppi => PPI::Document $ppi, replacement => Str )

=item rename( code => Str $code, replacement => Str )

Accepts either a C<PPI::Document> to process or a string containing
the code (which will be converted into a C<PPI::Document>) to process.
Replaces the package name with that supplied in the C<replacement>
parameter and returns a C<PPIx::EditorTools::ReturnObject> with the
new code available via the C<ppi> or C<code> accessors, as a
C<PPI::Document> or C<string>, respectively.

Croaks with a "package name not found" exception if unable to find the
package name.

=back

=head1 SEE ALSO

This class inherits from C<PPIx::EditorTools>.
Also see L<App::EditorTools>, L<Padre>, and L<PPI>.

=head1 AUTHORS

=over 4

=item *

Steffen Mueller C<smueller@cpan.org>

=item *

Mark Grimes C<mgrimes@cpan.org>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=item *

Gabor Szabo  <gabor@szabgab.com>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2014, 2012 by The Padre development team as listed in Padre.pm..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

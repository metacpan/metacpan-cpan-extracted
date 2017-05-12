package MooseX::ClosedHash;

use 5.008;

BEGIN {
	$MooseX::ClosedHash::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::ClosedHash::VERSION   = '0.003';
}

use Moose ();
use Moose::Exporter;
use Moose::Util::MetaRole;
use MooseX::ClosedHash::Meta::Instance ();
use MooseX::ClosedHash::Meta::Class ();

Moose::Exporter->setup_import_methods(
	also => [qw( Moose )],
);

sub init_meta
{
	shift;
	my %p = @_;
	Moose->init_meta(%p);
	Moose::Util::MetaRole::apply_metaroles(
		for             => $p{for_class},
		class_metaroles => {
			instance => [qw( MooseX::ClosedHash::Meta::Instance )],
			class    => [qw( MooseX::ClosedHash::Meta::Class )],
		},
	);
}

[qw( Yeah baby yeah )];

__END__

=pod

=encoding utf-8

=head1 NAME

MooseX::ClosedHash - blessed coderefs (closing over a hash) with Moose

=head1 SYNOPSIS

   use v5.14;
   
   package Person {
      use MooseX::ClosedHash;
      has name => (is => "rw");
      has age  => (is => "rw");
      __PACKAGE__->meta->make_immutable;
   }
   
   my $bob = Person->new(name => "Bob", age => 42);
   
   say $bob->name, " is ", $bob->age, " years old.";
   say $bob->dump;

=head1 DESCRIPTION

L<MooseX::ClosedHash> is a Moose module that lets you store your object's
attributes in a hash, closed over by a blessed coderef.

Why? I have no idea why you'd want to do this.

It provides a modicum of privacy I suppose. Privacy that is easily violated,
but that you're unlikely to accidentally violate.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-ClosedHash>.

=head1 SEE ALSO

L<http://www.perlmonks.org/?node_id=1039960>.

L<MooseX::ArrayRef>, L<MooseX::GlobRef>, L<MooseX::InsideOut>, etc.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


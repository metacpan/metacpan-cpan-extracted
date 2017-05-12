package MooseX::DeclareX::Keyword::interface;

{
	package # hide
	MooseX::DeclareX::Keyword::interface::SupportsTestCases;
	use Moose::Role;
}

BEGIN {
	$MooseX::DeclareX::Keyword::interface::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Keyword::interface::VERSION   = '0.004';
}

require MooseX::Declare;
require MooseX::Interface;

use Moose;
with qw(
	MooseX::Declare::Syntax::MooseSetup
	MooseX::Declare::Syntax::Extending
	MooseX::DeclareX::Plugin
	MooseX::DeclareX::Registry
	MooseX::DeclareX::Keyword::interface::SupportsTestCases
);

around import_symbols_from => sub { 'MooseX::Interface' };
around imported_moose_symbols => sub { qw( requires excludes extends const ) };

sub preferred_identifier { 'interface' }

before add_namespace_customizations => sub {
	my ($self, $ctx) = @_;
	$_->setup_for($ctx->namespace, provided_by => ref $self)
		foreach @{ $self->default_inner };
};

"Are you using Java?!"

__END__

=head1 NAME

MooseX::DeclareX::Keyword::interface - shiny syntax for MooseX::Interface

=head1 SYNOPSIS

  use MooseX::DeclareX
    keywords => [qw/ class interface /],
    plugins  => [qw/ guard build test_case /];
  
  interface BankAccountAPI
  {
    requires 'deposit';
    requires 'withdraw';
    requires 'balance';
    test_case numeric_balance {
      Scalar::Util::looks_like_number( $_->balance )
    }
  }
  
  class BankAccount with BankAccountAPI
  {
    has owner => (
      is       => 'ro',
      isa      => 'Str',
      required => 1,
    );
    has balance => (
      traits   => ['Number'],
      is       => 'rw',
      isa      => 'Num',
      handles  => {
        deposit   => 'add',
        withdraw  => 'sub',
      },
    );
    build balance { 0 }
    guard withdraw ($amt) {
      confess "insufficient funds" unless $self->balance >= $amt
    }
  }
  
  interface DDBankAccountAPI extends BankAccountAPI
  {
    requires 'setup_direct_debit';
    requires 'pay_direct_debit';
  }
  
  BankAccountAPI->meta->test_implementation( BankAccount->new );

=head1 DESCRIPTION

This distribution adds a new keyword and a new plugin to L<MooseX::DeclareX>.

=over

=item C<< interface >>

Defines an interface. An interface is much like a role, but with some heavy
restrictions - it can't define any methods (just require implementing classes
to define them), and it can only extend other interfaces, not roles. See
L<MooseX::Interface> for details.

=item C<< test_case >>

Sets up test cases for an interface.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-DeclareX-Keyword-interface>.

=head1 SEE ALSO

L<MooseX::DeclareX>, L<MooseX::Interface>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


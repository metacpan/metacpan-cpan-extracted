package Perl::Critic::Policy::Dancer2::ReturnNotNecessary;

our $VERSION = '0.4100'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY
# ABSTRACT: Trigger perlcritic alerts on needless return statements
use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{
    :booleans :characters :severities :classification :data_conversion
};
use Perl::Critic::Utils::PPI qw{ is_ppi_expression_or_generic_statement };
use base 'Perl::Critic::Policy';

sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes   { return qw( dancer2 ) }
sub applies_to       { return 'PPI::Token::Word' }

Readonly::Array my @implicit_returns => qw/
    forward
    halt
    pass
    redirect
    send_as
    send_error
    send_file/;

Readonly::Scalar my $EXPL =>
    'Certain keywords will immediately end a route, and do not need a return statement.';

sub violates {
   my ( $self, $elem, $doc ) = @_;

   return if is_hash_key($elem);
   return if is_method_call($elem);
   return if is_subroutine_name($elem);
   return if is_included_module_name($elem);
   return if is_package_declaration($elem);
   
   my $included = $doc->find_any(
      sub {
         $_[1]->isa('PPI::Statement::Include')
             and defined( $_[1]->module() )
             and ( $_[1]->module() eq 'Dancer2' )
             and $_[1]->type() eq 'use';
      }
   );
   return if !$included;
   if ( grep { $_ eq $elem} @implicit_returns ) {
      my $stmnt = $elem->statement();
      if ($stmnt =~ /^return $elem/){
         return $self->violation( "Don't need return before $elem", $EXPL, $elem );
      }
   }
   return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Dancer2::ReturnNotNecessary - Trigger perlcritic alerts on needless return statements

=head1 VERSION

version 0.4100

=head1 DESCRIPTION

Certain L<Dancer2> keywords immediately end execution of a route; specifically, using 
C<forward>, C<halt>, C<pass>, C<redirect>, C<send_as>, C<send_error>, or C<send_file>,
do not require a C<return> before them, as they do so implicitly.

=cut

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Dancer2>.

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Perl::Critic::Policy::Plicease::ProhibitLeadingZeros;

use strict;
use warnings;
use 5.010001;
use Perl::Critic::Utils;
use base qw( Perl::Critic::Policy );

# ABSTRACT: Leading zeroes are okay as the first arg to chmod, and other such reasonableness
our $VERSION = '0.06'; # VERSION


my $DESCRIPTION = q{Integer with leading zeros outside of chmod, mkpath};
my $EXPLANATION = "Only use leading zeros on numbers indicating file modes";

sub default_severity { $SEVERITY_MEDIUM     }
sub default_themes   { ()                   }
sub applies_to       { 'PPI::Token::Number' }

sub violates
{
  my($self, $element, undef) = @_;

  return unless $element =~ m/\A [+-]? (?: 0+ _* )+ [1-9]/mx;
  return if $element->sprevious_sibling eq 'chmod';
  return if (eval { $element->sprevious_sibling->sprevious_sibling->sprevious_sibling->sprevious_sibling->sprevious_sibling }||'') eq 'mkpath';

  my $working = eval { $element->parent->parent };
  if($element->parent->isa('PPI::Statement::Expression'))
  {
    my $working = $element->parent->parent;
    while(eval { $working->isa('PPI::Structure::List') })
    {
      $working = $working->parent;
    }
    return if $working and ($working->children)[0] eq 'chmod';
    return if $working and ($working->children)[-3] eq 'mkpath';
  }

  return $self->violation($DESCRIPTION, $EXPLANATION, $element);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Plicease::ProhibitLeadingZeros - Leading zeroes are okay as the first arg to chmod, and other such reasonableness

=head1 VERSION

version 0.06

=head1 SYNOPSIS

perlcriticrc:

 [Plicease::ProhibitLeadingZeros]

code:

 0123;               # not ok
 1234;               # ok
 chmod 0700;         # ok
 mkpath($foo, 0700); # ok

=head1 DESCRIPTION

Perl interprets numbers with leading zeros as octal. If that's what you really want, its
better to use C<oct> and make it obvious.  However, some operations are well known as using
octal such as C<chmod> and C<mkpath> so this policy disallows mistakes like this:

 my $x = 1231;
 my $y = 2345;
 my $z = 0032;

But not non-mistakes like this:

 chmod 0700, "secret_file.txt";

or this:

 use File::Path qw( mkpath );
 
 mkpath("/foo/bar/baz", 1, 0700);

or is this:

 use Path::Class qw( dir );
 
 dir()->mkpath(1,0700);

=head1 AFFILIATION

None.

=head1 CONFIGURATION

This policy is not configurable except for the standard options.

=head1 CAVEATS

Because C<mkpath> is not a built in (as C<chmod> is), this policy does not differentiate between the
C<mkpath> function provided by L<File::Path> or the C<mkpath> method provided by L<Path::Class::Dir>
and arbitrary C<mkpath> function or methods that you or someone else might define.  Also, there is
no way to really check if the object invocant of a C<mkpath> method is really an instance of
L<Path::Class::Dir>.

=head1 SEE ALSO

This policy is based largely on the existing in-core policy, and one in the lax bundle, but adds a
few exceptions that I find useful.

=over 4

=item L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitLeadingZeros>

=item L<Perl::Critic::Policy::Lax::ProhibitLeadingZeros::ExceptChmod>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ville Skyttä (SCOP)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Perl::Critic::Policy::Subroutines::ProhibitQualifiedSubDeclarations;

use strict;
use warnings;
use base 'Perl::Critic::Policy';

use Perl::Critic::Utils qw( :severities &is_qualified_name );

#-----------------------------------------------------------------------------

our $VERSION = 0.06;

#-----------------------------------------------------------------------------

sub supported_parameters { return }
sub default_severity     { return $SEVERITY_MEDIUM          }
sub default_themes       { return qw( strictersubs bugs )   }
sub applies_to           { return 'PPI::Statement::Sub'     }

#-----------------------------------------------------------------------------

my $desc = q{Subroutine declared with a qualified name};
my $expl = q{Remove package name from sub declaration};

#-----------------------------------------------------------------------------

sub violates {

    my ($self, $elem, undef) = @_;

    if ( is_qualified_name( $elem->name() ) ) {
        return $self->violation( $desc, $expl, $elem );
    }

    return;  #ok!
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitQualifiedSubDeclarations

=head1 AFFILIATION

This policy is part of L<Perl::Critic::StricterSubs|Perl::Critic::StricterSubs>.

=head1 DESCRIPTION

Perl permits you to declare subroutines into any package that you
want.  This can be downright dangerous if that package is already
defined elsewhere.

  package Foo;

  sub Bar::frobulate {}  #not ok
  sub frobulate {}       #ok

Even if you declare a subroutine into the current package, using
a fully-qualified name is just weird.

  package  Foo;

  sub Foo::frobulate {} #not ok
  sub frobulate {}      #ok

So this Policy catches any subroutine declaration that contains "::"
in the subroutine's name.

=head1 CAVEATS

Overriding subroutines in other packages is a common testing
technique.  So you may want to disable this policy when critiquing
test scripts.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007 Jeffrey Ryan Thalhammer.  All rights reserved.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :

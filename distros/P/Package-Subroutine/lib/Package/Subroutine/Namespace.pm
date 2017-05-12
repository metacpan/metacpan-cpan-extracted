  package Package::Subroutine::Namespace
# **************************************
; our $VERSION='0.01'
# *******************
; use strict ('vars','subs')
; use warnings

; use Perl6::Junction ()

; sub list_childs
    { my ($self,$package) = @_
    ; map { s/::$// ; $_ }
      grep { /::$/ } keys %{"${package}::"}
    }

; sub delete_childs
    { my ($self,$package,@keep) = @_
    ; for my $chld ($self->list_childs($package))
        { next if $chld eq Perl6::Junction::any(@keep)
        ; delete ${"${package}::"}{"${chld}::"}
        }
    }

; 1

__END__

=head1 NAME

Package::Subroutine::Namespace - naive namespace utilities

=head1 SYNOPSIS

  use Package::Subroutine::Namespace;

  # shortcut
  my $ns = bless \my $v, 'Package::Subroutine::Namespace';

  print "$_\n" for $ns->list_childs('Package::Subroutine');
  # should print at least: Namespace

  $ns->delete_childs('Package::Subroutine','Namespace');
  # deletes sub namespaces, but keeps the Namespace module intact

=head1 DESCRIPTION

=head2 list_childs

Class method to list all child namespaces for a given namespace.

=head2 delete_childs

Deletes sub namespaces from a namespace, takes an optional
list namespace names which are saved from extinction.

Removing is done simply with builtin delete function.

=head1 AUTHOR

Sebastian Knapp

=head1 LICENSE

Perl has a free license, so this module shares it with this
programming language.

Copyleft 2006-2009 by Sebastian Knapp E<lt>rock@ccls-online.deE<gt>

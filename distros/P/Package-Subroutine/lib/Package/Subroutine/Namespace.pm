  package Package::Subroutine::Namespace;
# ***************************************
  use strict; use warnings;
  our $VERSION='0.10';
# ********************

; use Carp ()
; use Perl6::Junction ()

; our $ROOT = \%::
; our %namespace

; sub list_namespaces
    { my ($self,$package) = @_
    ; local %namespace = %$ROOT
    ; $package =~ s/::$//
    ; my @path = split /::/, $package
    ; while(my $pkg = shift @path)
        { if(exists $namespace{"${pkg}::"})
            { %namespace = %{$namespace{$pkg."::"}}
            }
          else
            { Carp::carp("Package \"$package\" not available.")
            ; return ()
            }
        }
    ; map { s/::$// ; $_ } ## no critic
      grep { /::$/ } keys %namespace
    }

; sub delete_namespaces
    { my ($self,$package,@keep) = @_
    ; $package =~ s/::$//
    ; my @path = split /::/, $package
    ; my @children = $self->list_namespaces($package)
    ; my $namespace = $ROOT
    ; while(my $pkg = shift @path)
        { if(exists $namespace->{"${pkg}::"})
            { $namespace = \%{$namespace->{"${pkg}::"}}
            }
          else
            { Carp::carp("Package \"$package\" not found.")
            ; return
            }
        } 
    ; for my $chld (@children)
        { next if $chld eq Perl6::Junction::any(@keep)
        ; delete $namespace->{"${chld}::"}
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

  print "$_\n" for $ns->list_namespaces('Package::Subroutine');
  # should print at least: Namespace

  $ns->delete_namespaces('Package::Subroutine','Namespace');
  # deletes sub namespaces, but keeps the Namespace module intact

=head1 DESCRIPTION

=head2 list_namespaces

Class method to list all namespaces in a given package.

=head2 delete_namespaces

Deletes sub namespaces from a namespace, takes an optional
list with namespace child names which are saved from extinction.

Removing is done simply with builtin delete function.

=head1 AUTHOR

Sebastian Knapp

=head1 LICENSE

Perl has a free license, so this module shares it with this
programming language.

Copyleft 2006-2009,2025 by Sebastian Knapp E<lt>sknpp@cpan.orgE<gt>

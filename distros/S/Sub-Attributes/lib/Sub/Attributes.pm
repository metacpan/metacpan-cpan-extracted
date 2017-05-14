package Sub::Attributes;
use strict;
use warnings;

# voodoo
no strict 'refs';
no warnings qw(reserved redefine);

use B 'svref_2object';
use Carp 'croak';

BEGIN { our $VERSION = 0.04 }

# these data structures are key to this module. They're created in a BEGIN block
# as package variables so they're available when MODIFY_CODE_ATTRIBUTES is
# called:
#
#   %attributes is a hash of subroutine names and their attributes
#   %allowed is a hash of recognized subroutine attributes with a coderef for
#   the behavior
#
# You can relace/extend %allowed in an inherited class to provide your own behavior!
BEGIN {
  our %allowed = (
    # runtime check that caller is the package
    Private => sub {
      my ($package) = @_;
      return sub {
        my ($coderef, @args) = @_;
        my ($package_caller, $filename, $line, $sub) = caller(2);
        croak 'Only the object may call this sub' unless $sub && $sub =~ /^$package\:\:/;
        $coderef->(@args);
      };
    },
    # runtime check that the first arg is the package
    ClassMethod => sub {
      return sub {
        my ($coderef, @args) = @_;
        croak 'Class method called as function / object method'
          unless $args[0] && exists $Sub::Attributes::attributes{ $args[0] };
        $coderef->(@args);
      };
    },
    # runtime check that the first arg is the object
    Method => sub {
      return sub {
        my ($coderef, @args) = @_;
        croak 'Method called as function'
          unless $args[0] && exists $Sub::Attributes::attributes{ ref $args[0] };
        $coderef->(@args);
      };
    },
    # compile time override, run a coderef before running the subroutine
    Before => sub {
      my ($package, $value, $coderef) = @_;

      # full name of the sub to override
      my $fq_sub = "$package:\:$value";

      my $target_coderef = \&{$fq_sub};
      *{$fq_sub} = sub {
        $coderef->(@_);
        $target_coderef->(@_);
      };

      # we didn't change the method with the attribute
      # so we return undef as we have no runtime changes
      return undef;
    },
    # compile time override, run a coderef after running the subroutine
    After => sub {
      my ($package, $value, $coderef) = @_;

      # full name of the sub to override
      my $fq_sub = "$package:\:$value";

      my $target_coderef = \&{$fq_sub};
      *{$fq_sub} = sub {
        my @rv = $target_coderef->(@_);
        $coderef->(@_);
        return wantarray ? @rv : $rv[0];
      };

      # we didn't change the method with the attribute
      # so we return undef as we have no runtime changes
      return undef;
    },
    # compile time override, run a coderef around running the subroutine
    Around => sub {
      my ($package, $value, $coderef) = @_;

      # full name of the sub to override
      my $fq_sub = "$package:\:\$value";

      my $target_coderef = \&{$fq_sub};
      *{$fq_sub} = sub {
        $coderef->($target_coderef, @_);
      };

      # we didn't change the method with the attribute
      # so we return undef as we have no runtime changes
      return undef;
    },
  );
}

# this is the registrar for subroutine attributes called at compile time
sub MODIFY_CODE_ATTRIBUTES {
  my ($package, $coderef, @attributes, @disallowed) = @_;

  my $obj = svref_2object($coderef);
  my $subroutine = $obj->GV->NAME;

  for my $attribute (@attributes) {
    # parse the attribute into name and value
    my ($name, $value) = $attribute =~ qr/^ (\w+) (?:\((\S+?)\))? $/x;
    my $overrider = $Sub::Attributes::allowed{$name};

    # attribute not known, compile error
    push(@disallowed, $name) && next unless $overrider;

    # make compile time changes, skip ahead if no runtime changes
    my $override_coderef = $overrider->($package, $value, $coderef);
    next unless $override_coderef;

    # override subroutine with attribute coderef
    my $old_coderef = $coderef;
    $coderef = sub { $override_coderef->($old_coderef, @_) };
    *{"$package:\:$subroutine"} = $coderef;
  }

  $Sub::Attributes::attributes{$package}{ $subroutine } = \@attributes;
  return @disallowed;
};

sub sub_attributes {
  my ($package) = @_;
  my $package_name = ref $package || $package;
  return $Sub::Attributes::attributes{ $package_name };
}
1;
__END__
=head1 NAME

Sub::Attributes - meta programming with subroutine attributes

=head1 SYNOPSIS

  package Point;
  use base 'Sub::Attributes';

  # croak if not called as a class method
  sub new :ClassMethod {
    ...
  }

  # croak if not called as object method
  sub add : Method {
    ...
  }

  # private subroutine, will croak unless called from within Point package
  sub _internal_logic : Private Method {
    ...
  }

  # Typical method modifiers ala LISP & Class::Method::Modifiers
  # before, after & around all occur at compile time
  sub check_state : Before(add) {
    ...
  }

  sub doubleme : After(add) {
    ...
  }
  # orig is a coderef to add, it needs to be given $self becase it's an object
  # method
  sub filter_calls : Around(add) {
    my ($orig, $self, @args) = @_;
    my $result = $orig->($self, @args);
    ...
  }

  package main;
  my $p = Point->new(3,8);
  $p->sub_attributes(); # { add => ['Method'], _internal_logic => ['Private','Method'], ... }

=head1 METHODS

=head2 sub_attributes

Returns a hashref of subroutine names and their attributes.

=head1 SEE ALSO

=over 4

=item * L<Class::Method::Modifiers|https://metacpan.org/pod/Class::Method::Modifiers>

=item * L<MooseX::MethodAttributes|https://metacpan.org/pod/MooseX::MethodAttributes>

=back

=head1 AUTHOR

E<copy> 2016 David Farrell

=head1 LICENSE

See LICENSE

=head1 REPOSITORY

L<https://github.com/dnmfarrell/Sub-Attributes>

=head2 BUGTRACKER

L<https://github.com/dnmfarrell/Sub-Attributes/issues>

=cut

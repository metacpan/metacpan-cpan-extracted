use strict;
use warnings;

package Whitelist;

# FILENAME: Whitelist.pm
# CREATED: 12/04/12 06:33:42 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: A basic test whitelist
use Carp qw( confess );

sub new {
  my ( $class, @args ) = @_;
  return bless { args => \@args }, $class;
}

sub whitelist {
  my ( $self, @args ) = @_;
  die 'Frozen' if $self->{frozen};
  $self->{whitelist} = [] unless exists $self->{whitelist};
  $self->{load}      = [] unless exists $self->{load};

  push @{ $self->{whitelist} }, @args;
  push @{ $self->{load} },      @args;

}

sub noload_whitelist {
  my ( $self, @args ) = @_;
  die 'Frozen' if $self->{frozen};
  $self->{whitelist} = [] unless exists $self->{whitelist};
  push @{ $self->{whitelist} }, @args;
}

sub freeze {
  my ($self) = @_;
  $self->{module_whitelist} = {};
  $self->{whitelist_inc}    = {};
  require Module::Runtime;
  for my $lib ( @{ $self->{load} } ) {
    Module::Runtime::require_module($lib);
  }
  for my $lib ( @{ $self->{whitelist} } ) {
    my $nn = Module::Runtime::module_notional_filename($lib);
    $self->{module_whitelist}->{$nn} = 1;
    $self->{whitelist_inc}->{$nn} = $INC{$nn} if exists $INC{$nn};
  }
  $self->{frozen}   = 1;
  $self->{real_inc} = {%INC};
}

sub checker {
  my ($self) = @_;
  my $dumper = sub {
    my $dump_hash = sub {
      my $hash   = shift;
      my $prefix = shift;
      $prefix = "  " if not defined $prefix;
      return qq[{\n$prefix] . ( join qq{,\n$prefix}, map { $_ . ' => ' . $hash->{$_} } keys %{$hash} ) . qq[\n}];
    };
    my $string_values = sub {
      my $hash = shift;
      return { map { $_, 'q{' . $hash->{$_} . '}' } keys %{$hash} };
    };

    return $dump_hash->(
      {
        real_inc         => $dump_hash->( $string_values->( $self->{real_inc}, ),         "    " ),
        whitelist_inc    => $dump_hash->( $string_values->( $self->{whitelist_inc}, ),    "    " ),
        module_whitelist => $dump_hash->( $string_values->( $self->{module_whitelist}, ), "    " ),

      }
    );
  };

  my $coderef;
  $coderef = sub {
    my ( $code, $filename ) = @_;
    return if exists $self->{module_whitelist}->{$filename};
    confess( "$filename requested but not whitelisted:\n " . $dumper->() );
  };

}
1;


package Option::Option;

=pod

=head1 NAME

Option::Option

=head1 SYNOPSIS

Provides objects that can hold results that can be unwrapped
similar to Rust

    use Option::Option;

    my $option = Option::Option->new("something");

    # This croaks:
    print $var;

    # This works
    my $var = $option->unwrap();
    print $var;

    # This also works and has a helpful error message
    my $var = $option->expect("get my something");
    print $var;

=head1 AUTHOR

Lee Katz

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw/confess croak/;
use overload '""' => 'toString';

use Exporter qw/import/;

use version;
our $VERSION = version->declare("0.1");

=pod

=over

=item new()

Creates a new object with a variable

=cut

sub new{
  my($class, $var) = @_;

  my $self = {
    var => $var,
  };

  bless($self, $class);

  return $self;
}

=pod

=item unwrap()

Checks if the variable is defined and if it is, returns it.
If not defined, croaks.

=back

=cut

sub unwrap{
  my($self) = @_;

  if(!defined($$self{var})){
    croak("Variable not defined");
  }

  return $$self{var};
}

=pod

=over

=item expect($msg)

Checks if the variable is defined and if it is, returns it.
If not defined, croaks with error message.

=back

=cut

sub expect{
  my($self, $msg) = @_;
  
  if(!defined($$self{var})){
    croak("Variable not defined: $msg");
  }

  return $$self{var};
}

=pod

=over 

=item toString()

Dies with an error message, describing that the object was attempted to be used
in a scalar context without unwrapping.
This subroutine is not meant to be used directly.

    my $var = Option::Option->new("something");
    my $concat = $var . " wicked this way comes";
    # dies with error message during the concatenation

=back

=cut

sub toString{
  my($self) = @_;
  
  my $var = $$self{var};
  if(!defined($var)){
    $var = "UNDEFINED";
  }
  if(length($var) > 30){
    $var = substr($var, 0, 27)."...";
  }
  
  confess("Attempt to use a ".ref($self)." object whose value is `$var`");
}
1;


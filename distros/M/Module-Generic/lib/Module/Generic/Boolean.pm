##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Boolean.pm
## Version v1.0.2
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2021/05/03
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::Boolean;
BEGIN
{
    use common::sense;
    use overload
      "0+"     => sub{ ${$_[0]} },
      "++"     => sub{ $_[0] = ${$_[0]} + 1 },
      "--"     => sub{ $_[0] = ${$_[0]} - 1 },
      fallback => 1;
    use Module::Generic::Array;
    use Module::Generic::Number;
    use Module::Generic::Scalar;
    our( $VERSION ) = 'v1.0.2';
};

sub new { return( $_[1] ? $true : $false ); }

sub as_array { return( Module::Generic::Array->new( [ ${$_[0]} ] ) ); }

sub as_number { return( Module::Generic::Number->new( ${$_[0]} ) ); }

sub as_scalar { return( Module::Generic::Scalar->new( ${$_[0]} ) ); }

sub defined { return( 1 ); }

our $true  = do{ bless( \( my $dummy = 1 ) => Module::Generic::Boolean ) };
our $false = do{ bless( \( my $dummy = 0 ) => Module::Generic::Boolean ) };

sub true  () { $true  }
sub false () { $false }

sub is_bool  ($) {           UNIVERSAL::isa( $_[0], Module::Generic::Boolean ) }
sub is_true  ($) {  $_[0] && UNIVERSAL::isa( $_[0], Module::Generic::Boolean ) }
sub is_false ($) { !$_[0] && UNIVERSAL::isa( $_[0], Module::Generic::Boolean ) }

sub TO_JSON
{
    # JSON does not check that the value is a proper true or false. It stupidly assumes this is a string
    # The only way to make it understand is to return a scalar ref of 1 or 0
    # return( $_[0] ? 'true' : 'false' );
    return( $_[0] ? \1 : \0 );
}

1;

__END__

package Package::FromData;
use strict;
use warnings;
use 5.010;

use base 'Exporter';
our @EXPORT = qw/create_package_from_data/;

our $VERSION = '0.01';

use Readonly;
use Carp;
use Scalar::Util qw(blessed);
use Test::Deep::NoTest qw(eq_deeply);

Readonly my %SIGIL_TYPE_MAP => (
    '$' => 'SCALAR',
    '@' => 'ARRAY',
    '%' => 'HASH',
    '*' => 'GLOB',
);

sub _must_be($$$) {
    croak $_[0] unless ref $_[1] && ref $_[1] eq $_[2];
}

sub _must_be_hash($$)  { &_must_be(@_[0,1], 'HASH' ) }
sub _must_be_array($$) { &_must_be(@_[0,1], 'ARRAY') }

sub create_package_from_data {
    my $packages = shift;
    _must_be_hash 'please pass create_package_from_data a hashref', $packages;

    _must_be_hash 'definition for package must be a hashref', $_ 
      for values %$packages;

    foreach my $package (keys %$packages){
        my $def = $packages->{$package};
        
        # create package
        _create_package($package);
        
        # add constructors
        foreach my $const (@{$def->{constructors}||[]}){
            _add_constructor($package, $const);
        }

        # add variables
        my $sigils = '['. (join '', keys %SIGIL_TYPE_MAP). ']';
        foreach my $variable (keys %{$def->{variables}||{}}){
            if($variable !~ /^(?<sigil>$sigils)(?<varname>\w+)$/o){
                die "'$variable' doesn't look like a variable name";
            }
            
            my $sigil   = $+{sigil}; # XXX infer from reftype?
            my $varname = $+{varname};
            my $value   = $def->{variables}{$variable};
            $value = \"$value" if !ref $value; # make scalar a SCALAR

            _must_be "value for '$variable' must be a ".
              $SIGIL_TYPE_MAP{$sigil}. ' reference',
                $value, $SIGIL_TYPE_MAP{$sigil};
            _add_variable_to($package, $varname, $value);
        }
        
        # add functions
        foreach my $function (keys %{$def->{functions}||{}}){
            _add_function_from_definition($package, $function,
                                          $def->{functions}{$function});
            
        }
        
        # add methods
        foreach my $method (keys %{$def->{methods}||{}}){
            _add_function_from_definition(
                $package, $method,
                $def->{methods}{$method},
                1,
                sub { croak 'must be called as a method' unless blessed $_[0] },
            );
        }

        # add static methods
        foreach my $method (keys %{$def->{static_methods}||{}}){
            _add_function_from_definition(
                $package, $method,
                $def->{static_methods}{$method},
                1
            );
        }
    }
}

sub _create_package {
    my $name = shift;
    die "invalid package name '$name'" 
      unless $name =~ /^\w(?:\w|::)+\w$/;
    eval "package $name";
}

sub _add_constructor {
    my ($package, $name) = @_;
    _add_function_to($package, $name, sub { 
        my $class = shift; 
        return bless {}, $class 
    });
}

sub _mk_sub {
    my ($body, $shift, $precondition) = @_;
    return sub {
        $precondition->(@_)          if $precondition;
        do { shift for (1..$shift) } if $shift; # kill unnecessary args
        return $body->(@_)           if $body;
    }
}

sub _add_function_from_definition {
    my ($package, $function, $fdef, $shift, $precondition) = @_;
    given(ref $fdef){
        when('ARRAY'){
            my @fdef = @$fdef;
            my $func;
            
            # determine default
            my $default;
            $default = pop @fdef if @fdef % 2 == 1;
            
            # def is of the form { method => 'Class' }
            if(!@fdef && ref $default eq 'HASH' &&
                 scalar keys %$default == 1){
                my ($method, $class) = %$default;
 
                $func = _mk_sub( sub {
                    return $class->$method;
                }, $shift, $precondition);
            }
            
            # def is a [ [expected @_] => output, ... ] seq
            else {
                my @rules;
                for(my $i = 0; $i < @fdef; $i+=2){
                    my ($in, $out) = @fdef[$i,$i+1];
                    push @rules, _mk_matcher($in, $out);
                }
                
                $func = _mk_sub( sub {
                    for(@rules){
                        my @result = $_->(wantarray, @_);
                        if(@result){
                            return @result if(wantarray);
                            return $result[0];
                        }
                    }
                    if (ref $default eq 'ARRAY'){
                        if(wantarray){
                            return @$default;
                        }
                        return $default->[0];
                    }
                    return $default || 
                      die "$function cannot handle [@_] as input";
                }, $shift, $precondition);
            }
            
            _add_function_to($package, $function, $func);

        }
        default {
            # constant function
            _add_constant_function_to($package, $function, $fdef);
        }
    }
}

sub _mk_matcher {
    my ($in, $out) = @_;
    my @in  = @$in;
    my @out = ($out);
    @out = @$out if ref $out eq 'ARRAY';
    
    return sub {
        my $wantarray = shift;
        if (eq_deeply [@_], [@in]){
            if(ref $out eq 'HASH'){
                if($wantarray){
                    return @{$out->{list}||$out->{array}};
                }
                return $out->{scalar};
            }
            return @out;
        }
        return;
    }
}

sub _add_constant_function_to {
    my ($package, $function, $value) = @_;
    _add_function_to($package, $function, sub { $value });
}

sub _add_function_to { # package, subname, coderef
    _fuck_with_glob(@_);
}

sub _add_variable_to { # package, varname, value
    _fuck_with_glob(@_);
}

sub _fuck_with_glob {
    my ($package, $variable_name, $value) = @_;
    die "WHOA THERE, '$value' isn't a ref" unless ref $value;
    no strict 'refs';
    *{"${package}::${variable_name}"} = $value;
}

1;
__END__

=head1 NAME

Package::FromData - generate a package with methods and variables from
a data structure

=head1 SYNOPSIS

Given a data structure like this:

  my $packages = { 
      'Foo::Bar' => {
          constructors   => ['new'],        # my $foo_bar = Foo::Bar->new
          static_methods => {               # Foo::Bar->method
              next_word => [                # Foo::Bar->next_word
                  ['foo']       => 'bar',   # Foo::Bar->next_word('foo') = bar
                  ['hello']     => 'world',
                  [qw/bar baz/] => 'baz',   # Foo::Bar->next_word(qw/foo bar/) 
                                            #    = baz
                  'default_value'
              ],
              one => [ 1 ],                 # Foo::Bar->one = 1
          },
          methods => {
              wordify => [ '...' ],         # $foo_bar->wordify = '...'
                                            # Foo::Bar->wordify = <exception>
          
              # baz always returns Foo::Bar::Baz->new
              baz     => [ { new => 'Foo::Bar::Baz' } ],
          },
          functions => {
              map_foo_bar => [ 'foo' => 'bar', 'bar' => 'foo' ],
              context     => {
                  scalar => 'called in scalar context',
                  list   => [qw/called in list context/],
              }
          },
          variables => {
              '$VERSION' => '42',           # $Foo::Bar::VERSION
              '@ISA'     => ['Foo'],        # @Foo::Bar::ISA
              '%FOO'     => {Foo => 'Bar'}, # %Foo::Bar::FOO
          },
      },
  };

and some code like this:

   use Package::FromData;
   create_package_from_data($packages);

create the package C<Foo::Bar> and the functions as specified above.

After you C<create_package_from_data>, you can use C<Foo::Bar> as though
it were a module you wrote:

   my $fb = Foo::Bar->new       # blessed hash reference
   $fb->baz                     # a new Foo::Bar::Baz
   $fb->wordify                 # '...'
   $fb->next_word('foo')        # 'bar'
   Foo::Bar->next_word('foo')   # 'bar'
   Foo::Bar->baz                # <exception>, it's an instance method
   Foo::Bar::map_foo_bar('foo') # 'bar'
   $Foo::Bar::VERSION           # '42'

Not a very useful package, but you get the idea.

=head1 DESCRIPTION

This module creates a package with predefined methods, functions, and
variables from a data structure.  It's used for testing (mock objects)
or experimenting.  The idea is that you define a package containing
functions that return values based on keys, and the rest of your app
uses this somehow.  (I use it so that C<< Jifty->... >> or 
C<< Catalyst.uri_for >> will work in templates being served via
L<App::TemplateServer|App::TemplateServer>.)

=head2 THE TOP

The top level data structure is a hash of package names / package
definition hash pairs.

=head2 PACKAGE DEFINITION HASHES

Each package is defined by a package definition hash.  This can contain
a few keys:

=head3 constructors

An arrayref of constructors to be generated.  The generated code looks like:

   sub <the name> {
       my $class = shift;
       return bless {}, $class;
   }

=head3 functions

The functions key should point to a hash of function names / function
definiton array pairs.

=head4 FUNCTION DEFINITION ARRAYS

The function definition array is a list of pairs followed by an
optional single value.  The pairs are treated like a @_ => result of
function hash, and the optional single element is used as a default
return value.  The expected input (@_) can be deep Perl data
structures; an input => output pair matches if the C<\@_> in the
program C<Test::Deep::NoTest::eq_deeply>s the input rule you specify.

The pairs are of the form ARRAYREF => SCALAR|ARRAYREF|SEPECIAL.  To make
C<function('foo','bar')> return C<baz>, you would add a pair like C<[
'foo', 'bar' ] => 'baz'> to the definition hash.  To return a bare list,
use a arrayref; C<['foo','bar'] => ['foo','bar']>.  To return a
reference to a list, nest an arrayrf in the arrayref; C<foo('bar') =
['baz']>.

To return different values in scalar or list context, pass a hash as
the output definition:

    [ [input] => { scalar => '42', list => [qw/contents of the list/] },
      ... ]

To return a hashref, just say C<< [{ ... }] >>.

Finally, the function definition array may be a single hash containing
a C<method => package> pair, which means to always call C<<
package->method >> and return the result.  This makes it possible for
packages defined with C<Package::FromData> to be nested.

=head3 methods

Like functions, but the first argument (<$self>) is ignored.

=head3 static_methods

Like methods, but can be invoked against the class name instead of 
and instance of the class.

=head3 variables

A hash of variable name (including sigil) / value pairs.  Keys
starting with @ or % must point to the appropriate reference type.

=head1 EXPORTS

C<create_package_from_data>

=head1 FUNCTIONS

=head2 create_package_from_data

See L</DESCRIPTION> above.

=head1 BUGS

Probably.  Report them to RT.

=head1 CODE REPOSITORY

The git repository is at L<http://git.jrock.us/> and can be cloned with:

    git clone git://git.jrock.us/Package-FromData

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2007, Jonathan Rockway.  This module free software.  You may
redistribute it under the same terms as Perl itself.

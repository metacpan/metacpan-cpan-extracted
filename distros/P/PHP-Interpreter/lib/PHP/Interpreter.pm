package PHP::Interpreter;

=head1 NAME

PHP::Interpreter - An embedded PHP5 interpreter

=head1 SYNOPSIS

  use PHP::Interpreter;

  my $p = PHP::Interpreter->new();
  $p->include("some_php_include.php");

  my $val = $p->somePhpFunc($perlVal);

=head1 DESCRIPTION

This class encapsulates an embedded PHP5 intepreter.  It provides
proxy methods (via AUTOLOAD) to all the functions declared in the
PHP interpreter, transparent conversion of Perl datatypes to PHP
(and vice-versa), and the ability for PHP to similarly call Perl
subroutines and access the Perl symbol table.

The goal of this package is to construct a transaparent bridge for
running PHP code and Perl code side-by-side.

=cut

require DynaLoader;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
$VERSION = "1.0.2";
@ISA = qw(Exporter DynaLoader);
bootstrap PHP::Interpreter || die "couldn't bootstrap PHP::Interpreter";

use PHP::Interpreter::Class;

sub AUTOLOAD {
  my $sub = $AUTOLOAD;
  my $self = shift;
  $sub =~ s/.*:://;
  unshift @_, $sub;
  # we'd prefer to use goto here, but it dies if we croak in it
  no strict 'refs';
  *{$AUTOLOAD} = sub { shift->call($sub, @_) };
  $self->call(@_);
}

1;

__END__

=head1 INTERFACE

=head2 Constructor

=head3 new

  my $php = PHP::Interpreter->new( $init );

Instantiates a PHP::Interpreter object, and creates an associated PHP
interpreter instance. An anonymous hash of initial values may be passed. The
supported initial value keys are:

=over 4

=item * GET

An array ref that will be installed in the PHP $_GET autoglobal array.

=item * POST

An array ref that will be installed in the PHP $_POST autoglobal array.

=item * COOKIE

An array ref that will be installed in the PHP $_COOKIE autoglobal array.

=item * SERVER

An array ref that will be installed in the PHP $_SERVER autoglobal array.

=item * ENV

An array ref that will be installed in the PHP $_ENV autoglobal array.

=item * FILES

An array ref that will be installed in the PHP $_FILES autoglobal array.

=item * OUTPUT

Change the output handler. By default, any data sent to STDOUT in PHP will be
redirected to STDOUT in Perl. If OUTPUT is a scalar reference, then instead
output will be appended to that scalar reference. If OUTPUT is a coderef, then
whenever PHP emits data, that coderef will be called with the output fragment
as its argument.

=item * INCLUDE_PATH

A string that overides PHP's include_path ini setting.

=item *

Any other data that is passed will be installed in the PHP global symbol
table. So for instance if you set:

  $php = PHP::Interpreter( BRIC => { element => $e, session => $s } );

Then PHP will create the globally scoped $BRIC array with the keys 'element'
and 'session', pointing at the appropriately converted or wrapped Perl
variables $e and $s.

=back

=head2 Instance Methods

=head3 eval()

  $php->eval(q^ echo "hello world!\n"; ^);
  my $rv = $php->eval("return file_get_contents($some_url);");

Executes the PHP code passed to it, returning any value returned from the
script, or true. Throw an exception on failure.

=head3 include()

  $php->include("somePhpFile.php");

Calls the PHP construct include on the specified file (similar to Perl's
C<use> keyword). Does not suppress duplicate usages.  Throws an exception on failure.

=head3 include_once()

  $php->include_once("somePhpFile.php");

Calls the PHP construct include_once on the specified file (similar to Perl's
C<use> keyword). Throws an exception on failure.

=head3 is_multithreaded()

  if($php->is_multithread) {
    # I can instantiate a second independent interpreter
  }

A runtime check to determine if PHP is thread-safe - i.e. if more than one interpreter
can be simultaneously instantiated.  If not, further calls to PHP::Interpreter->new() 
will return the original PHP interpreter instance.

=head3 call()

  $rv = $php->call(stroupper => $perlVar);

Calls the PHP function specified by the first argument, passing the remaining
arguments as parameters. Returns the converted return value of the function
back into Perl. Throws an exception if an error is encountered.

=head3 set_output_handler()

  my $old_hander = $php->set_output_handler(\$scalar);
  $old_hander = $php->set_output_handler(\&func);

Sets a new output handler, either a scalar reference or a coderef.

=head3 get_output()

  my $outbuf = $php->get_output;

If the output buffer is a scalar reference, this method will return its
current contents.

=head3 clear_output()

  my $outbuf = $php->clear_output;

If the output buffer is a scalar reference, this method will set it to an
empty string.

=head3 instantiate()

  my $instance = $php->instantiate('stdClass', @args);

Creates and returns an instance of the specified PHP class. Any additional
arguments are passed to the object's constructor.

=head3 AUTOLOAD

  my $retval = $php->strtoupper($string);

An C<AUTOLOAD> method allows PHP::Interpreter to call arbitrary PHP functions
without using call(). Internally, this is identical to

  $php->call('method', @args);

The C<AUTOLOAD>-generated method will be cached for future calls to the
same PHP method.

=head1 TYPE HANDLING

In general, the PHP::Interpreter module attempts to make type conversion between Perl and PHP completely transparent.  
For non-tied, non-magical, and non-objects, this works well.  However, when passing these special types, some
considerations must be taken into account.

=head2 Perl variables passed into PHP

In PHP, magical/blessed values will appear as being of the class PerlSV::$CLASSNAME, as detailed below.

=head2 PHP variables passed into Perl

PHP has two types of 'special' variables which do not translate transparently to basic Perl types.

=over

=item * Resources

Resources in PHP will appear in Perl as of the type PHP::Interpreter::Resource.  PHP resources have no attributes or bound methods, so this class is just an opaque container.

=item * Objects

Object in PHP will appear in Perl as of the type PHP::Interpreter::Class::$CLASSNAME.  These objects will proxy all method calls and attribute accesses through to the internal PHP object.

=back

=head1 USING PHP

The PHP interpeter that is instantiated with PHP::Interpreter has some special classes it defines to allow PHP to interface back with its calling PHP Interpreter.

=head2 Perl

The PHP Perl class represents the calling Perl intepreter.

=head3 Constructor

The Perl class is a singleton class, and has no publc constructor.

=head3 getInstance()

  <?php
    $perl = Perl::getInstance();
  ?>

Returns the valid Perl object instance.

=head3 eval()

Executes the passed perl code, returning any return value into PHP.

  <?php
    $perl = Perl::getInstance();
    $perl->eval(q^
      for(reverse(1...99)) {
        print "$_ bottles of beer on the wall, $_ bottles of beer.\n";
      }
    ^);
  ?>

=head3 call()

Call a Perl subroutine, passing optional args and returning the return value into PHP.

  <?php
    $perl = Perl::getInstance();
    $upper = $perl->call('ucfirst', 'hello');
  ?>

This functionality is also available via an AUTOLOAD function described below.

=head3 new()

Create a new instance of a perl class.

  <?php
     $perl = Perl::getInstance();
     $file = __FILE__;
     $instance = $perl->new('IO::File', "<$file");
  ?>

This will return a PHP object of type 'PerlSV::IO::File' that will proxy all the Perl classes' method calls.

=head3 call_method()

Call as static (class) method of a perl class.

  <?php
     $perl = Perl::getInstance();
     $instance = $perl->call_method(
         'DBI', 'connect',
         array('dbi:SQLite:dbname=file.db, '', '')
     );
  ?>

This will effectively call "DBI->connect('dbi:SQLite:dbname=file.db')" and return a PHP object of type 'PerlSV::DBI:db' that will proxy all the Perl classes' method calls.

=head3 getVariable()

Access a Perl symbol by name.

  <?php
     $perl = Perl::getInstance();
     $version = $perl->getVariable('$PHP::Interpreter::VERSION');
  ?>

This works only for package variables, not lexical (C<my>) variables.

=head3 setVariable()

Set a Perl symbol by name.

  <?php
     $perl = Perl::getInstance();
     $arr  = array('banana' => 'yellow' , 'apple' => 'red');
     $perl->setVariable('$fruits', $arr);
  ?>

This sets '$main::fruits' to be a hashref of the listed fruits.
This works only for package variables, not lexical (C<my>) variables.

B<Note>: PHP functions are not first class objects, so you cannot set coderefs in perl.

=head3 AUTOLOAD

The Perl class provides an AUTOLOAD function to automatically call functions.

  <?php
    $perl = Perl::getInstance();
    $upper = $perl->ucfirst('hello');
  ?>

=head2 PerlSV

The PerlSV class is the base PHP wrapper class that serves as an opaque container for Perl objects in PHP.  It proxies all method calls and attribute accesses.  This class uses call and attribute accessor overloading to provide access to the object.

  <?php
    $perl = Perl::getInstance();
    $fh = $perl->new("IO::File", "<$file");
    while($fh->getline()) {
      # ...
    }
  ?>

=head1 BUGS

Please send bug reports to <bug-php-interpreter@rt.cpan.org>.

=head1 AUTHORS

George Schlossnagle <george@omniti.com>

=head1 CREDITS

Development sponsored by Portugal Telecom - SAPO.pt.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Kineticode, Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

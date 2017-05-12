##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::Callback - a workaround for the problem of nonserializable code.

=head1 SYNOPSIS

 use PApp::Callback;

 my $function = register_callback BLOCK [key => value...];
 my $cb = $function->refer ([args...]);

 &$cb;

 my $cb = create_callback BLOCK [key => value...];

=head1 DESCRIPTION

The problem: Code is unserializable (at the moment, but it will probably
never be efficient to serialize code).

The workaround (B<not> the solution): This class can be used to create
serializable callbacks (or "references"). You first have to register all
possible callback functions (in every process, and before you try to call
callbacks). Future versions might allow loading files or strings with the
function definition.

=over 4

=cut

package PApp::Callback;

require 5.006;

use base 'Exporter';

$VERSION = 2.1;
@EXPORT = qw(register_callback create_callback);

=item register_callback functiondef, key => value...

Registers a function (preferably at program start) and returns a callback
object that can be used to create callable and serializable objects.

If C<functiondef> is a string it will be interpreted as a function name in
the callers package (unless it contains '::'). Otherwise you should use a
"name => <funname>" argument to uniquely identify the function. If it is
omitted the filename and linenumber will be used, but that is fragile.

The optional C<< args => [arrayref] >> parameter will prepended the given
arguments to each invocation of the callback.

Examples:

 my $func = register_callback {
               print "arg1=$_[0] (should be 5), arg2=$_[1] (should be 7)\n";
            } name => "toytest_myfunc1";

 my $cb = $func->refer(5);
 # experimental alternative: $func->(5)

 # ... serialize and deserialize $cb using Data::Dumper, Storable etc..

 # should call the callback with 5 and 7
 $cb->(7);

=cut

our %registry;

sub new {
   my $self = shift;
   my %attr = @_;

   bless { %$self,
      args => $attr{args} || [],
   }, __PACKAGE__;
}

sub register_callback(&;@) {
   shift if $_[0] eq __PACKAGE__;
   my ($package, $filename, $lineno) = caller;
   my $id;
   my $code = shift;
   my %attr = @_;

   if (ref $code) {
      $id = $attr{name} ? "I$attr{name}" : "A$filename:$lineno";
   } else {
      $code = $package."::$code" unless $code =~ /::/;
      $id = "F$code";
      $code = sub { goto &$code };
   }
   $registry{$id} = [$code];

   my $self = new {
      'package' => $package,
      filename  => $filename,
      id        => $id,
   }, %attr;

   delete $attr{__do_refer} ? $self->refer : $self;
}

=item create_callback <same arguments as register_callback>

Just like C<register_callback>, but additionally calls C<refer> (see
below) on the result, returning the function reference directly.

=cut

sub create_callback(&;@) {
   push @_, __do_refer => 1;
   goto &register_callback;
}

=item $cb = $func->refer([args...])

Create a callable object (a code reference). The callback C<$cb> can
either be executed by calling the C<call> method or by treating it as a
code reference, e.g.:

 $cb->call(4,5,6);
 $cb->(4,5,6);
 &$cb;

It will behave as if the original registered callback function would be
called with the arguments given to C<register_callback> first and then the
arguments given to the C<call>-method.

C<refer> is implemented in a fast way and the returned objects are
optimised to be as small as possible.

The current database (C<$PApp::SQL::Database>) and the corresponding
database handle will be saved when a callback is refer'ed, and restored
later when it is called.

=cut

sub refer($;@) {
   my $self = shift;

   bless [$self->{id}, $PApp::SQL::Database, @{$self->{args}}, @_], PApp::Callback::Function;
}

=item $func2 = $func->append([args...])

Creates a new callback by appending the given arguments to each invocation of it.

=cut

sub append($;@) {
   my $self = bless { %{+shift} }, __PACKAGE__;
   $self->{args} = [@{$self->{args}}, @_];
   $self;
}

use overload
   fallback => 1,
   '&{}' => sub {
      my $self = shift;
      sub { 
         unshift @_, $self;
         goto &refer;
      };
   };

package PApp::Callback::Function;

use Carp 'croak';

# a Function is a [$id, $database, @args]

=item $cb->call([args...])

Call the callback function with the given arguments.

=cut
   
sub call($;@) {
   unshift @_, @{+shift};

   my $id = shift;
   my $cb = $PApp::Callback::registry{$id};

   unless ($cb) {
      # too bad, no callback
      croak "callback '$id' not registered";
   }

   local $PApp::SQL::Database = shift;
   local $PApp::SQL::DBH      = $PApp::SQL::Database ? $PApp::SQL::Database->checked_dbh : undef;

   &{$cb->[0]};
}

sub asString {
   my $self = shift;
   "CODE($self->[0])";
}

use overload
   fallback => 1,
   '""'  => \&asString,
   '&{}' => sub {
      my $self = shift;
      sub { 
         unshift @_, $self;
         #goto &call;#d#
         &call;
      };
   };

1;

=back

=head1 BUGS

 - should be able to serialize code at all costs
 - should load modules or other thingies on demand
 - the 'type' (ref $cb) of a callback is not CODE

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut


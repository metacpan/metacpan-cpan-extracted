package Test::CGI::Untaint;

# turn on perl's safety features
use strict;
#use warnings;
use Carp qw(croak);

# use test builder
use Test::Builder;
my $Test = Test::Builder->new();

# the stuff to test
use CGI;
use CGI::Untaint;

# export the test functions
use Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $config_vars $VERSION @Data_Stack);
@ISA         = qw( Exporter );
@EXPORT      = qw( is_extractable unextractable
                   is_extractable_deeply is_extractable_isa );
@EXPORT_OK   = qw( config_vars );
%EXPORT_TAGS = ("all" => [ @EXPORT, @EXPORT_OK ]);

# set the version
$VERSION = "1.10";

=head1 NAME

Test::CGI::Untaint - Test CGI::Untaint Local Extraction Handlers

=head1 SYNOPSIS

  use Test::More tests => 2;
  use Test::CGI::Untaint;

  # see that 'red' is extracted from 'Red'
  is_extractable("Red","red","validcolor");

  # see that validcolor fails
  unextractable("tree","validcolor");

=head1 DESCRIPTION

The B<CGI::Untaint> module can be extended with "Local Extraction
Handlers" that can be used define new ways of untainting data.

This module is designed to test these data extraction modules.  It
does this with the following methods:

=over 4

=item is_extractable

Tests that first value passed has the second value passed extracted
from it when the local extraction handler named in the third argument
is called.  An optional name for the test may be passed in the
forth argument.  For example:

  # check that "Buffy" is extracted from "Buffy Summers" with
  # the CGI::Untaint::slayer local extraction handler
  is_extractable("Buffy Summers","Buffy", "slayer");

=cut

sub is_extractable
{
  # extract the params, have a default test name
  my ($data, $wanted, $func, $name) = @_;

  # debug info
  # { no warnings;
  # print STDERR "data   is '$data'\n";
  # print STDERR "wanted is '$wanted'\n";
  # print STDERR "func   is '$func'\n";
  # print STDERR "name   is '$name'\n";
  # }

  # default name
  $name ||= "'$data' extractable as $func";

  # create a CGI::Untaint object
  my $untaint = CGI::Untaint->new(config_vars(),
				  data => $data);

  my $result = $untaint->extract("-as_$func" => "data");

  # check if there was an error
  if ($untaint->error)
  {
     $Test->ok(0,$name);
     $Test->diag($untaint->error);
     return 0;
  } 

  # check that the extracted value is equal
  $Test->is_eq(
     $result,
     $wanted,
     $name
  );
}

=item unextractable

Checks that nothing is extracted from the first argument passed with
the local extraction handler named in the second argument.  For
example:

  # check that nothing is extracted from "Willow Rosenberg"
  # with the CGI::Untaint::slayer local extraction handler
  unextractable("Willow Rosenberg", "slayer");

The third argument may optionally contain a name for the test.

=cut

sub unextractable
{
  # extract the params, have a default test name
  my ($data, $func, $name) = @_;

  # work out what it's called
  $name ||= "'$data' unextractable as $func";

  # create a CGI::Untaint object
  my $untaint = CGI::Untaint->new(config_vars(),
				  data => $data);

  # try extracting it
  my $result = $untaint->extract("-as_$func" => "data");
  unless($Test->ok($untaint->error, $name))
  {
    $Test->diag("expected data to be unextractable, but got:");
    if (defined($result))
      {  $Test->diag(" '$result'") }
    else
      {  $Test->diag(" undef") }
  }
  return !$result;
}

=item is_extractable_deeply

Tests that first value passed has the second value passed extracted
from it when the local extraction handler named in the third argument
is called B<deeply>.  Where C<is_extractable> does a simple string
equality test, this does a proper deep check like C<is_deeply> in
B<Test::More>.  This is most useful when your class returns a big
old data structure from is_valid rather than a simple scalar.

=cut

sub is_extractable_deeply
{
  # extract the params, have a default test name
  my ($data, $wanted, $func, $name) = @_;

  # default name
  $name ||= "'$data' deeply extractable as $func";

  # create a CGI::Untaint object
  my $untaint = CGI::Untaint->new(config_vars(),
				  data => $data);

  my $result = $untaint->extract("-as_$func" => "data");

  # check if there was an error
  if ($untaint->error)
  {
     $Test->ok(0,$name);
     $Test->diag($untaint->error);
     return 0;
  }

  # The code for the rest of this function is borrowed from
  # Test::More.

  # variable to store the success or failure
  my $ok;

  # hang on, are these things both not refs?
  if( !ref $result || !ref $wanted ) {
    $ok = $Test->is_eq($result, $wanted, $name);
  }

  else
  {
    # do the deep check
    local @Data_Stack = ();
    if (_deep_check($result, $wanted))
    {
      # yey! it worked
      $ok = $Test->ok(1, $name);
    }
    else
    {
      # no it didn't, darn!
      $ok = $Test->ok(0, $name);
      $ok = $Test->diag(_format_stack(@Data_Stack));
    }
  }

  # return the value
  return $ok;
}

=item is_extractable_isa

Tests that the first value pass extracts something that is, or is
a subclass of, the class passed in the second argument when the
extraction handler .

=cut

sub is_extractable_isa
{
  my ($data, $class, $func, $name) = @_;

  # default name
  $name ||= "'$data' extractable as a '$class'";

  # create a CGI::Untaint object
  my $untaint = CGI::Untaint->new(config_vars(),
				  data => $data);

  my $object = $untaint->extract("-as_$func" => "data");

  # check if there was an error
  if ($untaint->error)
  {
     $Test->ok(0,$name);
     $Test->diag($untaint->error);
     return 0;
  }

  # the code for the rest of this function is stolen pretty much
  # wholeheartedly from Test::More.  It's been reformatted to my
  # style and I've added lots of comments.

  my $diag;

  # check if the object is defined
  if (!defined $object)
    { $diag = "the extracted object isn't defined"; }

  # check if the object is a ref
  elsif (!ref $object)
    { $diag = "the extracted object isn't a reference"; }

  # check if we can call isa on it
  else
  {
    # We can't use UNIVERSAL::isa because we want to honor isa() overrides
    local($@, $!);  # eval sometimes resets $!

    # try calling isa
    my $rslt = eval { $object->isa($class) };

    # did we get an error?
    if ($@)
    {
      # see if it's a error due to the thing being a ref rather than the
      # thing being an object
      if ($@ =~ /^Can't call method "isa" on unblessed reference/)
      {
	# hmm looks like it''s just a plain old ref.  Use UNIVERSAL::isa
	# to check we get the same thing
	if (!UNIVERSAL::isa($object, $class))
        {
	  my $ref = ref $object;
          $diag = "the extracted object isn't a '$class' it's a '$ref'";
        }
      }
      else
      {
	# We got a error thrown from the code when we called the isa
	# method?  That's screwed up!  PANIC!
	die <<WHOA;
WHOA! I tried to call ->isa on the extacted object and got some weird
error. This should never happen.  Please contact the author immediately.
Here's the error.
$@
WHOA
       }
    }

    # did we get false back?  That means it's a real object, but it
    # just isn't a subclass of what we thought it should be.
    elsif( !$rslt ) {
      my $ref = ref $object;
      $diag = "the extracted object isn't a '$class' it's a '$ref'";
    }
  }

  # did we have a 'problem'?
  my $ok;
  if($diag)
  {
    # print a failure
    $ok = $Test->ok( 0, $name );
    # print out the debug info
    $Test->diag("    $diag\n");
  }
  else
    { $ok = $Test->ok( 1, $name ); }

  # return true unless we printed out a failure
  return $ok;
}

=back

And that's that all there is to it, apart from the one function that
can be used to configure the test suite.  It's not exported by default
(though you may optionally import it if you want.)

=over 4

=item config_vars

The config_vars function is a get/set function that can be used to set
the hashref that will be passed to the creation of the CGI::Untaint
object used for testing.  For example, if you need to instruct
CGI::Untaint to use a custom prefix for your local extraction
handlers, you can do so like so:

  use Test::CGI::Untaint qw(:all);
  config_vars({ INCLUDE_PATH => "Profero" });

=cut

sub config_vars
{
  # setting?
  if (@_)
  {
    croak "Argument to 'config_vars' must be a hashref"
      unless ref $_[0] eq "HASH";
    $config_vars = shift;
  }

  # return the current value or a default value
  return $config_vars || {};
}

=back

=head1 BUGS

None known.

Bugs (and requests for new features) can be reported to the open
source development team at Profero though the CPAN RT system:
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-CGI-Untaint>

=head1 AUTHOR

Written By Mark Fowler E<lt>mark@twoshortplanks.comE<gt>.

Copyright Profero 2003

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::More>, L<CGI::Untaint>

=cut


# code below this point is DIRECTLY cargo culted from Test::More
# without changing anything

my $DNE = bless [], 'Does::Not::Exist';

sub eq_array  {
    my($a1, $a2) = @_;
    return 1 if $a1 eq $a2;

    my $ok = 1;
    my $max = $#$a1 > $#$a2 ? $#$a1 : $#$a2;
    for (0..$max) {
        my $e1 = $_ > $#$a1 ? $DNE : $a1->[$_];
        my $e2 = $_ > $#$a2 ? $DNE : $a2->[$_];

        push @Data_Stack, { type => 'ARRAY', idx => $_, vals => [$e1, $e2] };
        $ok = _deep_check($e1,$e2);
        pop @Data_Stack if $ok;

        last unless $ok;
    }
    return $ok;
}

sub _deep_check {
    my($e1, $e2) = @_;
    my $ok = 0;

    my $eq;
    {
        # Quiet uninitialized value warnings when comparing undefs.
        local $^W = 0; 

        if( $e1 eq $e2 ) {
            $ok = 1;
        }
        else {
            if( UNIVERSAL::isa($e1, 'ARRAY') and
                UNIVERSAL::isa($e2, 'ARRAY') )
            {
                $ok = eq_array($e1, $e2);
            }
            elsif( UNIVERSAL::isa($e1, 'HASH') and
                   UNIVERSAL::isa($e2, 'HASH') )
            {
                $ok = eq_hash($e1, $e2);
            }
            elsif( UNIVERSAL::isa($e1, 'REF') and
                   UNIVERSAL::isa($e2, 'REF') )
            {
                push @Data_Stack, { type => 'REF', vals => [$e1, $e2] };
                $ok = _deep_check($$e1, $$e2);
                pop @Data_Stack if $ok;
            }
            elsif( UNIVERSAL::isa($e1, 'SCALAR') and
                   UNIVERSAL::isa($e2, 'SCALAR') )
            {
                push @Data_Stack, { type => 'REF', vals => [$e1, $e2] };
                $ok = _deep_check($$e1, $$e2);
            }
            else {
                push @Data_Stack, { vals => [$e1, $e2] };
                $ok = 0;
            }
        }
    }

    return $ok;
}

sub _format_stack {
    my(@Stack) = @_;

    my $var = '$FOO';
    my $did_arrow = 0;
    foreach my $entry (@Stack) {
        my $type = $entry->{type} || '';
        my $idx  = $entry->{'idx'};
        if( $type eq 'HASH' ) {
            $var .= "->" unless $did_arrow++;
            $var .= "{$idx}";
        }
        elsif( $type eq 'ARRAY' ) {
            $var .= "->" unless $did_arrow++;
            $var .= "[$idx]";
        }
        elsif( $type eq 'REF' ) {
            $var = "\${$var}";
        }
    }

    my @vals = @{$Stack[-1]{vals}}[0,1];
    my @vars = ();
    ($vars[0] = $var) =~ s/\$FOO/     \$got/;
    ($vars[1] = $var) =~ s/\$FOO/\$expected/;

    my $out = "Structures begin differing at:\n";
    foreach my $idx (0..$#vals) {
        my $val = $vals[$idx];
        $vals[$idx] = !defined $val ? 'undef' : 
                      $val eq $DNE  ? "Does not exist"
                                    : "'$val'";
    }

    $out .= "$vars[0] = $vals[0]\n";
    $out .= "$vars[1] = $vals[1]\n";

    $out =~ s/^/    /msg;
    return $out;
}

1;

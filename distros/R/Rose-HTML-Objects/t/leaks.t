#!/usr/bin/perl -w

use strict;

use Config;

use Test::More;

eval { require Test::Memory::Cycle };

plan(skip_all => 'Test::Memory::Cycle required for leak tests')  if($@); 

package LeakForm;

use Rose::HTML::Form;
use base qw(Rose::HTML::Form);

sub build_form
{
  shift->add_fields
  (
    myfield => 
    { 
      type    => 'selectbox', 
      options => [ 'm' => { label => 'aLabel' } ],
    },
  );
}

package main;

my $form = LeakForm->new;

Test::More->import(tests => 2);

Test::Memory::Cycle::memory_cycle_ok($form, 'no memory cycles');

# XXX: Confine lame memory tests to a known OS.
# XXX: Should use a real rusage-ish module.
if($^O eq 'darwin' && $Config{'osvers'} =~ /^9\./ && !$ENV{'AUTOMATED_TESTING'})
{
  my $first_size = `/bin/ps -orss= -p $$`;
  my $last_size = 0;

  use Rose::HTML::Form::Field::SelectBox;

  use constant ITERATIONS => 1_000;

  my @leaked;

  foreach my $iterations (ITERATIONS, ITERATIONS * 2)
  {
    for(0 .. $iterations) 
    {
      # XXX: For debugging
      #my $foo = Rose::HTML::Form::Field::SelectBox->new(options => [ 'm' => { label => 'aLabel' } ]);

      my $form = LeakForm->new();

      next;

      my $size = `/bin/ps -orss= -p $$`;

      if($size > $last_size)
      {
        print "$size (+" . ($size - $last_size) . ")\n";
        $last_size = $size;
      }
    }

    $last_size ||= `/bin/ps -orss= -p $$`;
    my $leaked = $last_size - $first_size;
    #$leaked && print "# Leaked ", ($leaked * 1024), ' bytes (', (($leaked * 1024) / $iterations), " bytes per iteration)\n";
    push(@leaked, $leaked);
  }

  # There is a constant memory loss due to God-knows-what inside perl.
  # The thing to check is that it does not grow as iterations increase.
  is($leaked[0], $leaked[1], 'no per-iteration leaks');
}
else
{
  SKIP: { skip('leak tests that only run non-automated on darwin 9', 1) }
}

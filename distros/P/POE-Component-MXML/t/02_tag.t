#!/usr/bin/perl -w
# $Id: 02_tag.t,v 1.6 2001/07/15 19:52:31 jgoff Exp $

use strict;

sub POE::Kernel::ASSERT_DEFAULT () { 1 };
use POE;
use POE::Component::MXML;

$| = 1;

#------------------------------------------------------------------------------

my @tests;

sub _assert {
  my $result   = shift;
  my $cur_test = @tests+1;
  if($result == 1) {
    push @tests,"ok $cur_test\n";
  } else {
    push @tests,"not ok $cur_test\n";
    warn "Failed $cur_test : ".shift();
  }
}

#------------------------------------------------------------------------------

#
# Ask for a single parsed tag.
#
sub parse_tag {
  $_[KERNEL]->post ( single_tag_mxml => 'get_tag' );
}

#------------------------------------------------------------------------------

POE::Component::MXML->spawn
  ( Alias       => 'empty_tag_mxml',
    InputHandle => '<empty></empty>',

    Tag         => 'Tag',         # Event for <tag>content</tag>
  );

POE::Component::MXML->spawn
  ( Alias       => 'single_tag_mxml',
    InputHandle => '<date>2001/7/20</date>',

    Tag         => 'Tag',         # Event for <tag>content</tag>
  );

POE::Component::MXML->spawn
  ( Alias       => 'two_tag_mxml',
    InputHandle => '<first_name>Jeff</first_name><last_name>Goff</last_name>',

    Tag         => 'Tag',         # Event for <tag>content</tag>
  );

POE::Component::MXML->spawn
  ( Alias       => 'nested_tag_mxml',
    InputHandle => '<para>open<emph>nest</emph>close</para>',

    Tag         => 'Tag',         # Event for <tag>content</tag>
  );

POE::Component::MXML->spawn
  ( Alias       => 'inter_tag_mxml',
    InputHandle => '<para>open<emph>nest</emph>inter<emph>nest2</emph>close</para>',

    Tag         => 'Tag',         # Event for <emph>content</emph>
  );

#------------------------------------------------------------------------------

POE::Session->create (
  inline_states => {
    _start => sub { $_[KERNEL]->post ( empty_tag_mxml => 'get_tag' ); },
    Tag => sub {
             my ($tag_type,$tag_name,$tag_contents) = @{$_[ARG1]}[0..2];
             _assert($tag_type eq 'Tag');
             _assert($tag_name eq 'empty');
             _assert($tag_contents eq '');
           }
  }
);

POE::Session->create (
  inline_states => {
    _start => sub { $_[KERNEL]->post ( single_tag_mxml => 'get_tag' ); },
    Tag => sub {
             my ($tag_type,$tag_name,$tag_contents) = @{$_[ARG1]}[0..2];
             _assert($tag_type eq 'Tag');
             _assert($tag_name eq 'date');
             _assert($tag_contents eq '2001/7/20');
           }
  }
);

POE::Session->create (
  inline_states => {
    _start => sub {
                for(0..1) {
                  $_[KERNEL]->post ( two_tag_mxml => 'get_tag' );
                }
              },
    Tag => sub {
             my ($tag_type,$tag_name,$tag_contents) = @{$_[ARG1]}[0..2];
             my $heap = $_[HEAP];
             $heap->{ctr}++;
             if($heap->{ctr} == 1) {
               _assert($tag_type eq 'Tag');
               _assert($tag_name eq 'first_name');
               _assert($tag_contents eq 'Jeff');
             } elsif($heap->{ctr} == 2) {
               _assert($tag_type eq 'Tag');
               _assert($tag_name eq 'last_name');
               _assert($tag_contents eq 'Goff');
             }
           }
  }
);

POE::Session->create (
  inline_states => {
    _start => sub {
                for(0..2) {
                  $_[KERNEL]->post ( nested_tag_mxml => 'get_tag' );
                }
              },
    Tag => sub {
             my ($tag_type,$tag_name,$tag_contents) = @{$_[ARG1]}[0..2];
             if($tag_type eq 'Tag') {
               _assert($tag_name eq 'emph');
               _assert($tag_contents eq 'nest');
             } elsif($tag_type eq 'Open_Tag') {
               _assert($tag_name eq 'para');
               _assert($tag_contents eq 'open');
             } elsif($tag_type eq 'Close_Tag') {
               _assert($tag_name eq 'para');
               _assert($tag_contents eq 'close');
             }
           },
  }
);

POE::Session->create (
  inline_states => {
    _start => sub {
                for(0..4) {
                  $_[KERNEL]->post ( inter_tag_mxml => 'get_tag' );
                }
              },
    Tag => sub {
             my ($tag_type,$tag_name,$tag_contents) = @{$_[ARG1]}[0..2];
             my $heap = $_[HEAP];
             if($tag_type eq 'Tag') {
               $heap->{tag}++;
               if($heap->{tag}==1) {
                 _assert($tag_name eq 'emph','tag was not "emph"');
                 _assert($tag_contents eq 'nest','contents were not "nest"');
               } elsif($heap->{tag}==2) {
                 _assert($tag_name eq 'emph','tag was not "emph"');
                 _assert($tag_contents eq 'nest2','contents were not "nest2"');
               }
             } elsif($tag_type eq 'Open_Tag') {
               _assert($tag_name eq 'para');
               _assert($tag_contents eq 'open');
             } elsif($tag_type eq 'Close_Tag') {
               _assert($tag_name eq 'para');
               _assert($tag_contents eq 'close');
             } elsif($tag_type eq 'Inter_Tag') {
               _assert($tag_name eq 'para');
               _assert($tag_contents eq 'inter');
             }
           },
  }
);

# Run it all until done.
$poe_kernel->run();

print "1..".@tests."\n";
print for @tests;

exit;

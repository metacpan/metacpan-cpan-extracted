package Package::Tent;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;
use Carp;

=head1 NAME

Package::Tent - temporary package infrastructure

=head1 SYNOPSIS

This module allows you to setup camp inside an existing module/program
with minimal commitment to filenames, while still being able to use the
same require/use statements of normal code.

  use Package::Tent sub {
    package Who::sYourDaddy;
    sub thing {
      print "hello world\n";
    }
    1;
  };
  use Package::Tent sub {
    package What::sInAName;
    use base 'Who::sYourDaddy';
    sub method {
      $_[0]->thing;
    }
    __PACKAGE__;
  };

  use What::sInAName;
  What::sInAName->method;

=head1 USAGE

The 'use Package::Tent sub {...}' statement is equivalent to wrapping
your package in a BEGIN block and setting an entry in %INC.

Note that the first example simply returns a true value, while the
second explicitly returns the package name using the __PACKAGE__ token.
You may use either method.

The implicit form will cause Package::Tent to attempt opening and
scanning the file containing the calling code.  The latter is more
robust in strange (PAR, @INC hooks, etc.) environments, but is less
convenient.

=head1 NOTES

It is not wise to install a datacenter in a tent.  Need I say more?

This module was designed to reduce development time by allowing me to
maintain my train of thought.  The scenario is that you're coding along
in some module or program and you realize the need for a support module
(or even a few of them.)  Package::Tent allows you to keep writing code
while you're thinking rather than stopping long enough to commit to a
name, create a file, maybe add it to version control, etc.

It should be similarly useful in single-file prototypes or other
experimental code.  Hopefully, lowering the file-juggling overhead
encourages you to start your code with a modular style.  When the
prototype becomes the finished product (as it so often does), the
refactoring is nearly mechanical as opposed to a difficult untangling of
ad-hoc variables.

=cut

=head1 Methods

=head2 import

  use Package::Tent sub {
    ...
  };

  Package::Tent->import($subref);

=cut

sub import {
  my $self = shift;
  @_ or return;
  my ($subref) = @_;

  ((ref($subref) || '') eq 'CODE') or croak("must be a subref");

  my ($p, $fn, $line) = caller;

  my $v = eval {$subref->()};
  $@ and die;
  $v or croak("$subref did not return a true value");

  unless($v =~ m/^[a-z][a-z0-9:_]*$/i) {
    $v = eval {$self->_find_package($fn, $line)};
    if($@) {
      croak($@, "\n\n  -- you should use the __PACKAGE__ tag\n\n  ");
    }
    $v or croak("failed to determine package name");
  }

  my $pf = $v . '.pm';
  $pf =~ s#::#/#g;
  $INC{$pf} = $fn;
} # end subroutine import definition
########################################################################

=head2 _find_package

  Package::Tent->_find_package($file, $line);

=cut

sub _find_package {
  my $self = shift;
  my ($file, $num) = @_;
  open(my $fh, '<', $file) or die("cannot open $file");

  my $pname = ref($self) || $self;

  use constant DBG => 0;

  DBG and warn "XX pname is $pname\n";

  my $ln = 0;
  my $in_use = 0;
  my $got_pack;
  while(my $line = <$fh>) {
    $ln++;
    DBG and warn "## $line";
    if($line =~ m/^\s*use \Q$pname\E *\(? *sub *\{(.*)/) {
      if(my $also = $1) {
        if($also =~ m/\bpackage ([\w:]+)/) {
          $got_pack = $1;
        }
      }
      else {
        $got_pack = undef;
      }
      DBG and warn "XX in_use\n";
      $in_use = 1;
    }
    elsif($in_use and ! defined($got_pack)) {
      DBG and warn "XX check\n";
      if($line =~ m/(?:^|;)\s*package ([\w:]+)/) {
        $got_pack = $1;
        DBG and warn "%% got $got_pack\n";
      }
    }
    ($ln >= $num) and last;
  }

  return($got_pack);
} # end subroutine _find_package definition
########################################################################

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2007 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;

package Template::Plugin::VMethods;

use strict;
#use warnings;

use Template::Plugin::VMethods::VMethodContainer;

# set up the default hash before we go adding things to it
use Template::Stash;

use Template::Plugin;
use vars qw(@ISA $VERSION);
@ISA = qw(Template::Plugin);

$VERSION = "0.03";

use constant OPS => [qw{ LIST_OPS SCALAR_OPS HASH_OPS }];

=head1 NAME

Template::Plugin::VMethods - install vmethods

=head1 SYNOPSIS

  package Template::Plugin::ReverseVMethod;
  use base qw(Template::Plugin::VMethods);
  @SCALAR_OPS = qw(reverse);

  sub reverse
  {
     my $string = shift;
     scalar reverse $string;
  }

  1;

=head1 DESCRIPTION

Simple base class to allow your module to install and remove
virtual methods into the Template Toolkit.

All you need to do in your package is declare one or more of the
variables @LIST_OPS, @SCALAR_OPS or @HASH_OPS to indicate what
virtual methods you want to export.

These can either be the names of functions in your package, or
name/subroutine reference pairs.

For example, using named functions:

  package Template::Plugin::HexVMethod;
  use base qw(Template::Plugin::VMethods);
  @SCALAR_OPS = ( "hex" );
  sub hex { sprintf "%x", $_[0] };
  1;

For example, using the name and subroutine ref pairs:

  package Template::Plugin::DoubleVMethod;
  use base qw(Template::Plugin::VMethods);
  @SCALAR_OPS = ( double => \&double_string);
  @LIST_OPS   = ( double => \&double_list);
  sub double_string  { $_[0]x2             }
  sub double_list    { [ (@{ $_[0] }) x 2] }
  1;

For example, mixing the two freely:

  package CaesarVMethod;
  use base qw(Template::Plugin::VMethods);
  @SCALAR_OPS = ( "caesar",
                  "rot13"   => sub { caesar($_[0],"13") } );
  sub caesar
  {
    $string = shift;
    $string =~ tr/A-Za-z/B-ZAb-za/ for 1..$_[0];
    return $string;
  }

=head2 Using VMethods Based Plugins

Once you've done this people can use your plugin just like they would
any other:

  [% USE CaesarVMethod %]
  [% foo = "Crbcyr jub yvxr gur pbybhe benatr ner fvyyl" %]
  The secret phrase is [% foo.rot13 %]

The vmethods will remain in effect till the end of the template,
meaning all templates called from within this template (i.e. via
PROCESS, INCLUDE, WRAPPER, etc) will be able to access the VMethods.

It's possible to permanently install the vmethods from perl space, so
that all instances of Template everywhere will always have access
to all the vmethods by using your plugin like so:

  use Template::Plugin::CaesarVMethod 'install';

=head2 Using subroutines from other classes.

Instead of writing virtual methods, you might be using the
B<Template::Plugin::Procedural> class:

  package Template::Plugin::MD5;
  use base qw(Template::Plugin::Procedural);
  use Digest::MD5;
  sub md5        { Digest::MD5::md5_hex(@_) };
  sub md5_base64 { Digest::MD5::md5_base64(@_) };
  1;

And you'll be calling the methods as so from within the template:

  [% USE MD5 %]
  [% MD5.md5(foo) %]

You'd rather use VMethods though, to do things like this:

  [% USE MD5VMethods %]
  [% foo.md5 %]

The obvious way to do this is to load the original class and take
references to those subroutines:

  package Template::Plugin::MD5VMethods;
  use base qw(Template::Plugin::VMethods);
  use Template::Plugin::MD5;
  @SCALAR_OPS = (md5        => \&Template::Plugin::MD5::md5,
                 md5_base64 => \&Template::Plugin::MD5::md5_base64);
  1;

This can get awfully tedious very soon when you're attempting to
re-wrap a class with many subroutines in it.  Because of this
B<Template::Plugin::VMethods> allows you to use a special variable
B<$VMETHOD_PACKAGE> which can be used to alter the package this module
uses to find named VMethods.

  package Template::Plugin::MD5VMethods;
  use base qw(Template::Plugin::VMethods);
  use Template::Plugin::MD5;
  $VMETHOD_PACKAGE = 'Template::Plugin::MD5';
  @SCALAR_OPS = qw(md5 md5_base64);
  1;

=cut

#### simple inheritable methods

sub new
{
  my $class = shift;
  my $context = shift;

  # check no-one is trying to create us directly
  if ($class eq __PACKAGE__)
    { die "This class must be subclassed, not instantiated directly" }

  # create a new object
  my $this = bless {}, $class;

  # install the vmethods
  $this->_install($context);

  # return the object
  return $this;
}

sub import
{
  my $class = shift;

  if (defined $_[0] && $_[0] eq "install")
    { $class->_install() }
}

sub _install
{
  my $class = shift;
  $class = ref $class if ref $class;

  # use another class?
  my $destclass;
  {
    no strict 'refs';
    $destclass = ${ $class . '::'. 'VMETHOD_PACKAGE' } || $class;
  }

  my $context = shift;

  # right, get data structure that we can work with
  my $data;
  foreach my $op (@{ OPS() })
  {
    # we need to access variables by name now
    # (like exporter does)
    no strict 'refs';

    # work out if we've got any ops declared
    my $varname = $class.'::'.$op;
    next unless @{$varname};

    # work out where we're going to stick them
    my $hashref = ${'Template::Stash::'.$op};

    # process each thingy
    my $count = 0;
    while ($count < @{$varname})
    {
      my $vmethname = $varname->[ $count ];
      $count++;

      # either get the subroutine from the namespace or
      # from the list
      my $sub;
      if (ref($varname->[ $count ]) && ref($varname->[ $count ]) eq "CODE")
      {
	# ah we've got a ref in the list, use that.
	$sub = $varname->[ $count ];
        $count++;
      }
      else
      {
        $sub = \&{ $destclass . '::' . $vmethname };
      }

      # do we want to be able to remove them again?
      if ($context)
      {
        # get the stash
	my $stash = $context->stash;

        # remember what was there originally if there was something there
        if (!defined $hashref->{ $vmethname })
	{
	  #print STDERR "Creating empty ref $op $vmethname\n";

	  $stash->set("origvmethod$op$vmethname",
	     Template::Plugin::VMethods::VMethodContainer->new(
                        $op,
			$vmethname,
			$stash,
          ));
        }
        elsif (!$stash->get("origvmethod$op$vmethname") ||
	       !$stash->get("origvmethod$op$vmethname")->stashmatch($stash))
	{
	  #print STDERR "Creating sub ref $op $vmethname\n";

	  $stash->set("origvmethod$op$vmethname",
	     Template::Plugin::VMethods::VMethodContainer->new(
                        $op,
			$vmethname,
			$stash,
   	 	        $hashref->{ $vmethname },

          ));
        }
      }

      # print what we're installing
      #use B::Deparse;
      #my $deparse = B::Deparse->new("-p", "-sC");
      #print STDERR "installing as a $op in $vmethname:\n";
      #print STDERR $deparse->coderef2text($sub)."\n";

      # install the new op
      $hashref->{ $vmethname } = $sub;
    }
  }
}

=head1 BUGS

This module has an 'import' and a 'new' method;  If you implement any of
these in your subclass you'll need to chain the methods like this:

   sub new
   {
      my $class = shift;
      my $this  = $class->SUPER::new(@_);

      ...
   }

Even if you manually redefine a VMethod that this module has defined
(by manually assigning to the $Template::Stash::*_OPS variables) then
that VMethod will still be restored to the value that it had before
the USE statement that installed the VMethod you are overriding as soon
as you leave the template that that USE method was declared in.

Sharing $Template::Stash::*_OPS across threads will really screw
this whole system up;  But you weren't going to do that anyway, were
you?

Further bugs (and requests for new features) can be reported to the
author though the CPAN RT system:
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-VMethods>

=head1 AUTHOR

Written by Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

Copyright Mark Fowler 2003.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

Caesar code example adapted from Crypt::Caesar by Juerd

=head1 SEE ALSO

L<Template::Stash>

=cut

1;

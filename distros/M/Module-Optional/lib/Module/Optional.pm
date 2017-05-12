package Module::Optional;
use strict;
use warnings;

BEGIN {
	use vars qw ($VERSION $AUTOLOAD);
	$VERSION     = 0.03;
}

=head1 NAME

Module::Optional - Breaking module dependency chains

=head1 SYNOPSIS

  use Bar::Dummy qw();
  use Module::Optional Bar;

=head1 ABSTRACT

This module provides a way of using a module which may or may not be installed
on the target machine. If the module is available it behaves as a straight 
use. If the module is not available, subs are repointed to their equivalents
in a dummy namespace.

=head1 DESCRIPTION

Suppose you are the developer of module C<Foo>, which uses functionality 
from the highly controversial module C<Bar>. You actually quite like C<Bar>,
and want to reuse its functionality in your C<Foo> module. But, many people 
will refuse to install C<Foo> as it needs C<Bar>. Maybe C<Bar> is failing 
tests or is misbehaving on some platforms.

Making C<Bar> an optional module will allow users to run C<Foo> that don't
have C<Bar> installed. For L<Module::Build> users, this involves changing 
the status of the C<Bar> dependency from C<requires> to C<recommends>.

To use this module, you need to set up a namespace C<Bar::Dummy>. The 
recommended way of doing this is to ship lib/Bar/Dummy.pm with your module.
This could be shipped as a standalone module. A dummy module for 
C<Params::Validate> is shipped with Module::Optional, as this was the 
original motivation for the module. If there are other common candidates 
for dummying, petition me, and I'll include them in the Module::Optional 
distribution.

=head2 Using an optional module

Place the lines of code in the following order:

  use Bar::Dummy qw();
  use Module::Optional qw(Bar quux wibble wobble);

Always set up the dummy module first, but don't import anything - this 
is to avoid warnings about redefined subroutines if the real Bar is 
installed on the target machine. Module::Optional will do the importing: 
quux wibble and wobble from the real Bar if it exists, or from Bar::Dummy
if it doesn't.

=head2 Asking for a module version

If you need a version of the module or later, this can be done thus:

  use Bar::Dummy qw();
  use Module::Optional qw(Bar 0.07 quux wibble wobble);

If version 0.07 or later of Bar is not available, the dummy is used.

=head2 Suppressing the module

You will probably be developing your module on a platform that does have 
Bar installed (I hope). However, you need to be able to tell what happens
on systems without Bar. To do this, run the following (example is Unix):

  MODULE_OPTIONAL_SKIP=1 make test

You also want to do this in tests for the dummy module that you are 
providing. (You are providing tests for this module?) This can easily be
done with a begin block at the top of the test:

  BEGIN {
      local $ENV{MODULE_OPTIONAL_SKIP} = 1;
      use Module::Optional qw(Params::Validate);
  }

=head2 Writing a ::Dummy Module

You provide a namespace suffixed with ::Dummy containing subs corresponding
to all the subs and method calls for the optional module. You should also 
provide the same exports as the module itself performs.

Adhere strictly to any prototypes in the optional module.

An example of a dummy module is Params::Validate::Dummy, provided in 
this distribution.

=head1 INTERNALS

Module::Optional performs two types of redirection for the missing module.
Firstly via @ISA inheritance - Foo::Bar inherits from Foo::Bar::Dummy.

Secondly, an AUTOLOAD method is added to Foo::Bar, which will catch calls 
to subs in this namespace.

=head1 BUGS

Please report bugs to rt.cpan.org by posting to 
bugs-module-optional@rt.cpan.org or visiting 
https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Optional.

=head1 AUTHOR

	Ivor Williams
	ivorw-mod-opt at xemaps.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Test::MockModule>, L<Module::Pluggable>, L<Module::Build>.

=cut

use Carp;

sub import {
    my $this = shift;
    my $module = shift or croak "Module name not passed";
    my $calling_pkg = (caller())[0];
    local $"=' ';
    my $evs = <<EVAL;

package $calling_pkg;
use $module qw(@_);
EVAL

    $evs =~ s/\sqw\(\)//; # @EXPORT for empty arg list
    eval ($ENV{MODULE_OPTIONAL_SKIP} ? "'poo" : $evs);
    if ($@) {
#        warn "Eval failed: $@";
    	no strict 'refs';

	push @{$module.'::ISA'},$module.'::Dummy';
	*{"${module}::AUTOLOAD"} = \&_autoload;
	$evs =~ s/$module/${module}::Dummy/;
	$evs =~ s/qw\(\d\S+\s/qw(/;
	eval $evs;
    }
#    else {
#    	warn "eval successful: $evs";
#    }
}

sub _autoload {
    my ($mod,$func) = $AUTOLOAD =~ /(.+)::(\w+)$/;
    my $dummy_mod = "${mod}::Dummy";
    my $dummy_sub = "${dummy_mod}::$func";

    if (!$dummy_mod->can($func)) {
	croak "No sub $func default for optional module $mod"
		unless $dummy_mod->can('AUTOLOAD');
	no strict 'refs';

	goto &{"${dummy_mod}::AUTOLOAD"};
    }

    no strict 'refs';
    *$AUTOLOAD = \&$dummy_sub;
    goto &$AUTOLOAD;
}
1; #this line is important and will help the module return a true value
__END__


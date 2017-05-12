package Module::Stubber::Stub;
use strict;
use warnings;
use base qw(Exporter);

our $AUTOLOAD;
our %Retvals;
our @EXPORT;

our $MSG_FMT = <<EOS;
*** '%s' requested at %s:%d
*** This symbol does not really exist, and has been
*** implemented as a stub by Module::Stubber.
*** Depending on how important
*** this function is, this program may not function
*** correctly. This message will only display once.
EOS

our %Warncache;
sub _can_warn($) {
    my $key = shift;
    (my $cls = $key) =~ s/::[^:]+$//g;
    return !(exists $Warncache{$cls} || exists $Warncache{$key});
}

sub AUTOLOAD {
    my $arg = shift;
    my $fn  = $AUTOLOAD;
    my @callinfo = caller(0);
    my ($pkg,$fname,$line,$subname) = @callinfo[0..3];
    if(_can_warn($fn)) {    
        printf STDERR ($MSG_FMT, $fn, $fname, $line);
        $Warncache{$fn} = 1;
    }
    
    if(!exists $Retvals{$fn}) {
        return $arg if ref $arg;
        return 1;
    }
    
    return $Retvals{$fn};
}

sub new {
    my $cls = shift;
    my $s = "Dummy Object";
    my ($pkg,$file,$line) = caller();
    printf STDERR $MSG_FMT, $cls . "::new", $file, $line if _can_warn($cls . "::new");
    bless \$s, $cls;
}

sub import {
    my ($cls,@options) = @_;
    my @esyms = grep { !ref $_ && $_ =~ m/^[a-zA-Z_\$\@\%\&]/ } @options;
    no strict 'refs';
    
    @{$cls.'::EXPORT'} = @esyms;
    *{$cls.'::AUTOLOAD'} = \&AUTOLOAD;
    @_ = ($cls,@esyms);
    goto &Exporter::import;
}

package Module::Stubber;
use strict;
use warnings;
our %Status;
our $VERSION = '0.03';

my $USAGE_ERR = sprintf("Usage: use %s ".
    "Pkg::Name => [ 'import', 'options' ], extra => 'options'",
    __PACKAGE__);

sub import {
    my ($cls,$wanted_pkg,$import_params,%options) = @_;
    my ($caller,$ifname,$ifline) = caller();
    if(!$wanted_pkg) {
        die $USAGE_ERR;
    }
    
    my $pkg_s = $wanted_pkg;
    $pkg_s =~ s,::,/,g;
    $pkg_s .= ".pm";
    
    @_ = ($wanted_pkg, @$import_params);
    if(eval { require $pkg_s }
       && !$wanted_pkg->isa('Module::Stubber::Stub') ) {
        $Status{$wanted_pkg} = 1;
        goto &{$wanted_pkg->can('import') || sub () { } };
    } else {
        warn(__PACKAGE__ . ": ".$@);
        $Status{$wanted_pkg} = 0;
        $INC{$pkg_s} = 1;
        no strict 'refs';
        @{$wanted_pkg . '::ISA'} = 'Module::Stubber::Stub';
        my $more_syms = $options{will_use};
        if(ref $more_syms eq 'ARRAY') {
            push @_, @$more_syms;
        } else {
            no strict 'refs';
            while (my ($sym,$symspec) = each %$more_syms) {
                if(ref $symspec eq 'CODE') {
                    *{$wanted_pkg."::$sym"} = $symspec;
                } else {
                    $Module::Stubber::Stub::Retvals{$wanted_pkg."::$sym"} = $symspec;
                }
                push @_, $sym;
            }
        }
        if($options{silent}) {
            $Module::Stubber::Stub::Warncache{$wanted_pkg} = 1;
        }
        
        goto &Module::Stubber::Stub::import;
    }
}

1;

__END__

=head1 NAME

Module::Stubber - Import possibly unavailable modules and their exported symbols
as stub functions, objects, and methods

=head1 SYNOPSIS

    use Module::Stubber 'Possibly::Unavailable::Module' => [qw(some symbols)];
    
    some();
    symbols();
    
    my $maybe_dummy = Possibly::Unavailable::Module->new();
    $maybe_dummy->anything();
    
=head2 DESCRIPTION

Module::Stubber lets you create dummy stubs for modules which may not be importable,
either because they are not a hard dependency for your code, or they do not
function correctly on the target platform.

The proper usage for C<Module::Stubber> is

    use Module::Stubber $module_name => $import_spec, other => options;
    
Thus, assuming the module C<My::Foo> is installed, calling

    use Module::Stubber 'My::Foo' => [(foo_frob foo_bork)];
    
is equivalent to
    
    use My::Foo qw(foo_frob foo_bork);
    
=head3 OPTIONS

The following options are currently supported, and may be passed as hash keys
after the import spec

=over

=item will_use

C<will_use> allows for extended symbol specifications if the module is not available.

It can take one of two value types:

=over

=item Array Reference

This is a simple list of symbol names to append to the stub's functions.

=item Hash Reference

This is a more detailed specification of symbols, and will let you specify a
default value or replacement subroutine for each symbol listed.

    use Module::Stubber
        'My::Foo' => [qw(foo_frob foo_bork)],
        will_use => {
            foo_frob => 42,
            foo_bork => sub {
                warn("We're already borked!")
            }
        };
    
    my $answer_to_everything = foo_frob(); # 42
    foo_bork(); # prints a warning
    
=back

=item silent

Set this to true to disable printing initial warning messages when stubs are used
in code. See L</Warning Messages> for more information.

=back

=head3 MISCELLANY


=over

=item Warning Messages

The stub methods and functions created will print a warning message that looks
something like 

    *** '%s' requested at %s:%d
    *** This symbol does not really exist, and has been
    *** implemented as a stub by Module::Stubber.
    *** Depending on how important
    *** this function is, this program may not function
    *** correctly. This message will only display once.

only once.

The message is a package variable found at C<$Module::Stubber::Stub::MSG_FMT>.
It is a format string; the first parameter is the function name, the second
is the filename of the caller of this function, and the third is the line number.

The printing of this message is dependent on another package-level hash,
C<%Module::Stubber::Sub::Warncache>.

Often it is desirable to have these messages print, but this may sometimes be
impractical, especially for many methods. To silence the initial printing, simply
place a hash entry under those method names - which must be fully qualified.


=item Module Load Status

You can check to see if a real module loaded successfully by inspecting the
C<%Module::Stubber::Status> hash. Keys are module names, and values are true or
false, depending on whether the module was loaded or not.

=back

=head2 RATIONALE

There are quite a few 'see if this module exists' handlers on CPAN. None of them
(to my knowledge) allow you to actually do the hard part and specify stub replacements.

I wrote this module because I needed a way to include debugging/development
modules on a project of mine, while being able to test core functionality on
other systems which did not/could not have those development modules installed.

This module can become quite handy when the core purpose of the modules being used
are mainly informative and with a simple API. For more complicated scenarios when
the functionality of the desired module is actually B<needed>, you might want to
consider L<maybe>, L<if>, and L<first>, and others.

=head2 SEE ALSO

L<maybe>

L<if>

L<Module::Load::Conditional>

L<Package::Butcher> - Provides a different and more comprehensive API

=head1 AUTHOR AND COPYRIGHT

Copyright (C) 2011 M. Nunberg

You may use and distribute this module under the same terms as Perl itself.


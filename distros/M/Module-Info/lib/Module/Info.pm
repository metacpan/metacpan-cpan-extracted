package Module::Info;

use 5.006;
use strict;
use warnings;
use Carp;
use File::Spec;
use Config;

my $has_version_pm = eval 'use version; 1';

our $AUTOLOAD;
our $VERSION;

$VERSION = eval 'use version; 1' ? 'version'->new('0.39') : '0.39';
$VERSION = eval $VERSION;


=head1 NAME

Module::Info - Information about Perl modules

=head1 SYNOPSIS

  use Module::Info;

  my $mod = Module::Info->new_from_file('Some/Module.pm');
  my $mod = Module::Info->new_from_module('Some::Module');
  my $mod = Module::Info->new_from_loaded('Some::Module');

  my @mods = Module::Info->all_installed('Some::Module');

  my $name    = $mod->name;
  my $version = $mod->version;
  my $dir     = $mod->inc_dir;
  my $file    = $mod->file;
  my $is_core = $mod->is_core;

  # Only available in perl 5.6.1 and up.
  # These do compile the module.
  my @packages = $mod->packages_inside;
  my @used     = $mod->modules_used;
  my @subs     = $mod->subroutines;
  my @isa      = $mod->superclasses;
  my @calls    = $mod->subroutines_called;

  # Check for constructs which make perl hard to predict.
  my @methods   = $mod->dynamic_method_calls;
  my @lines     = $mod->eval_string;    *UNIMPLEMENTED*
  my @lines     = $mod->gotos;          *UNIMPLEMENTED*
  my @controls  = $mod->exit_via_loop_control;      *UNIMPLEMENTED*
  my @unpredictables = $mod->has_unpredictables;    *UNIMPLEMENTED*

  # set/get Module::Info options
  $self->die_on_compilation_error(1);
  my $die_on_error = $mod->die_on_compilation_error;
  $self->safe(1);
  my $safe = $mod->safe;

=head1 DESCRIPTION

Module::Info gives you information about Perl modules B<without
actually loading the module>.  It actually isn't specific to modules
and should work on any perl code.

=head1 METHODS

=head2 Constructors

There are a few ways to specify which module you want information for.
They all return Module::Info objects.

=over 4

=item new_from_file

  my $module = Module::Info->new_from_file('path/to/Some/Module.pm');

Given a file, it will interpret this as the module you want
information about.  You can also hand it a perl script.

If the file doesn't exist or isn't readable it will return false.

=cut

sub new_from_file {
    my($proto, $file) = @_;
    my($class) = ref $proto || $proto;

    return unless -r $file;

    my $self = {};
    $self->{file} = File::Spec->rel2abs($file);
    $self->{dir}  = '';
    $self->{name} = '';
    $self->{safe} = 0;
    $self->{use_version} = 0;

    return bless $self, $class;
}

=item new_from_module

  my $module = Module::Info->new_from_module('Some::Module');
  my $module = Module::Info->new_from_module('Some::Module', @INC);

Given a module name, @INC will be searched and the first module found
used.  This is the same module that would be loaded if you just say
C<use Some::Module>.

If you give your own @INC, that will be used to search instead.

=cut

sub new_from_module {
    my($class, $module, @inc) = @_;
    return ($class->_find_all_installed($module, 1, @inc))[0];
}

=item new_from_loaded

  my $module = Module::Info->new_from_loaded('Some::Module');

Gets information about the currently loaded version of Some::Module.
If it isn't loaded, returns false.

=cut

sub new_from_loaded {
    my($class, $name) = @_;

    my $mod_file = join('/', split('::', $name)) . '.pm';
    my $filepath = $INC{$mod_file} || '';

    my $module = Module::Info->new_from_file($filepath) or return;
    $module->{name} = $name;
    ($module->{dir} = $filepath) =~ s|/?\Q$mod_file\E$||;
    $module->{dir} = File::Spec->rel2abs($module->{dir});
    $module->{safe} = 0;
    $module->{use_version} = 0;

    return $module;
}

=item all_installed

  my @modules = Module::Info->all_installed('Some::Module');
  my @modules = Module::Info->all_installed('Some::Module', @INC);

Like new_from_module(), except I<all> modules in @INC will be
returned, in the order they are found.  Thus $modules[0] is the one
that would be loaded by C<use Some::Module>.

=cut

sub all_installed {
    my($class, $module, @inc) = @_;
    return $class->_find_all_installed($module, 0, @inc);
}

# Thieved from Module::InstalledVersion
sub _find_all_installed {
    my($proto, $name, $find_first_one, @inc) = @_;
    my($class) = ref $proto || $proto;

    @inc = @INC unless @inc;
    my $file = File::Spec->catfile(split /::/, $name) . '.pm';

    my @modules = ();
    DIR: foreach my $dir (@inc) {
        # Skip the new code ref in @INC feature.
        next if ref $dir;

        my $filename = File::Spec->catfile($dir, $file);
        if( -r $filename ) {
            my $module = $class->new_from_file($filename);
            $module->{dir} = File::Spec->rel2abs($dir);
            $module->{name} = $name;
            push @modules, $module;
            last DIR if $find_first_one;
        }
    }

    return @modules;
}


=back

=head2 Information without loading

The following methods get their information without actually compiling
the module.

=over 4

=item B<name>

  my $name = $module->name;
  $module->name($name);

Name of the module (ie. Some::Module).

Module loaded using new_from_file() won't have this information in
which case you can set it yourself.

=cut

sub name {
    my($self) = shift;

    $self->{name} = shift if @_;
    return $self->{name};
}

=item B<version>

  my $version = $module->version;

Divines the value of $VERSION.  This uses the same method as
ExtUtils::MakeMaker and all caveats therein apply.

=cut

# Thieved from ExtUtils::MM_Unix 1.12603
sub version {
    my($self) = shift;
    local($_, *MOD);

    my $parsefile = $self->file;
    my $safe = $self->safe;

    open(MOD, $parsefile) or die $!;

    my $inpod = 0;
    my $result;
    while (<MOD>) {
        $inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
        next if $inpod || /^\s*#/;

        chomp;
        # taken from ExtUtils::MM_Unix 6.63_02
        next if /^\s*(if|unless|elsif)/;
        if (m{^\s*package\s+\w[\w\:\']*\s+(v?[0-9._]+)\s*;}) {
            local $^W = 0;
            $result = $1;
            last;
        }
        next unless /([\$*])(([\w\:\']*)\bVERSION)\b.*\=/;
        my $eval = sprintf qq{
                      package Module::Info::_version;
                      %s

                      local $1$2;
                      \$$2=undef; do {
                          %s
                      }; \$$2
        }, ( $safe ? '' : 'no strict;' ), $_;
        local $^W = 0;
        $result = $self->_eval($eval);
        warn "Could not eval '$eval' in $parsefile: $@" if $@ && !$safe;
        $result = "undef" unless defined $result;
        last;
    }
    close MOD;
    $result = 'version'->new($result) # quotes for 5.004
      if    $self->use_version
         && (!ref($result) || !UNIVERSAL::isa($result, "version"));
    return $result;
}


=item B<inc_dir>

  my $dir = $module->inc_dir;

Include directory in which this module was found.  Module::Info
objects created with new_from_file() won't have this info.

=cut

sub inc_dir {
    my($self) = shift;

    return $self->{dir};
}

=item B<file>

  my $file = $module->file;

The absolute path to this module.

=cut

sub file {
    my($self) = shift;

    return $self->{file};
}

=item B<is_core>

  my $is_core = $module->is_core;

Checks if this module is the one distributed with Perl.

B<NOTE> This goes by what directory it's in.  It's possible that the
module has been altered or upgraded from CPAN since the original Perl
installation.

=cut

sub is_core {
    my($self) = shift;

    return scalar grep $self->{dir} eq File::Spec->canonpath($_), 
                           ($Config{installarchlib},
                            $Config{installprivlib},
                            $Config{archlib},
                            $Config{privlib});
}

=item B<has_pod>

    my $has_pod = $module->has_pod;

Returns the location of the module's pod, which can be the module file itself, 
if the POD is inlined, the associated POD file, or nothing if there is no POD 
at all.

=cut

sub has_pod {
    my $self = shift; 

    my $filename = $self->file;
    
    open my $file, "<", $filename or return; # the file won't even open 
    
    while( <$file> ) { 
        return $filename if /^=[a-z]/; 
    } 

    # nothing found? Try a companion POD file

    $filename =~ s/\.[^.]+$/.pod/ or return;

    return unless -f $filename;

    open $file, "<", $filename or return;
    
    while( <$file> ) { 
        return $filename if /^=[a-z]/; 
    } 
    
    return;
}

=back

=head2 Information that requires loading.

B<WARNING!>  From here down reliability drops rapidly!

The following methods get their information by compiling the module
and examining the opcode tree.  The module will be compiled in a
separate process so as not to disturb the current program.

They will only work on 5.6.1 and up and requires the B::Utils module.

=over 4

=item B<packages_inside>

  my @packages = $module->packages_inside;

Looks for any explicit C<package> declarations inside the module and
returns a list.  Useful for finding hidden classes and functionality
(like Tie::StdHandle inside Tie::Handle).

B<KNOWN BUG> Currently doesn't spot package changes inside subroutines.

=cut

sub packages_inside {
    my $self = shift;

    my %packs = map {$_, 1} $self->_call_B('packages');
    return keys %packs;
}

=item B<package_versions>

  my %versions = $module->package_versions;

Returns a hash whose keys are the packages contained in the module
(these are the same as what's returned by C<packages_inside()>), and
whose values are the versions of those packages.

=cut

sub package_versions {
    my $self = shift;

    my @packs = $self->packages_inside;

    # To survive the print(), we translate undef into '~' and then back again.
    (my $quoted_file = $self->file) =~ s/(['\\])/\\$1/g;
    my $command = qq{-le "require '$quoted_file';};
    foreach (@packs) {
        $command .= " print defined $_->VERSION ? $_->VERSION : '~';"
    }
    $command .= qq{"};

    my ($status, @versions) = $self->_call_perl($command);
    chomp @versions;
    foreach (@versions) {
        $_ = undef if $_ eq '~';
    }

    my %map;
    @map{@packs} = @versions;

    return %map;
}


=item B<modules_used>

  my @used = $module->modules_used;

Returns a list of all modules and files which may be C<use>'d or
C<require>'d by this module.

B<NOTE> These modules may be conditionally loaded, can't tell.  Also
can't find modules which might be used inside an C<eval>.

=cut

sub modules_used {
    my($self) = shift;
    my %used = $self->modules_required;

    return keys %used;
}

=item B<modules_required>

  my %required = $module->modules_required;

Returns a list of all modules and files which may be C<use>'d or
C<require>'d by this module, together with the minimum required version.

The hash is keyed on the module/file name, the corrisponding value is
an array reference containing the requied versions, or an empty array
if no specific version was required.

B<NOTE> These modules may be conditionally loaded, can't tell.  Also
can't find modules which might be used inside an C<eval>.

=cut

sub modules_required {
    my($self) = shift;

    my $mod_file = $self->file;
    my @mods = $self->_call_B('modules_used');

    my @used_mods = ();
    my %used_mods = ();
    for (grep /^use \D/ && /at "\Q$mod_file\E" /, @mods) {
        my($file, $version) = /^use (\S+) \(([^\)]*)\)/;
        $used_mods{_file2mod($file)} ||= [];
        next unless defined $version and length $version;

        push @{$used_mods{_file2mod($file)}}, $version;
    }

    push @used_mods, map { my($file) = /^require bare (\S+)/; _file2mod($file) }
                     grep /^require bare \D/ , @mods;

    push @used_mods, map { /^require not bare (\S+)/; $1 }
                     grep /^require not bare \D/, @mods;

    foreach ( @used_mods ) { $used_mods{$_} = [] };
    return %used_mods;
}

sub _file2mod {
    my($mod) = shift;
    $mod =~ s/\.pm//;
    $mod =~ s|/|::|g;
    return $mod;
}


=item B<subroutines>

  my %subs = $module->subroutines;

Returns a hash of all subroutines defined inside this module and some
info about it.  The key is the *full* name of the subroutine
(ie. $subs{'Some::Module::foo'} rather than just $subs{'foo'}), value
is a hash ref with information about the subroutine like so:

    start   => line number of the first statement in the subroutine
    end     => line number of the last statement in the subroutine

Note that the line numbers may not be entirely accurate and will
change as perl's backend compiler improves.  They typically correspond
to the first and last I<run-time> statements in a subroutine.  For
example:

    sub foo {
        package Wibble;
        $foo = "bar";
        return $foo;
    }

Taking C<sub foo {> as line 1, Module::Info will report line 3 as the
start and line 4 as the end.  C<package Wibble;> is a compile-time
statement.  Again, this will change as perl changes.

Note this only catches simple C<sub foo {...}> subroutine
declarations.  Anonymous, autoloaded or eval'd subroutines are not
listed.

=cut

sub subroutines {
    my($self) = shift;

    my $mod_file = $self->file;
    my @subs = $self->_call_B('subroutines');
    return  map { /^(\S+) at "[^"]+" from (\d+) to (\d+)/;
                  ($1 => { start => $2, end => $3 }) }
            grep /at "\Q$mod_file\E" /, @subs;
}

sub _get_extra_arguments { '' }

sub _call_B {
    my($self, $arg) = @_;

    my $mod_file = $self->file;
    my $extra_args = $self->_get_extra_arguments;
    my $command = qq{$extra_args "-MO=Module::Info,$arg" "$mod_file"};
    my($status, @out) = $self->_call_perl($command);

    if( $status ) {
        my $exit = $status >> 8;
        my $msg = join "\n",
                       "B::Module::Info,$arg use failed with $exit saying:",
                       @out;

        if( $self->{die_on_compilation_error} ) {
            die $msg;
        }
        else {
            warn $msg;
            return;
        }
    }

    @out = grep !/syntax OK$/, @out;
    chomp @out;
    return @out;
}


=item B<superclasses>

  my @isa = $module->superclasses;

Returns the value of @ISA for this $module.  Requires that
$module->name be set to work.

B<NOTE> superclasses() is currently cheating.  See L<CAVEATS> below.

=cut

sub superclasses {
    my $self = shift;

    my $mod_file = $self->file;
    my $mod_name = $self->name;
    unless( $mod_name ) {
        carp 'isa() requires $module->name to be set';
        return;
    }

    my $extra_args = $self->_get_extra_arguments;
    my $command =
      qq{-e "require q{$mod_file}; print join qq{\\n}, \@$mod_name\::ISA"};
    my($status, @isa) = $self->_call_perl("$extra_args $command");
    chomp @isa;
    return @isa;
}

=item B<subroutines_called>

  my @calls = $module->subroutines_called;

Finds all the methods and functions which are called inside the
$module.

Returns a list of hashes.  Each hash represents a single function or
method call and has the keys:

    line        line number where this call originated
    class       class called on if its a class method
    type        function, symbolic function, object method, 
                class method, dynamic object method or 
                dynamic class method.
                (NOTE  This format will probably change)
    name        name of the function/method called if not dynamic


=cut

sub subroutines_called {
    my($self) = shift;

    my @subs = $self->_call_B('subs_called');
    my $mod_file = $self->file;

    @subs = grep /at "\Q$mod_file\E" line/, @subs;
    my @out = ();
    foreach (@subs) {
        my %info = ();
        ($info{type}) = /^(.+) call/;
        $info{type} = 'symbolic function' if /using symbolic ref/;
        ($info{'name'}) = /to (\S+)/;
        ($info{class})= /via (\S+)/;
        ($info{line}) = /line (\d+)/;
        push @out, \%info;
    }
    return @out;
}

=back

=head2 Information about Unpredictable Constructs

Unpredictable constructs are things that make a Perl program hard to
predict what its going to do without actually running it.  There's
nothing wrong with these constructs, but its nice to know where they
are when maintaining a piece of code.

=over 4

=item B<dynamic_method_calls>

  my @methods = $module->dynamic_method_calls;

Returns a list of dynamic method calls (ie. C<$obj->$method()>) used
by the $module.  @methods has the same format as the return value of
subroutines_called().

=cut

sub dynamic_method_calls {
    my($self) = shift;
    return grep $_->{type} =~ /dynamic/, $self->subroutines_called;
}

=back

=head2 Options

The following methods get/set specific option values for the
Module::Info object.

=over 4

=item B<die_on_compilation_error>

  $module->die_on_compilation_error(0); # default
  $module->die_on_compilation_error(1);
  my $flag = $module->die_on_compilation_error;

Sets/gets the "die on compilation error" flag. When the flag is off
(default), and a module fails to compile, Module::Info simply emits a
watning and continues. When the flag is on and a module fails to
compile, Module::Info C<die()>s with the same error message it would use
in the warning.

=cut

sub die_on_compilation_error {
    my($self) = shift;

    $self->{die_on_compilation_error} = $_[0] ? 1 : 0 if @_;
    return $self->{die_on_compilation_error};
}

=item B<safe>

  $module->safe(0); # default
  $module->safe(1); # be safer
  my $flag = $module->safe;

Sets/gets the "safe" flag. When the flag is enabled all operations
requiring module compilation are forbidden and the C<version()> method
executes its code in a C<Safe> compartment.

=cut

sub safe {
    my($self) = shift;

    if( @_ ) {
        $self->{safe} = $_[0] ? 1 : 0;
        require Safe if $self->{safe};
    }
    return $self->{safe};
}

sub AUTOLOAD {
    my($super) = $_[0]->safe ? 'Module::Info::Safe' : 'Module::Info::Unsafe';
    my($method) = $AUTOLOAD;
    $method =~ s/^.*::([^:]+)$/$1/;

    return if $method eq 'DESTROY';

    my($code) = $super->can($method);

    die "Can not find method '$method' in Module::Info" unless $code;

    goto &$code;
}

=item B<use_version>

  $module->use_version(0); # do not use version.pm (default)
  $module->use_version(1); # use version.pm, die if not present
  my $flag = $module->use_version;

Sets/gets the "use_version" flag. When the flag is enabled the 'version'
method always returns a version object.

=cut

sub use_version {
    my($self) = shift;

    if( @_ ) {
        die "Can not use 'version.pm' as requested"
          if $_[0] && !$has_version_pm;

        $self->{use_version} = $_[0] ? 1 : 0;
    }

    return $self->{use_version};
}

=back

=head1 REPOSITORY

L<https://github.com/neilb/Module-Info>

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com> with code from ExtUtils::MM_Unix,
Module::InstalledVersion and lots of cargo-culting from B::Deparse.

Mattia Barbon <mbarbon@cpan.org> maintained
the module from 2002 to 2013.

Neil Bowers <neilb@cpan.org> is the current maintainer.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 THANKS

Many thanks to Simon Cozens and Robin Houston for letting me chew
their ears about B.

=head1 CAVEATS

Code refs in @INC are currently ignored.  If this bothers you submit a
patch.

superclasses() is cheating and just loading the module in a separate
process and looking at @ISA.  I don't think its worth the trouble to
go through and parse the opcode tree as it still requires loading the
module and running all the BEGIN blocks.  Patches welcome.

I originally was going to call superclasses() isa() but then I
remembered that would be bad.

All the methods that require loading are really inefficient as they're
not caching anything.  I'll worry about efficiency later.

=cut

package Module::Info::Safe;

my $root = 'Module::Info::Safe::_safe';

sub _create_compartment {
    my $safe = Safe->new( $root );

    $safe->permit_only( qw(:base_orig :base_core) );

    return $safe;
}

sub _eval {
    my($self, $code) = @_;
    $self->{compartment} ||= _create_compartment;

    return $self->{compartment}->reval( $code, 0 )
}

sub _call_perl {
    die "Module::Info attemped an unsafe operation while in 'safe' mode.";
}

package Module::Info::Unsafe;

sub _eval { eval($_[1]) }

sub _is_win95() {
    return $^O eq 'MSWin32' && (Win32::GetOSVersion())[4] == 1;
}

sub _is_macos_classic() {
    return $^O eq 'MacOS';
}

sub _call_perl {
    my($self, $args) = @_;

    my $perl = _is_macos_classic ? 'perl' : $^X;
    my $command = "$perl $args";
    my @out;

    if( _is_win95 ) {
        require IPC::Open3;
        local *OUTFH;
        my($line, $in);
        my $out = \*OUTFH;
        my $pid = IPC::Open3::open3($in, $out, $out, $command);
        close $in;
        while( defined($line = <OUTFH>) ) {
            $line =~ s/\r\n$/\n/; # strip CRs
            push @out, $line;
        }

        waitpid $pid, 0;
    }
    elsif( _is_macos_classic ) {
        @out = `$command \xb7 Dev:Stdout`;
    }
    else {
        @out = `$command 2>&1`;
    }

    @out = grep !/^Using.*blib$/, @out;
    return ($?, @out);
}

return 'Stepping on toes is what Schwerns do best!  *poing poing poing*';

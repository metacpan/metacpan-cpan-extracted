#!/usr/bin/perl

# recursively find NEEDED (in the ELF sense) shared libraries 
# for a given share library or for all installed Perl "glue" libraries

use strict;
use warnings;

use File::Spec;
use File::Find;
use File::Basename;

package DLL
{
    use strict;
    use warnings;
    use Capture::Tiny qw(:all);

    our ($show_system_libs, $show_perl_libs);   # default: don't show

    my @dll_path = File::Spec->path;            # Windows
    # my @dll_path = qw(/lib /lib/x86_64-linux-gnu /usr/lib /usr/lib/x86_64-linux-gnu);
    # + $ENV{LD_LIBRARY_PATH} if set
    #                                           Linux (Debian multi-arch)
    # maybe use "gcc -print-search-dirs" (pathnames may need canonicalization)
    #   install: /usr/lib/gcc/x86_64-linux-gnu/4.9/
    #   programs: =/usr/lib/gcc/x86_64-linux-gnu/4.9/:/usr/lib/gcc/x86_64-linux-gnu/4.9/:/usr/lib/gcc/x86_64-linux-gnu/:/usr/lib/gcc/x86_64-linux-gnu/4.9/:/usr/lib/gcc/x86_64-linux-gnu/:/usr/lib/gcc/x86_64-linux-gnu/4.9/../../../../x86_64-linux-gnu/bin/x86_64-linux-gnu/4.9/:/usr/lib/gcc/x86_64-linux-gnu/4.9/../../../../x86_64-linux-gnu/bin/x86_64-linux-gnu/:/usr/lib/gcc/x86_64-linux-gnu/4.9/../../../../x86_64-linux-gnu/bin/
    #   libraries: =/usr/lib/gcc/x86_64-linux-gnu/4.9/:/usr/lib/gcc/x86_64-linux-gnu/4.9/../../../../x86_64-linux-gnu/lib/x86_64-linux-gnu/4.9/:/usr/lib/gcc/x86_64-linux-gnu/4.9/../../../../x86_64-linux-gnu/lib/x86_64-linux-gnu/:/usr/lib/gcc/x86_64-linux-gnu/4.9/../../../../x86_64-linux-gnu/lib/../lib/:/usr/lib/gcc/x86_64-linux-gnu/4.9/../../../x86_64-linux-gnu/4.9/:/usr/lib/gcc/x86_64-linux-gnu/4.9/../../../x86_64-linux-gnu/:/usr/lib/gcc/x86_64-linux-gnu/4.9/../../../../lib/:/lib/x86_64-linux-gnu/4.9/:/lib/x86_64-linux-gnu/:/lib/../lib/:/usr/lib/x86_64-linux-gnu/4.9/:/usr/lib/x86_64-linux-gnu/:/usr/lib/../lib/:/usr/lib/gcc/x86_64-linux-gnu/4.9/../../../../x86_64-linux-gnu/lib/:/usr/lib/gcc/x86_64-linux-gnu/4.9/../../../:/lib/:/usr/lib/

    require Tie::CPHash;
    tie my %cache, "Tie::CPHash";

    sub name    { shift->{name} }
    sub path    { shift->{path} }


    sub find                            # class method
    {
        my ($class, $name) = @_;
        unless ($cache{$name})
        {
            my $found;
            foreach (@dll_path)
            {
                my $path = File::Spec->catfile($_, $name);
                $found = $path, last if -e $path;
            }

            $cache{$name} = bless {
                name    => $name,
                path    => $found,
            }, $class;
        }
        return $cache{$name};
    }

    sub needed
    {
        my ($self, $path) = @_;
        if (ref $self)
        {
            return @{ $self->{needed} } if $self->{needed};
            $path = $self->{path};
            die "can't find DLL $self->{name}" unless defined $path;
        }
        else
        {
            die __PACKAGE__."->needed: argument PATH missing" unless defined $path;
        }

        my ($out, $err, $exit) = capture { system(qw( objdump -ax ), $path) };
        die qq["objdump -ax $path" failed: $err] unless $exit == 0;

        my @needed = map { __PACKAGE__->find($_) } 
                         $out =~ /^\s*DLL Name:\s*(\S+)/gm;     # Windows
        #                $out =~ /^\s*NEEDED\s+(\S+)/gm;        # Linux
        $self->{needed} = \@needed if ref $self;
        return @needed;
    }


    sub depends
    {
        my ($self, $path) = @_;
        if (ref $self)
        {
            $path = $self->{path};
            die "can't find DLL $self->{name}" unless defined $path;
        }
        else
        {
            die __PACKAGE__."->depends argument PATH missing" unless defined $path;
        }

        tie my %seen, "Tie::CPHash";
        $seen{$self->name} = $self if ref $self;
        _depends(\%seen, $self->needed($path));
        return values %seen;
    }

    sub _depends
    {
        my ($seen, @needed) = @_;

        foreach (@needed)
        {
            next if $seen->{$_->name};
            if (defined $_->path)
            {
                next if $_->is_system_lib && !$show_system_libs;
                next if $_->is_perl_lib   && !$show_perl_libs;
            }

            $seen->{$_->name} = $_;
            _depends($seen, $_->needed) if defined $_->path;
        }
    }

    sub canon_path
    {
        my ($self) = @_;
        return unless defined $_->path;

        return $_->{canon_path} ||= _canon_path($_->path);
    }

    sub _canon_path
    {
        my ($path, $no_file) = @_;

        my ($vol, $dirs, $file) = File::Spec->splitpath($path, $no_file);
        $dirs =~ s{[/\\]$}{};
        my $foo = join("/", $vol, File::Spec->splitdir($dirs), $file);
        return lc $foo;
    }

    my $system_root = _canon_path($ENV{SystemRoot}, 1);

    sub is_system_lib
    {
        my ($self) = @_;
        my $canon_path = $_->canon_path or return;
        return length $canon_path > length $system_root
               && substr($canon_path, 0, length $system_root) eq $system_root;
    }

    tie my %perl_libs, "Tie::CPHash";
    {
        local $show_system_libs = 0;
        local $show_perl_libs = 1;
        $perl_libs{$_->name} = $_ foreach __PACKAGE__->depends($^X);
    };        

    sub is_perl_lib     { $perl_libs{shift->name} ? 1 : 0 }
}


# return a list of installed (ie. found below some directory in @INC) glue DLLs
sub find_all_installed_glue_dlls
{
    my @dlls;

    find(sub { push @dlls, $File::Find::name if /\.dll/i; }, 
         grep { my $auto;
                !ref $_ && -d ($auto = File::Spec->catdir($_, "auto")) ? 
                    $auto : () 
              } @INC);

    return @dlls;
}


# guess the Perl module from the pathname of a glue DLL
sub guess_module_from_glue_dll
{
    my ($path) = @_;

    # module Foo::Bar::Quux typically installs its glue DLL as
    # .../auto/Foo/Bar/Quux/Quux.dll or
    # .../auto/Foo/Bar/Quux/Quux.xs.dll
    my ($vol, $dirs, $file) = File::Spec->splitpath($path);
    $dirs =~ s{[/\\]$}{};
    $dirs =~ s{^(?:.*?[/\\])?auto[/\\]}{}
        or warn(qq[DLL "$path": path doesn't contain "auto"\n]), return;
    return join("::", File::Spec->splitdir($dirs));
}


my $show_lib_path = 0;
sub show_lib
{
    my ($dll) = @_;
    if ($show_lib_path)
    {
        printf "\t%s => %s\n", $dll->name, $dll->path || "(not found)";
    }
    else
    {
        printf "\t%s\n", $dll->name;
    }
}

if (@ARGV)
{
    foreach (@ARGV)
    {
        print $_, "\n";
        show_lib($_) foreach DLL->depends($_);
    }
}
else
{
    my %mod2dll;
    my @non_mod_dlls;
    foreach (find_all_installed_glue_dlls())
    {
        my $mod = guess_module_from_glue_dll($_);
        push(@non_mod_dlls, $_), next unless $mod;
        $mod2dll{$mod} = $_;
    }

    foreach my $mod (sort keys %mod2dll)
    {
	my $dll = $mod2dll{$mod};
        my @deps = DLL->depends($dll) or next; # suppress glue DLLs w/o dependencies
        print "$mod ($dll)\n";
        show_lib($_) foreach @deps;
    }

    print "\n";
    foreach my $dll (sort @non_mod_dlls)
    {
        print "$dll\n";
        show_lib($_) foreach DLL->depends($dll);
    }
}

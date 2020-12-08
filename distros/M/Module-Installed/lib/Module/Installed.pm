package Module::Installed;

our $VERSION = '1.01';

use strict;
use warnings;

use Carp qw(croak);
use Data::Dumper;
use Exporter qw(import);
our @EXPORT_OK = qw(
    includes_installed
    module_installed
);

my $SEPARATOR;

BEGIN {
    if ($^O =~ /^(dos|os2)/i) {
        $SEPARATOR = '\\';
    } elsif ($^O =~ /^MacOS/i) {
        $SEPARATOR = ':';
    } else {
        $SEPARATOR = '/';
    }
}

sub includes_installed {
    my $file = shift;

    my $PPI = $ENV{MI_TEST_PPI} ? $ENV{MI_TEST_PPI} : 'PPI';

    if (! -f $file) {
        croak("includes_installed() requires a valid Perl file as a parameter...");
    }

    if (! module_installed($PPI)) {
        croak("includes_installed() requires PPI, which isn't installed...");
    }

    require PPI;
    PPI->import;

    my $doc = PPI::Document->new($file);
    my $includes = $doc->find('PPI::Statement::Include');

    my %includes;

    for (@$includes) {
        $includes{$_->module} = module_installed($_->module) ? 1 : 0;
    }

    return \%includes;
}
sub module_installed {
    my $name = shift;

    # convert Foo::Bar -> Foo/Bar.pm
    my $name_pm;
    if ($name =~ /\A\w+(?:::\w+)*\z/) {
        ($name_pm = "$name.pm") =~ s!::!$SEPARATOR!g;
    } else {
        $name_pm = $name;
    }

    return 1 if exists $INC{$name_pm};
    return eval {_module_source($name_pm); 1 } ? 1 : 0;
}
sub _get_module_source {
    my $name = shift;

    # convert Foo::Bar -> Foo/Bar.pm
    my $name_pm;
    if ($name =~ /\A\w+(?:::\w+)*\z/) {
        ($name_pm = "$name.pm") =~ s!::!$SEPARATOR!g;
    } else {
        $name_pm = $name;
    }

    return _module_source $name_pm;
}
sub _module_source {
    my $name_pm = shift;

    for my $entry (@INC) {
        next unless defined $entry;
        my $ref = ref($entry);
        my ($is_hook, @hook_res);
        if ($ref eq 'ARRAY') {
            $is_hook++;
            @hook_res = $entry->[0]->($entry, $name_pm);
        } elsif (UNIVERSAL::can($entry, 'INC')) {
            $is_hook++;
            @hook_res = $entry->INC($name_pm);
        } elsif ($ref eq 'CODE') {
            $is_hook++;
            @hook_res = $entry->($entry, $name_pm);
        } else {
            my $path = "$entry$SEPARATOR$name_pm";
            if (-f $path) {
                open my($fh), "<", $path
                    or die "Can't locate $name_pm: $path: $!";
                local $/;
                return wantarray ? (scalar <$fh>, $path) : scalar <$fh>;
            }
        }

        if ($is_hook) {
            next unless @hook_res;
            my $prepend_ref; $prepend_ref = shift @hook_res if ref($hook_res[0]) eq 'SCALAR';
            my $fh         ; $fh          = shift @hook_res if ref($hook_res[0]) eq 'GLOB';
            my $code       ; $code        = shift @hook_res if ref($hook_res[0]) eq 'CODE';
            my $code_state ; $code_state  = shift @hook_res if @hook_res;
            if ($fh) {
                my $src = "";
                local $_;
                while (!eof($fh)) {
                    $_ = <$fh>;
                    if ($code) {
                        $code->($code, $code_state);
                    }
                    $src .= $_;
                }
                $src = $$prepend_ref . $src if $prepend_ref;
                return wantarray ? ($src, $entry) : $src;
            } elsif ($code) {
                my $src = "";
                local $_;
                while ($code->($code, $code_state)) {
                    $src .= $_;
                }
                $src = $$prepend_ref . $src if $prepend_ref;
                return wantarray ? ($src, $entry) : $src;
            }
        }
    }

    die "Can't locate $name_pm in \@INC (\@INC contains: ".join(" ", @INC).")";
}
1;

# ABSTRACT: Check if modules are installed

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Installed - Check whether a module, or a file's list of includes are
installed.

=for html
<a href="http://travis-ci.org/stevieb9/mock-sub"><img src="https://secure.travis-ci.org/stevieb9/module_installed.png"/>
<a href='https://coveralls.io/github/stevieb9/module_installed?branch=master'><img src='https://coveralls.io/repos/stevieb9/module_installed/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use Module::Installed qw(module_installed includes_installed)

    my $module = 'Mock::Sub';

    # module_installed()

    if (module_installed($module)) {
        require $module;
        $module->import;

        ...
    }
    else {
        warn "$module is not installed...";
    }

    # includes_installed()

    my $includes = includes_installed('perl_file_with_includes.pl');

    for my $inc_name (keys %$includes) {
        my $statement = $includes->{$inc_name}
            ? "is installed"
            : "isn't installed";

        print "$inc_name $statement\n";
    }

=head1 DESCRIPTION

Verifies whether or not a module or a file's list of includes are installed.

=head1 FUNCTIONS

=head2 module_installed($name)

Checks whether a module is installed on your system.

Parameters:

    $name

Mandatory, String: The name of the module to check against (eg: C<Mock::Sub>).

Returns: True (C<1>) if the module is found, and false (C<0>) if not.

=head2 includes_installed($file)

This function reads in a Perl file, strips out all of its includes (C<use> and
C<require>), and checks whether each one is installed on the system.

B<Note>: This function requires L<PPI> to be installed. If it is, we'll load it
and proceed. If it isn't, we C<croak()>.

Parameters:

    $file

Mandatory, String: The name of a Perl file.

Returns: A hash reference where the found included modules' name as the key,
and for the value, true (C<1>) if the module is installed and false (C<0>) if
not.

=head1 SEE ALSO

This module was pretty well copy/pasted from L<Module::Installed::Tiny>, but
without the significant dependency chain required by that distribution's test
suite.

=head1 AUTHOR

Steve Bertrand <steveb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Steve Bertrand

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


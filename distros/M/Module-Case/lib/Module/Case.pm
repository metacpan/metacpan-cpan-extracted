package Module::Case;

use 5.008000;
use strict;
use warnings;

our $VERSION = '0.05';

our $sensitive_modules;

our $inc_sniffer = sub {
    # Special @INC hook to only load modules with exact case match.
    # This is particularly useful on case insensitive file systems.
    my ($self, $filename) = @_;
    # Ignore full path filenames
    return undef if $filename =~ m{^/};
    # Calculate package name
    my $pkg = $filename;
    $pkg =~ s/\.pm$//;
    $pkg =~ s{/+}{::}g;
    # For efficiency purposes, skip module unless it's one of the special case sensitive packages flagged to load case-sensitively.
    $sensitive_modules->{$pkg} or $sensitive_modules->{'-all'} or return undef;

    # Skip the directories before me since they've already been tried (and obviously didn't find the file already or else we wouldn't be here)
    my $keep = 0;
    # Only look through regular directories after myself but ignore CODEREFs (such as myself) in @INC
    my @scan = grep { $keep = 1 if $_ eq $self; !ref $_ and $keep; } @INC;
    # Now that @scan has been built, it's safe to disable $pkg from the list.
    __PACKAGE__->unimport($pkg);
    my $found_wrong_case = 0;
    foreach my $dir (@scan) {
        if (open my $fh, "<", "$dir/$filename") {
            # Found a matching file but might not have same case.
            # Take a quick peek to make sure the case matches too.
            my $contents = join "", <$fh>;
            if ($contents =~ /^\s*package\s+\Q$pkg\E\s*;/m) {
                 # Smells like a pretty good package.
                 # Case matches case exactly.
                 # So rewind and return this handle.
                 seek($fh, 0, 0);
                 $INC{$filename} = "$dir/$filename";
                 return $fh;
            }
            else {
                # Looks like we found a file with the wrong case, so ignore it.
                $found_wrong_case ||= "$dir/$filename";
            }
            close $fh;
        }
    }
    # Couldn't find the real module
    if ($found_wrong_case) {
        # Found a case insensitive match but did NOT find an exact match.
        # We need to block Perl from continuing along @INC or else it will find the bad guy too.
        my $error = "Can't locate $filename in \@INC except for decoy with wrong case [$found_wrong_case]";
        if (eval { require Carp }) {
            Carp::croak($error);
        }
        else {
            die "$error\n";
        }
    }
    # Can't even find a case-insensitive match, so just continue and let Perl try
    return undef;
};

our $sub_import = sub {
    my $class = shift;
    foreach (@_) {
        # Autovivify $sensitive_modules only as needed
        $sensitive_modules->{$_} = $_;
    }
    if (keys %$sensitive_modules and !grep { $_ eq $inc_sniffer } @INC) {
        # Only inject the sniffer if there is something to smell
        # and only if it's not already in the list.
        # Search for the first regular directory (non-ref string) @INC setting
        # Then jam the $inc_sniffer right before it.
        for (my $i = 0; $i < @INC; $i++) {
            if (!ref $INC[$i]) {
                splice @INC, $i, 0, $inc_sniffer;
                last;
            }
        }
    }
    return;
};

my $sub_unimport = sub {
    my $class = shift;
    my $wiped = undef;
    if ($sensitive_modules) {
        if (@_) {
            # Pick out module(s) to quit case sniffing for
            foreach (@_) {
                $wiped ||= delete $sensitive_modules->{$_};
            }
        }
        else {
            # No specific module provided, so just wipe everything
            ($wiped) = keys %$sensitive_modules;
            $sensitive_modules = undef;
        }
    }
    if (!$sensitive_modules or !keys %$sensitive_modules) {
        # No module case-sensitive modules left, so restore @INC without the sniffer
        $sensitive_modules = undef;
        @INC = grep { $_ ne $inc_sniffer } @INC;
    }
    # Return one of the modules that got wiped, if any.
    return $wiped;
};

{
    no strict 'refs';
    my $should_pkg = __PACKAGE__;
    defined &{"$should_pkg\::import"}   or *{"$should_pkg\::import"}   = $sub_import;
    defined &{"$should_pkg\::unimport"} or *{"$should_pkg\::unimport"} = $sub_unimport;
    (my $should_file = "$should_pkg.pm") =~ s%::%/%g;
    if (__FILE__ !~ m{\b\Q$should_file\E$} and
        __FILE__ =~ m{\b(\Q$should_file\E)$}i) {
        my $fake_file = $1;
        my $fake_pkg = $fake_file;
        $fake_pkg =~ s%/+%::%g;
        $fake_pkg =~ s/\.pm//;
        #if (eval { require Carp }) { Carp::carp("Case-ignorant filesystem exploited by loading module wrongly: $fake_pkg"); }
        defined &{"$fake_pkg\::import"}   or *{"$fake_pkg\::import"}   = *{"$should_pkg\::import"};
        defined &{"$fake_pkg\::unimport"} or *{"$fake_pkg\::unimport"} = *{"$should_pkg\::unimport"};
        # Fake Preload Real Module
        $INC{$should_file} = __FILE__;
    }
}

1;

__END__

=pod

=head1 NAME

Module::Case - Case sensitive module loading.

=head1 SYNOPSIS

    # Specify which modules you wish to force the case
    # to match exactly if ever loaded in the future
    use Module::Case qw(Config config);

    # Load only Config.pm starting with CAPITAL C
    # even on case-insensitive file systems and
    # even if lowercase config.pm is earlier in the @INC.
    use Config;

    # Now load only the lowercase file
    use config;

    # Or to enforce all modules to be case-sensitive
    use Module::Case '-all';

=head1 DESCRIPTION

This module was created to alleviate the problems caused by
case-ignorant or case-insensitive file systems or operating
systems such as Windows or OSX when attempting to load a
module that doesn't exactly match the case.

This is especially troublesome when there are two different
modules within the @INC that are case-insensitively similar.
It becomes very difficult to load the one that comes later in
the @INC because it will always get snagged on the first one.

Using this module can force a module to load ONLY if the case
matches exactly, just as if the file system containing the
module were case-sensitive.

Module::Case is efficient enough to run in production.

=head1 IMPLEMENTATION

This modules injects a special CODEREF at the beginning of @INC that
performs a pre-check on each matching file within @INC to ensure the
case is exactly correct instead of allowing Perl to blindly compile
any file that smells like the module wishing to load.

If the specified module doesn't exactly match the case of how it was
requested, then the "require" or "use" will die with an error
instead of gleefully loading any file matching case-insensitively.

=head1 CAVEATS

The module being loaded must contain the exact string of the package
matching what has been flagged for sensitively. For example:

    use Module::Case qw(Exact::Module::Name);
    use Exact::Module::Name;
    # -or-
    require Exact::Module::Name;

Then the contents of "Exact/Module/Name.pm" must contain
"package Exact::Module::Name" somewhere in the pm file
or else it will fail to load.

If there are multiple different modules that match case-insensitvely
and you wish to load more than one of these, then it would be safer
to specify ALL of these variations in the import line, such as:

    use Module::Case qw(cwd Cwd);
    use cwd;
    use Cwd;

This is because once a case-sensitive module is loaded successfully,
then it is immediately removed from the import whitelist. Technically,
you only need to specify the module that isn't matched first in the
@INC, but if this order ever changes in the future, then it will
still incorrectly load the FIRST case-insensitive match in @INC.

=head1 AUTHOR

Rob Brown <bbb@cpan.org>

=head1 SEE ALSO

Similar behavior to Acme::require::case but using an alternate
implementation which makes Module::Case quite fast and
Module::Case doesn't require any dependencies.

=cut

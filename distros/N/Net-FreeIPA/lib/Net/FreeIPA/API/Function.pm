package Net::FreeIPA::API::Function;
$Net::FreeIPA::API::Function::VERSION = '3.0.2';
use strict;
use warnings;

use base qw(Exporter);

our $AUTOLOAD;

use Net::FreeIPA::API::Convert qw(process_args);
use Net::FreeIPA::API::Magic qw(retrieve);

my @all = Net::FreeIPA::API::Magic::all_command_names();

# Make all functions individually exportable
our @EXPORT_OK = @all;

# Support :all tag
our %EXPORT_TAGS = (
    all => \@all,
);

# Make an export tag for each method-class, e.g. :user
foreach my $cmd (@all) {
    my $class = $cmd;
    $class =~ s/_.*$//;
    $EXPORT_TAGS{$class} = [] if ! defined($EXPORT_TAGS{$class});
    push(@{$EXPORT_TAGS{$class}}, $cmd);
};

#
# AUTOLOAD a function with the exact commandname, returns C<_api_function> call
#
sub AUTOLOAD
{
    my $called = $AUTOLOAD;

    # Don't mess with garbage collection!
    return if $called =~ m{DESTROY};

    my $called_orig = $called;
    $called =~ s{^.*::}{};

    my ($cmd, $fail) = retrieve($called);

    if ($fail) {
        die "Unknown Net::FreeIPA::API method: $called failed $fail (from original $called_orig)";
    } else {
        # Run the expected method.
        # AUTOLOAD with glob assignment and goto defines the autoloaded method
        # (so they are only autoloaded once when they are first called),
        # but that breaks inheritance.

        # The method name is in the name attribute
        return process_args($cmd, @_);
    }
}

1;

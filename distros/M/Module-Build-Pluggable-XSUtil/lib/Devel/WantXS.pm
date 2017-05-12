package Devel::WantXS;
use strict;
use warnings;
use utf8;
use parent qw/Exporter/;

our @EXPORT = qw/want_xs/;

our $_CACHE;
sub want_xs {
    my($self, $default) = @_;
    return $_CACHE if defined $_CACHE;

    # you're using this module, you must want XS by default
    # unless PERL_ONLY is true.
    $default = !$ENV{PERL_ONLY} if not defined $default;

    for my $arg(@ARGV){
        if($arg eq '--pp'){
            return $_CACHE = 0;
        }
        elsif($arg eq '--xs'){
            return $_CACHE = 1;
        }
    }
    return $_CACHE = $default;
}

1;
__END__

=head1 NAME

Devel::WantXS - user needs pure perl?

=head1 SYNOPSIS

    use Devel::WantXS;

    if (want_xs()) {
        ... # setup to compile
    } else {
        ... # setup to PP version
    }

=head1 DESCRIPTION

This module detects the user need to use pure perl version or not.

=head1 FUNCTIONS

=over 4

=item want_xs() : Bool

Returns true if the user asked for the XS version or pure perl version of the module.

Will return true if C<<--xs>> is explicitly specified as the argument to Makefile.PL, and false if C<<--pp>> is specified. If neither is explicitly specified, will
return the value specified by $default. If you do not specify the value of $default, then it will be true.

=back

=head1 AUTHORS

Goro Fuji(Original author of Module::Install::XSUtil)

Tokuhiro Matsuno(Port from Module::Install::XSUtil)


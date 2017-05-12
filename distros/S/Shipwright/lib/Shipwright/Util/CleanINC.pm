package Shipwright::Util::CleanINC;
use strict;
use warnings;
use Config;

sub import {
    # It's expensive to do, but we need to find out what's in @INC now that
    # should be kept (because it was specified on the commandline with -I)
    # and what we should drop because it's baked into perl as a local lib
    
    my %skip_lib_path = map { $_ => 1 } _default_inc();
    my @explicit_libs = grep {!/inc$/}  split( /[:;]/,($ENV{'PERL5LIB'} ||''));
    my @inc_libs = grep {/inc$/}  split( /[:;]/,($ENV{'PERL5LIB'} ||''));
    # if the libs are explicitly specified, don't pull them from @INC
    my @new_base_inc = grep { !$skip_lib_path{$_}++ } (  @explicit_libs, @INC,@inc_libs);
    @INC = map { /(.+)/; $1 } grep { defined } (
        @new_base_inc,               $Config::Config{updatesarch},
        $Config::Config{updateslib}, $Config::Config{archlibexp},
        $Config::Config{privlibexp}, '.'
    );
}



{

    # This code stolen from 
    # http://cpansearch.perl.org/src/ANDYA/Test-Harness-3.15/lib/Test/Harness.pm
    # Cache this to avoid repeatedly shelling out to Perl.
    my @inc;

    sub _default_inc {
        return @inc if @inc;
        local $ENV{PERL5LIB} = '';
        local $ENV{PERLLIB} = '';
        local $ENV{PERL5DB} = '';
        local $ENV{PERL5OPT} = '';
        local $ENV{PERL5ENV} = '';
        local $ENV{PATH} = $1 if $ENV{PATH} =~ /^(.*)$/;
        my $perl;
        $perl =  $1 if $^X =~ /^(.*)$/;
        # Avoid using -l for the benefit of Perl 6
        chomp( @inc = map { /^(.*)$/ && $1 }  `$perl -e "print join qq[\\n], \@INC, q[]"` );
        return @inc;
    }
}

1;

__END__

=head1 NAME

Shipwright::Util::CleanINC - Use this to clean @INC

=head1 DESCRIPTION

this will limit the @INC to only contain "Core" ( technically, they are
$Config::Config{privlibexp} and $Config::Config{archlibexp}, also 
$Config::Config{updatesarch} and $Config::Config{updateslib}, which are
used in Mac ) and PERL5LIB

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2007-2015 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


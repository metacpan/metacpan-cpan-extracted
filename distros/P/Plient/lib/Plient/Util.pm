package Plient::Util;

use warnings;
use strict;
use Carp;
use Config;

use File::Spec::Functions;
use base 'Exporter';
our @EXPORT = 'which';

use constant WIN32 => $^O eq 'MSWin32';
my $bin_quote = WIN32 ? q{"} : q{'};
my $bin_ext = $Config{_exe};
my %cache;
sub which {
    my $name = shift;
    return $cache{$name} if $cache{$name};

    my $path;

  LINE:
    for my $dir ( path() ) {
        my $p = catfile( $dir, $name );

        # XXX  any other names need to try?
        my @try = grep { -x } ( $p, $p . $bin_ext );
        for my $try (@try) {
            $path = $try;
            last LINE;
        }
    }

    return unless $path;
    if ( $path =~ /\s/ && $path !~ /^$bin_quote/ ) {
        $path = $bin_quote . $path . $bin_quote;
    }

    return $cache{$name} = $path;
}

1;

__END__

=head1 NAME

Plient::Util - 


=head1 SYNOPSIS

    use Plient::Util;

=head1 DESCRIPTION


=head1 INTERFACE


=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2010-2011 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


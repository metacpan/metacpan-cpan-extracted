#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Say;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Say -  Compatibility layer to use say().

=head1 SYNOPSIS
        
    print "hello world\n";

    # same as:

    say "hello world";

=head1 DESCRIPTION

Nile::Say -  Compatibility layer to use say().

=cut

use strict;
use warnings;
use IO::Handle;
use Scalar::Util 'openhandle';
use Carp;

# modified code from Say::Compat
sub import {
    my $class = shift;
    my $caller = caller;

    if( $] < 5.010 ) {
        no strict 'refs';
        *{caller() . '::say'} = \&say; 
        use strict 'refs';
    }
    else {
        require feature;
        feature->import("say");
    }
}

# code from Perl6::Say
sub say {
    my $currfh = select();
    my $handle;
    {
        no strict 'refs';
        $handle = openhandle($_[0]) ? shift : \*$currfh;
        use strict 'refs';
    }
    @_ = $_ unless @_;
    my $warning;
    local $SIG{__WARN__} = sub { $warning = join q{}, @_ };
    my $res = print {$handle} @_, "\n";
    return $res if $res;
    $warning =~ s/[ ]at[ ].*//xms;
    croak $warning;
}

# Handle OO calls:
*IO::Handle::say = \&say if ! defined &IO::Handle::say;


=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

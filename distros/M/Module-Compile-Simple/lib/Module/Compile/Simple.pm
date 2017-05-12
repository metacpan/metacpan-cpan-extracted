package Module::Compile::Simple;
use 5.006001;
use strict;
use warnings;
our $VERSION = '0.24';

use Module::Compile -base;

sub pmc_compile {
    my ($class, $source) = @_;
    return "use 5.006001;
use strict;
use warnings;

use Module::Compile -base;

sub pmc_compile {
    my (\$class, \$source) = \@_;
    $source;
}

1;
"
}

1;

__END__

=head1 NAME

Module::Compile::Simple - Even Simpler Perl Module Compilation

=head1 SYNOPSIS

    package Foo;
    use Module::Compile::Simple;
    transform($source);

In F<Bar.pm>

    package Bar;

    use Foo;
    ...
    no Foo


=head1 DESCRIPTION

C<Module::Compile::Simple> makes it easier to write L<Module::Compile>
modules, doing compile-time source filtering.

After using C<Module::Compile::Simple>, apply transformation on
C<$source>.

=head1 TODO

Make this work:

    use Module::Compile::Simple '$source';

=head1 SEE ALSO

L<Module::Compile>

=head1 AUTHORS

Chia-liang Kao <clkao@clkao.org>

=head1 COPYRIGHT

Copyright (c) 2006. Chia-liang Kao. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut


=cut

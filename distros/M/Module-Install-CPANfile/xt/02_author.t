use strict;
use warnings;
use Test::More;
use xt::Util;
use Test::Requires 'CPAN::Meta::Check';

my $warning;
{
    local $SIG{__WARN__} = sub { $warning .= $_[0] };
    make_meta_data(*DATA);
}
like $warning, qr/'XYZDummy' is not installed/;

done_testing;

__DATA__
@@ Makefile.PL
use inc::Module::Install;

cpanfile;

name 'Dummy';
all_from 'lib/Dummy.pm';
tests 't/*.t';
WriteAll;

@@ cpanfile
on 'develop' => sub {
    requires 'XYZDummy';
};

@@ lib/Dummy.pm
package Dummy;
use 5.006;
our $VERSION = '0.1';
1;
__END__
=pod

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2012- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

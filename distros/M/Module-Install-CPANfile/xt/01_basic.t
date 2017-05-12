use strict;
use warnings;
use Test::More;
use xt::Util;

note explain my $meta_data = make_meta_data(*DATA);

subtest build_requires => sub {
    my $build_requires = $meta_data->{build_requires};
    is $build_requires->{'Test::More'}, '>= 0.96, < 2.0';
};

subtest requires => sub {
    my $requires = $meta_data->{requires};
    is $requires->{Plack}, '0.9986';
    is $requires->{'SQL::Maker'}, 0;
};

subtest recommends => sub {
    my $recommends = $meta_data->{recommends};
    is $recommends->{'JSON::XS'}, '2.0';
    is $recommends->{'Test::TCP'}, '1.12';
};

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
requires 'Plack' => '0.9986';
requires 'SQL::Maker';

recommends 'JSON::XS', '2.0';

on 'runtime' => sub {
    recommends 'Test::TCP', '1.12';
};

on 'test' => sub {
    requires 'Test::More', '>= 0.96, < 2.0';
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

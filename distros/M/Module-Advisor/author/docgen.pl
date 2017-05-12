#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use Text::MicroTemplate qw/render_mt/;
use lib 'lib';
use Module::Advisor;

our %pod_escape_table = ('>' => 'E<gt>', '<' => 'E<lt>');

sub escape_pod {
    my ($variable) = @_;

    my $source = qq{
        do{
            $variable =~ s/([><])/\$::pod_escape_table{\$1}/ge;
            $variable;
        }
    };
    $source =~ s/\n//g; # to keep line numbers
    return $source;
}

my $tmpl = join '', <DATA>;
my $render = Text::MicroTemplate->new(template => $tmpl,
                                      escape_func => \&escape_pod);
my $result = $render->build->();
print $result;

__DATA__

=encoding utf8

=for stopwords ddf timezone segv eof x-up-devcap-multimedia StandAloneGPS filehandles colourful newlines big-endian x-up-devcap-multimedia(StandAloneGPS)

=head1 NAME

Module::Advisor - check a modules you are installed

=head1 SYNOPSIS

    use Module::Advisor;
    Module::Advisor->new()->check();

=head1 DESCRIPTION

Module::Advisor checks a modules you are installed, and notice if:

=over 4

=item There is a module, have known bugs.

=item There is a module, have optional XS module for better performance.

=item Your are using broken version of CPAN module.

=back

=head1 RULES

Here is a rules to check the modules.

=head2 Modules have security issues.

=over 4

? for my $module (@Module::Advisor::SECURITY) {
=item <?= $module->[0] ?> <?= $module->[1] ?>

<?= $module->[2] ?>

? }

=back

=head2 Modules have performance improvements

=over 4

? for my $module (@Module::Advisor::PERFORMANCE) {

=item <?= $module->[0] ?> <?= $module->[1] ?>

<?= $module->[2] ?>

? }

=back

=head2 Modules have bugs

=over 4

? for my $module (@Module::Advisor::BUG) {

=item <?= $module->[0] ?> <?= $module->[1] ?>

<?= $module->[2] ?>

? }

=back

=head2 The version of this module was broken

=over 4

? for my $module (@Module::Advisor::BROKEN) {

=item <?= $module->[0] ?> <?= $module->[1] ?> has bug.

<?= $module->[2] ?>

? }

=back

=head2 Recommended XS module for better performance

=over 4

? for my $module (@Module::Advisor::XS) {

=item <?= $module->[1] ?> is recommended

If you are using <?= $module->[0] ?>.

? }

=back

=head2 Recommended version to enable good feature

=over 4

? for my $module (@Module::Advisor::FEATURE) {

=item <?= $module->[0] ?> <?= $module->[1] ?> does not have

<?= $module->[2] ?>

? }

=back

=head2 Recommend modules when using ...

=over 4

? for my $module (@Module::Advisor::OPTIONAL_MODULES) {

=item I recommend to install <?= $module->[1] ?>, if you are using <?= $module->[0] ?>.

<?= $module->[2] ?>

? }

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

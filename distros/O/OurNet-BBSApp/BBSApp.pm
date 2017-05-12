package OurNet::BBSApp;
$VERSION = '0.03';

require 5.006;

=head1 NAME

OurNet::BBSApp - BBS Application Interface

=head1 SYNOPSIS

    use OurNet::BBSApp;
    OurNet::BBSApp->new('autrijus.xml')->run();

The file "autrijus.xml" would look like:

    <bbsapp>
      <handler>Templator</handler>
      <monitor source="archives" name="autrijus">
        <template list="group.w" file="article.w" />
        <output path="/srv/www/autrijus" list="index-[% dir %]-[% recno %].html"
                file="archive[% dir %]-[% recno %].html" />
      </monitor>
      <monitor source="articles" name="autrijus">
        <template list="group.w">
            <file>article.w</file>
            <file>reply.w</file>
        </template>
        <output path="/srv/www/autrijus" reversed="1" preview="5" pagemax="20"
                list="index-[% page %].html">
            <file>article[% recno %].html</file>
            <file>reply[% recno %].html</file>
        </output>
      </monitor>
      <interval>10</interval>
      <bbsarg>CVIC</bbsarg>
      <bbsarg>/srv/bbs/cvic</bbsarg>
      <bbsarg>1003</bbsarg>
      <bbsarg>2500</bbsarg>
    </bbsapp>

The XML tree could also be passed as a hash reference instead. Consult
L<XML::Simple> for how the attributes will look like.

Note that C<keyattr> attribute is set to C<{}> (null), so there are no
"default" attribute keys in incoming XML structure.

=head1 DESCRIPTION

OurNet::BBSApp provides a XML-based, unified access interface to
applications operating on L<OurNet::BBS>. The factory class for
these services are usually L<OurNet::BBSApp::Board>, which supports
various tweakings on ArticleGroup classes.

The specific API remains to be documented.

=head1 BUGS

Too numerous to describe.

=cut

use strict;
use OurNet::BBSApp::Monitor;
use OurNet::BBS;
use XML::Simple;
use fields qw/BBS loaded config/;
use vars qw/$Interval/;

$Interval = 10; # default: 10 sec sleeps

sub new {
    my $class = shift;
    my $self  = fields::new($class);

    $self->{config} = UNIVERSAL::isa($_[0], 'HASH')
        ? $_[0]
        : XMLin(
            @_,
            keyattr => {},
            searchpath => ['.']
        );

    $self->{config}{handler} = "OurNet::BBSApp::$self->{config}{handler}"
        unless $self->{config}{handler} =~ /::/;

    my $handler = $self->{config}{handler};
    $handler =~ s|::|/|g;

    require "$handler.pm";
    $self->{BBS} = OurNet::BBS->new(@{$self->{config}{bbsarg}});

    return $self;
}

sub load {
    my $self = shift;
    return if $self->{loaded}++;

    foreach my $item (@{$self->{config}{'monitor'}}) {
        OurNet::BBSApp::Monitor::add($self->{config}{handler}->new(
            $self->{BBS}, $item
        ));
    }
}

sub run {
    my $self = shift;

    $self->load() if $self; # could be called without an object

    while (1) {
        OurNet::BBSApp::Monitor::process;
        sleep ($self ? $self->{config}{interval} : $Interval);
    }
}

1;

=head1 SEE ALSO

L<OurNet::BBS>

=head1 AUTHORS

Chia-Liang Kao E<lt>clkao@clkao.org>
Autrijus Tang E<lt>autrijus@autrijus.org>

=head1 COPYRIGHT

Copyright 2001 by Autrijus Tang E<lt>autrijus@autrijus.org>,
                  Chia-Liang Kao E<lt>clkao@clkao.org>.

All rights reserved.  You can redistribute and/or modify
this module under the same terms as Perl itself.

=cut

use strict;
package Template::Plugin::YAML;
use Template::Plugin;
use base 'Template::Plugin';
use YAML qw(Dump Load DumpFile LoadFile);
use vars qw($VERSION);
$VERSION = '1.23';

=head1 NAME

Template::Plugin::YAML - Plugin interface to YAML

=head1 SYNOPSIS

    [% USE YAML %]

    [% YAML.dump(variable) %]
    [% YAML.dump_html(variable) %]
    [% value = YAML.undump(yaml_string) %]
    [% YAML.dumpfile(filename, variable) %]
    [% value = YAML.undumpfile(filename) %]

=head1 DESCRIPTION

This is a simple Template Toolkit Plugin Interface to the YAML module.
A YAML object will be instantiated via the following directive:

    [% USE YAML %]

As a standard plugin, you can also specify its name in lower case:

    [% USE yaml %]

=head1 METHODS

These are the methods supported by the YAML object.

=head2 dump( @variables )

Generates a raw text dump of the data structure(s) passed

    [% USE Dumper %]
    [% yaml.dump(myvar) %]
    [% yaml.dump(myvar, yourvar) %]

=cut

sub dump {
    my $self = shift;
    my $content = Dump @_;
    return $content;
}


=head2 dump_html( @variables )

Generates a dump of the data structures, as per C<dump>, but with the
characters E<lt>, E<gt> and E<amp> converted to their equivalent HTML
entities, spaces converted to &nbsp; and newlines converted to
E<lt>brE<gt>.

    [% USE yaml %]
    [% yaml.dump_html(myvar) %]

=cut

sub dump_html {
    my $self = shift;
    my $content = Dump @_;
    for ($content) {
        s/&/&amp;/g;
        s/ /&nbsp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        s/\n/<br>\n/g;
    }
    return $content;
}


=head2 undump( $string )

Converts a YAML-encoded string into the equivalent data structure.
Here's a way to deep-copy a complex structure by completely serializing
the data.

  [% USE yaml;
     yaml_string = yaml.dump(complex_data_structure);
     complex_copy = yaml.undump(yaml_string);
  %]

=cut

sub undump {
    my $self = shift;
    return Load shift;
}


=head2 dumpfile( $file, @variables )

Converts the data to YAML encoding, and dumps it to the specified
filepath.

  [% USE yaml; yaml.dumpfile(".storage", my_data) %]

=cut

sub dumpfile {
    my $self = shift;
    return DumpFile @_;
}


=head2 undumpfile( $file )

Loads the YAML-encoded data from the specified filepath

  [% USE yaml; my_data = yaml.undumpfile(".storage") %]

=cut

sub undumpfile {
    my $self = shift;
    return LoadFile @_;
}

1;
__END__

=head1 AUTHORS

Richard Clamp <richardc@unixbeard.net>, with undump, undumpfile, and
dumpfile implementation by Randal L. Schwartz <merlyn@stonehenge.com>

based on Simon Matthews' L<Template::Plugin::Dumper>

=head1 COPYRIGHT

Copyright 2003, 2008 Richard Clamp All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::Dumper>

=cut

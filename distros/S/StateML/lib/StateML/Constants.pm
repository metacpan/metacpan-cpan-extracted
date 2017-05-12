package StateML::Constants;

$VERSION = 0.000_1;

=head1 NAME

StateML::Constants - A very few constants shared by various StateML modules

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=cut

use Exporter;
@ISA = qw( Exporter );

@EXPORT_OK = qw( stateml_1_0_ns stateml_1_0_graphviz_ns );

use strict;

=item stateml_1_0_ns

The namespace for StateML 1.0:

    http://slaysys.com/StateML/1.0

=cut

sub stateml_1_0_ns () { "http://slaysys.com/StateML/1.0" }

=item stateml_1_0_graphviz_ns

The namespace for graphviz-specific attributes used in StateML 1.0 is:

    http://slaysys.com/StateML/1.0/GraphViz

=cut

sub stateml_1_0_graphviz_ns () { "http://slaysys.com/StateML/1.0/GraphViz" }

=back

=head1 LIMITATIONS

=head1 COPYRIGHT

    Copyright 2003, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, or GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;

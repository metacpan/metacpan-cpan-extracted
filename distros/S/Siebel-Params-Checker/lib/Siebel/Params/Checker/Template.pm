package Siebel::Params::Checker::Template;

=pod

=head1 NAME

Siebel::Params::Checker::Template - defines and generates HTML report for scpc.pl command line program

=cut

use warnings;
use strict;
use Exporter qw(import);
use Carp;
use Template 2.26;
our $VERSION = '0.002'; # VERSION
our @EXPORT_OK = qw(gen_report);
our $TEMPLATE;

=head1 DESCRIPTION

This module uses L<Template> to generate the HTML report for C<scpc.pl> command line program.

=head1 FUNCTIONS

Only the sub C<gen_report> is exportable by demand.

=head2 gen_report

Generates the report.

Expects as positional parameters:

=over

=item *

A string with the component name

=item *

An array reference with the data to be used as header

=item *

An array reference to be used report body.

=item *

The complete path where the HTML file should be generated

=back

It returns true if the report is generated success. Errors might generate
an exception with L<Carp> C<confess>.

=cut

sub gen_report {
    my ( $comp_name, $header_ref, $rows_ref, $output_path ) = @_;
    my $template = Template->new(
        {
            ENCODING   => 'utf8',
            TRIM       => 1,
            OUTPUT     => $output_path,
            PRE_CHOMP  => 1,
            POST_CHOMP => 1,
        }
    );
    unless (defined($TEMPLATE))
    {
        local $/ = undef;
        # the template will be hold on memory if this sub is invoked again
        $TEMPLATE = <DATA>;
        close(DATA);
    }
    my $vars = {
        title   => "Report of parameters of $comp_name component",
        header  => $header_ref,
        rows    => $rows_ref,
        version => $VERSION
    };

    $template->process( \$TEMPLATE, $vars )
      or confess $template->error();

    return 1;
}

=pod

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr>

=item *

The command line utility scpc.pl uses this module.

=item *

L<Siebel::Params::Checker::ListComp>

=item *

L<Siebel::Params::Checker::ListParams>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;

__DATA__
<!DOCTYPE html>
<html><head>
<!-- CSS borrowed from https://www.smashingmagazine.com/2008/08/top-10-css-table-designs/ -->
<style>
body
{
	line-height: 1.6em;
}
#box-table-a
{
	font-family: "Lucida Sans Unicode", "Lucida Grande", Sans-Serif;
	font-size: 12px;
	margin: 45px;
	width: 480px;
	text-align: left;
	border-collapse: collapse;
}
#footer {
	font-family: "Lucida Sans Unicode", "Lucida Grande", Sans-Serif;
	font-size: 10px;
}
#box-table-a th
{
	font-size: 13px;
	font-weight: normal;
	padding: 8px;
	background: #b9c9fe;
	border-top: 4px solid #aabcfe;
	border-bottom: 1px solid #fff;
	color: #039;
}
#box-table-a td
{
	padding: 8px;
	background: #e8edff; 
	border-bottom: 1px solid #fff;
	color: #669;
	border-top: 1px solid transparent;
    text-align:center; 
    vertical-align:middle;
}
#first-left
{
	font-size: 13px;
	font-weight: bold;
	padding: 8px;
	background: #d0dafd;
	border-top: 4px solid #aabcfe;
	border-bottom: 1px solid #fff;
    text-align:left !important; 
	color: #039;
}
#box-table-a tr:hover td
{
	background: #d0dafd;
	color: #339;
}
</style>
<title>[% title %]</title>
</head>
<body>
<h1>[% title %]</h1>
<table id="box-table-a">
<thead>
<tr>
[% FOREACH column IN header %]
<th scope="col">[% column %]</th>
[% END %]
</tr>
</thead>
<tbody>
[% FOREACH row IN rows %]
<tr>
[% first = 1 %]
[% FOREACH column IN row %]
[% IF first %]
<td id="first-left">[% column %]</td>
[% first = 0 %]
[% ELSE %]
<td>[% column %]</td>
[% END %]
[% END %]
</tr>
[% END %]
</tbody>
</table>
<hr>
<p id="footer">Generated with Siebel::Params::Checker version [% version %].</p>
</body>
</html>

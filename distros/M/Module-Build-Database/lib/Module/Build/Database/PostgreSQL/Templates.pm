=head1 NAME

Module::Build::Database::PostgreSQL::Templates - PostgreSQL documentation templates

=head1 DESCRIPTION

Templates used to generate documentation for a postgres database.

=cut

package Module::Build::Database::PostgreSQL::Templates;
our $VERSION = '0.57';

sub filenames {
    return qw/header.tmpl footer.tmpl html.tmpl pod.tmpl dot.tmpl/;
}

sub file_contents {
    my $class = shift;
    my $filename = shift;
    our %contents;
    return $contents{$filename};
}

our %contents = ( "footer.tmpl" => <<'END_FOOTER', "header.tmpl" =><< 'END_HEADER', "html.tmpl" =><<'END_HTML', "pod.tmpl" =><< 'END_POD', "dot.tmpl" =><< 'END_DOT' );

</body></html>
END_FOOTER
<!-- $Header: /cvsroot/autodoc/autodoc/html.tmpl,v 1.4 2006/05/16 19:01:27 rbt Exp $ -->
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">

<html>
  <head>
    <title>Index for <!-- TMPL_VAR ESCAPE="HTML" name="database" --></title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <style type="text/css">
	BODY {
		color:	#000000;
		background-color: #FFFFFF;
		font-family: Helvetica, sans-serif;
	}

	P {
		margin-top: 5px;
		margin-bottom: 5px;
	}

	P.w3ref {
		font-size: 8pt;
		font-style: italic;
		text-align: right;
	}

	P.detail {
		font-size: 10pt;
	}

	.error {
		color: #FFFFFF;
		background-color: #FF0000;
	}

	H1, H2, H3, H4, H5, H6 {
	}

	OL {
		list-style-type: upper-alpha;
	}

	UL.topic {
		list-style-type: upper-alpha;
	}

	LI.topic {
		font-weight : bold;
	}

	HR {
		color: #00FF00;
		background-color: #808080;
	}

	TABLE {
		border-width: medium;
		padding: 3px;
		background-color: #000000;
		width: 90%;
	}

	CAPTION {
		text-transform: capitalize;
		font-weight : bold;
		font-size: 14pt;
	}

	TH {
		color: #FFFFFF;
		background-color: #000000;
		text-align: left;
	}

	TR {
		color: #000000;
		background-color: #000000;
		vertical-align: top;
	}

	TR.tr0 {
		background-color: #F0F0F0;
	}

	TR.tr1 {
		background-color: #D8D8D8;
	}

	TD {
		font-size: 12pt;
	}

	TD.col0 {
		font-weight : bold;
		width: 20%;
	}

	TD.col1 {
		font-style: italic;
		width: 15%;
	}

	TD.col2 {
		font-size: 12px;
	}
    </style>
    <link rel="stylesheet" type="text/css" media="all" href="all.css">
    <link rel="stylesheet" type="text/css" media="screen" href="screen.css">
    <link rel="stylesheet" type="text/css" media="print" href="print.css">
    <meta HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
  </head>
  <body>


END_HEADER
_CUT: index.html
<html>

<frameset cols="20%,80%">
    <frame src="contents.html" name="contents">
    <frame src="default.html" name="data">
</frameset>

</html>
<!-- ------------------------------------------------------------------------- -->
_CUT: contents.html
<html>
<style>
a { color:#009; text-decoration:none; }
a:hover { color:#33f; }
</style>
<b><!-- TMPL_VAR ESCAPE="HTML" name="database" --></b><br>
<!-- TMPL_LOOP name="schemas" -->
<!-- TMPL_VAR ESCAPE="HTML" name="schema" -->
<br>
<!-- TMPL_LOOP name="tables" -->
<a target="data" href="<tmpl_if view_definition>view<tmpl_else>table</tmpl_if>_<tmpl_var schema>.<tmpl_var table>.html"><!-- TMPL_VAR ESCAPE="HTML" name="table" --></a>
<br>
<!-- /TMPL_LOOP name="tables" -->
<!-- TMPL_LOOP name="functions" -->
<a target="data" href="#<!-- TMPL_VAR ESCAPE="URL" name="function_sgmlid" -->"><!-- TMPL_VAR ESCAPE="HTML" name="function" --></a>
<br>
<!-- /TMPL_LOOP name="functions" -->
<!-- /TMPL_LOOP name="schemas" -->
<!-- TMPL_VAR ESCAPE="HTML" name="dumped_on" -->
</html>

<!-- ------------------------------------------------------------------------- -->
_CUT: default.html
<html>
Please select an item from the frame on the left.
</html>
<!-- ------------------------------------------------------------------------- -->
    <!-- TMPL_LOOP name="schemas" -->
        <!-- TMPL_LOOP name="tables" -->
_CUT: <tmpl_if view_definition>view<tmpl_else>table</tmpl_if>_<tmpl_var schema>.<tmpl_var table>.html
<tmpl_include header.tmpl>
        <h2><!-- TMPL_IF name="view_definition" -->View:<!-- TMPL_ELSE -->Table:<!-- /TMPL_IF -->
            <!-- TMPL_IF name="number_of_schemas" -->
            <a href="#<!-- TMPL_VAR ESCAPE="URL" name="schema_sgmlid" -->"><!-- TMPL_VAR ESCAPE="HTML" name="schema" --></a>.<!-- /TMPL_IF name="number_of_schemas" --><a name="<!-- TMPL_VAR ESCAPE="URL" name="table_sgmlid" -->"><!-- TMPL_VAR ESCAPE="HTML" name="table" --></a>
        </h2>
        <!-- TMPL_IF name="table_comment" -->
         <p><!-- TMPL_VAR ESCAPE="HTML" name="table_comment" --></p>
        <!-- /TMPL_IF name="table_comment" -->


        <table width="100%" cellspacing="0" cellpadding="3">
                <caption><!-- TMPL_IF name="number_of_schemas" --><!-- TMPL_VAR ESCAPE="HTML" name="schema" -->.<!-- /TMPL_IF name="number_of_schemas" --><!-- TMPL_VAR ESCAPE="HTML" name="table" --> Structure</caption>
                <tr>
                <th>F-Key</th>
                <th>Name</th>
                <th>Type</th>
                <th>Description</th>
                </tr>
            <!-- TMPL_LOOP name="columns" -->
            <tr class="<!-- TMPL_IF name="__odd__" -->tr0<!-- tmpl_else name="__odd__" -->tr1<!-- /TMPL_IF name="__odd__" -->">
                <td>
                <!-- TMPL_LOOP name="column_constraints" -->
                  <!-- TMPL_IF name="column_fk" -->
                  <a href="table_<tmpl_var column_fk_schema>.<tmpl_var column_fk_table>.html#<!-- TMPL_VAR ESCAPE="URL" name="column_fk_sgmlid" -->"><!-- TMPL_IF name="number_of_schemas" --><!-- TMPL_VAR ESCAPE="HTML" name="column_fk_schema" -->.<!-- /TMPL_IF name="number_of_schemas" --><!-- TMPL_VAR ESCAPE="HTML" name="column_fk_table" -->.<!-- TMPL_VAR ESCAPE="HTML" name="column_fk_colnum" --><!-- TMPL_IF name="column_fk_keygroup" -->#<!-- TMPL_VAR name="column_fk_keygroup" --><!-- /TMPL_IF name="column_fk_keygroup" --></a>
                  <!-- /TMPL_IF name="column_fk" -->
                <!-- /TMPL_LOOP name="column_constraints" -->
                </td>
                <td><!-- TMPL_VAR ESCAPE="HTML" name="column" --></td>
                <td><!-- TMPL_VAR ESCAPE="HTML" name="column_type" --></td>
                <td><i>
                <!-- TMPL_LOOP name="column_constraints" -->
                    <!-- TMPL_IF name="column_primary_key" -->PRIMARY KEY
                    <!-- /TMPL_IF name="column_primary_key" -->

                    <!-- TMPL_IF name="column_unique" -->
                       UNIQUE<!-- TMPL_IF name="column_unique_keygroup" -->#<!-- TMPL_VAR name="column_unique_keygroup" --><!-- /TMPL_IF name="column_unique_keygroup" -->
                    <!-- /TMPL_IF name="column_unique" -->
                <!-- /TMPL_LOOP name="column_constraints" -->

                <!-- TMPL_IF name="column_constraint_notnull" -->NOT NULL<!-- /TMPL_IF name="column_constraint_notnull" -->
                <!-- TMPL_IF name="column_default" -->DEFAULT <!-- TMPL_VAR ESCAPE="HTML" name="column_default" --><!-- /TMPL_IF name="column_default" -->
                </i>
                <!-- TMPL_IF name="column_comment" --><br><br><!-- TMPL_VAR ESCAPE="HTML" name="column_comment" --><!-- /TMPL_IF name="column_comment" -->
                </td>
             </tr>
            <!-- /TMPL_LOOP name="columns" -->
        </table>

        <!-- Inherits -->
        <!-- TMPL_IF name="inherits" -->
        <p>Table <!-- TMPL_IF name="number_of_schemas" --><!-- TMPL_VAR ESCAPE="HTML" name="schema" -->.<!-- /TMPL_IF name="number_of_schemas" --><!-- TMPL_VAR ESCAPE="HTML" name="table" --> Inherits
        <!-- TMPL_LOOP name="inherits" -->
           <!-- TMPL_VAR name="index_name" --> <!-- TMPL_VAR name="index_definition" -->
           <a href="#<!-- TMPL_VAR ESCAPE="URL" name="parent_sgmlid" -->"><!-- TMPL_IF name="number_of_schemas" --><!-- TMPL_VAR ESCAPE="HTML" name="parent_schema" -->.<!-- /TMPL_IF name="number_of_schemas" --><!-- TMPL_VAR ESCAPE="HTML" name="parent_table" --></a>, 
        <!-- /TMPL_LOOP name="inherits" -->
        </p>
        <!-- /TMPL_IF name="inherits" -->

        <!-- Constraint List -->
        <!-- TMPL_IF name="constraints" -->
        <p>&nbsp;</p>
        <table width="100%" cellspacing="0" cellpadding="3">
            <caption><!-- TMPL_IF name="number_of_schemas" --><!-- TMPL_VAR ESCAPE="HTML" name="schema" -->.<!-- /TMPL_IF name="number_of_schemas" --><!-- TMPL_VAR ESCAPE="HTML" name="table" --> Constraints</caption>
            <tr>
                <th>Name</th>
                <th>Constraint</th>
            </tr>
            <!-- TMPL_LOOP name="constraints" -->
            <tr class="<!-- TMPL_IF name="__odd__" -->tr0<!-- TMPL_ELSE name="__odd__" -->tr1<!-- /TMPL_IF name="__odd__" -->">
                <td><!-- TMPL_VAR ESCAPE="HTML" name="constraint_name" --></td>
                <td><!-- TMPL_VAR ESCAPE="HTML" name="constraint" --></td>
            </tr>
            <!-- /TMPL_LOOP name="constraints" -->
        </table>
        <!-- /TMPL_IF name="constraints" -->

        <!-- Foreign Key Discovery -->
        <!-- TMPL_IF name="fk_schemas" -->
            <p>Tables referencing this one via Foreign Key Constraints:</p>
        <!-- TMPL_LOOP name="fk_schemas" -->
                <a href="table_<!-- TMPL_VAR ESCAPE="URL" name="fk_schema" -->.<tmpl_var fk_table>.html"><!-- TMPL_IF name="number_of_schemas" --><!-- TMPL_VAR ESCAPE="HTML" name="fk_schema" -->.<!-- /TMPL_IF name="number_of_schemas" --><!-- TMPL_VAR ESCAPE="HTML" name="fk_table" --></a><br>
        <!-- /TMPL_LOOP name="fk_schemas" -->
        <!-- /TMPL_IF name="fk_schemas" -->

    <!-- Indexes -->
    <!-- TMPL_LOOP name="indexes" -->
       <!-- TMPL_VAR name="index_name" --> <!-- TMPL_VAR name="index_definition" -->
    <!-- /TMPL_LOOP name="indexes" -->

    <!-- View Definition -->
    <!-- TMPL_IF name="view_definition" -->
    <pre><!-- TMPL_VAR ESCAPE="HTML" name="view_definition" --></pre>
    <!-- /TMPL_IF name="view_definition" -->

    <!-- List of permissions -->
    <!-- TMPL_IF name="permissions" -->
    <p>&nbsp;</p>
    <table width="100%" cellspacing="0" cellpadding="3">
        <caption>Permissions which apply to <!-- TMPL_IF name="number_of_schemas" --><!-- TMPL_VAR ESCAPE="HTML" name="schema" -->.<!-- /TMPL_IF name="number_of_schemas" --><!-- TMPL_VAR ESCAPE="HTML" name="table" --></caption>
        <tr>
            <th>User</th>
            <th><center>Select</center></th>
            <th><center>Insert</center></th>
            <th><center>Update</center></th>
            <th><center>Delete</center></th>
            <th><center>Reference</center></th>
            <th><center>Rule</center></th>
            <th><center>Trigger</center></th>
        </tr>
        <!-- TMPL_LOOP name="permissions" -->
        <tr class="<!-- TMPL_IF name="__odd__" -->tr0<!-- tmpl_else name="__odd__" -->tr1<!-- /TMPL_IF name="__odd__" -->">
            <td><!-- TMPL_VAR ESCAPE="HTML" name="user" --></td>
            <td><!-- TMPL_IF name="select" --><center>&diams;</center><!-- /TMPL_IF name="select" --></td>
            <td><!-- TMPL_IF name="insert" --><center>&diams;</center><!-- /TMPL_IF name="insert" --></td>
            <td><!-- TMPL_IF name="update" --><center>&diams;</center><!-- /TMPL_IF name="update" --></td>
            <td><!-- TMPL_IF name="delete" --><center>&diams;</center><!-- /TMPL_IF name="delete" --></td>
            <td><!-- TMPL_IF name="references" --><center>&diams;</center><!-- /TMPL_IF name="references" --></td>
            <td><!-- TMPL_IF name="rule" --><center>&diams;</center><!-- /TMPL_IF name="rule" --></td>
            <td><!-- TMPL_IF name="trigger" --><center>&diams;</center><!-- /TMPL_IF name="trigger" --></td>
        </tr>
        <!-- /TMPL_LOOP name="permissions" -->
    </table>
    <!-- /TMPL_IF name="permissions" -->

<tmpl_include footer.tmpl>
    <!-- /TMPL_LOOP name="tables" -->

<!-- ------------------------------------------------------------------------- -->
    <!-- TMPL_LOOP name="functions" -->
_CUT: func_<tmpl_var schema>.<tmpl_var function>.html
<tmpl_include header.tmpl>
        <h2>Function:
            <a href="#<!-- TMPL_VAR ESCAPE="HTML" name="schema_sgmlid" -->"><!-- TMPL_IF name="number_of_schemas" --><!-- TMPL_VAR ESCAPE="HTML" name="schema" --></a>.<!-- /TMPL_IF name="number_of_schemas" --><a name="<!-- TMPL_VAR ESCAPE="URL" name="function_sgmlid" -->"><!-- TMPL_VAR ESCAPE="HTML" name="function" --></a>
        </h2>
<h3>Returns: <!-- TMPL_VAR ESCAPE="HTML" name="function_returns" --></h3>
<h3>Language: <!-- TMPL_VAR ESCAPE="HTML" name="function_language" --></h3>
        <!-- TMPL_IF name="function_comment" --><p><!-- TMPL_VAR ESCAPE="HTML" name="function_comment" --></p><!-- /TMPL_IF name="function_comment" -->
        <pre><!-- TMPL_IF name="function_source" --><!-- TMPL_VAR ESCAPE="HTML" name="function_source" --><!-- /TMPL_IF name="function_source" --></pre>
<tmpl_include footer.tmpl>
    <!-- /TMPL_LOOP name="functions" -->

</tmpl_loop name="schemas">
END_HTML
<tmpl_loop schemas><tmpl_loop tables>
_CUT: <tmpl_if view_definition>view<tmpl_else>table</tmpl_if>_<tmpl_var table>.pod
=head1 NAME

<tmpl_var table>

=head1 DESCRIPTION

<tmpl_var table_comment>

=head1 FIELDS

<tmpl_loop columns> <tmpl_var column> (<tmpl_var column_type>) - <tmpl_var column_comment>
</tmpl_loop>

=head1 SCHEMA

_DB: \d+ <tmpl_var table>

=cut

</tmpl_loop>
</tmpl_loop>


END_POD

digraph g {
graph [
rankdir = "LR",
concentrate = true,
ratio = auto
];
node [
fontsize = "10",
shape = record
];
edge [
];
<TMPL_LOOP name="schemas"><TMPL_LOOP name="tables"><TMPL_UNLESS name="view_definition">
"<TMPL_IF name="number_of_schemas"><TMPL_VAR name="schema_dot">.</TMPL_IF name="number_of_schemas"><TMPL_VAR name="table_dot">" [shape = plaintext, label = < <TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0"> <TR ><TD PORT="ltcol0"> </TD> <TD bgcolor="grey90" border="1" COLSPAN="4"> \N </TD> <TD PORT="rtcol0"></TD></TR> <TMPL_LOOP name="columns"> <TR><TD PORT="ltcol<TMPL_VAR name="column_number">" ></TD><TD align="left" > <TMPL_VAR name="column_dot"> </TD><TD align="left" > <TMPL_VAR name="column_type"> </TD><TD align="left" > <TMPL_LOOP name="column_constraints"><TMPL_IF NAME="column_primary_key">PK</TMPL_IF NAME="column_primary_key"></TMPL_LOOP name="column_constraints"> </TD><TD align="left" > <TMPL_LOOP name="column_constraints"><TMPL_IF NAME="column_fk"><TMPL_IF NAME="__first__">FK</TMPL_IF NAME="__first__"></TMPL_IF NAME="column_fk"></TMPL_LOOP name="column_constraints"> </TD><TD align="left" PORT="rtcol<TMPL_VAR name="column_number">"> </TD></TR></TMPL_LOOP name="columns"> </TABLE>> ];
</TMPL_UNLESS name="view_definition"></TMPL_LOOP name="tables"></TMPL_LOOP name="schemas">

<TMPL_LOOP name="fk_links">
"<TMPL_IF name="number_of_schemas"><TMPL_VAR name="handle0_schema">.</TMPL_IF name="number_of_schemas"><TMPL_VAR name="handle0_name">":rtcol<TMPL_VAR name="handle0_connection"> -> "<TMPL_IF name="number_of_schemas"><TMPL_VAR name="handle1_schema">.</TMPL_IF name="number_of_schemas"><TMPL_VAR name="handle1_name">":ltcol<TMPL_VAR name="handle1_connection"> [label="<TMPL_VAR name="fk_link_name_dot">"];</TMPL_LOOP name="fk_links">
}

END_DOT


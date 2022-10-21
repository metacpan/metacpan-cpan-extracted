#!/usr/bin/perl

use strict;
use warnings;

use JSON;
use OpenAPI::Render::HTMLForms;
use Test::More tests => 1;

open( my $inp, 't/RestfulDB-API.json' );
my $api = OpenAPI::Render::HTMLForms->new( decode_json( join '', <$inp> ) );
close $inp;

is( $api->show . "\n", <<END, 'HTML forms generation works' );
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title>RestfulDB API v0.13.0-dev</title>
<script type="text/javascript">//<![CDATA[


function replace_url_parameters( form ) {
    var url = form.getAttribute( "action" );
    var inputs = form.getElementsByTagName( "input" );
    for( var i = 0; i < inputs.length; i++ ) {
        var data_in_path = inputs[i].getAttribute( "data-in-path" );
        if( data_in_path ) {
            url = url.replace( "{" + inputs[i].name + "}", inputs[i].value );
            inputs[i].disabled = "disabled";
        }
    }
    form.setAttribute( "action", url );
}


//]]></script>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
</head>
<body>
<h1>/{table}</h1><form method="get" action="https://solsa.crystallography.net/db/samples/{table}" enctype="multipart/form-data"><fieldset><legend>GET: Get list of entries</legend><h3>table</h3><p>Name of the table</p><input data-in-path="1" name="table" placeholder="books" required="required" type="text" /><h3>rows</h3><p>Number of entries per page</p><input name="rows" type="text" /><h3>offset</h3><p>Offset of the first entry</p><input name="offset" type="text" /><h3>filter</h3><p>Filter to select entries to show</p><input name="filter" placeholder="solsaid STARTS WITH &quot;TEST&quot;" type="text" /><h3>columns</h3><p>Comma-separated list of columns that are requested in the output</p><input name="columns" placeholder="id,SolsaID" type="text" /><h3>format</h3><p>Requested return format. 'html' by default</p><select name="format" >
<option value=""></option>
<option value="html">html</option>
<option value="csv">csv</option>
<option value="xlsx">xlsx</option>
<option value="json">json</option>
<option value="jsonapi">jsonapi</option>
</select><h3>order</h3><p>Database ordering, e.g.: 'order=revision:u,date:d'. Specifies a comma-separated list of database columns, together with a ':' delimited order specifiers ('a' == ascending, asc; 'd' == descending, desc)</p><input name="order" placeholder="order=revision:u,date:d" type="text" /><h3>action</h3><p>Specify the action. Solely used to download templates as of now with 'action=template'.</p><select name="action" >
<option value=""></option>
<option value="template">template</option>
</select><h3>select_column</h3><p>Column to perform the search.</p><input name="select_column" placeholder="SolsaID" type="text" /><h3>select_operator</h3><p>Operator to perform the search with.</p><select name="select_operator" >
<option value=""></option>
<option value="eq">eq</option>
<option value="ne">ne</option>
<option value="gt">gt</option>
<option value="lt">lt</option>
<option value="le">le</option>
<option value="ge">ge</option>
<option value="contains">contains</option>
<option value="starts">starts</option>
<option value="ends">ends</option>
<option value="known">known</option>
<option value="unknown">unknown</option>
</select><h3>search_value</h3><p>Search value.</p><input name="search_value" placeholder="TEST-XX-0001" type="text" /><h3>select_not_operator</h3><p>Invert the matching.</p><select name="select_not_operator" >
<option value=""></option>
<option value="not">not</option>
</select><h3>select_combining</h3><p>Combination with previously submitted query (conjunction, disjunction or new).</p><select name="select_combining" >
<option value=""></option>
<option value="new">new</option>
<option value="append">append</option>
<option value="within">within</option>
</select><h3>include</h3><p>A comma-separated list of tables to be returned in the response. If not provided, all tables are returned. Currently only supported for spreadsheet downloads.</p><input name="include" placeholder="sample,experiment" type="text" /><input type="submit" onclick="replace_url_parameters( this.form )" /></fieldset>
</form><form method="post" action="https://solsa.crystallography.net/db/samples/{table}" enctype="multipart/form-data"><fieldset><legend>POST: Insert or update entry or entries in a table</legend><h3>table</h3><p>Name of the table</p><input data-in-path="1" name="table" placeholder="books" required="required" type="text" /><h3>csvfile</h3><input type="file" name="csvfile"  /><h3>jsonfile</h3><input type="file" name="jsonfile"  /><h3>odsfile</h3><input type="file" name="odsfile"  /><h3>spreadsheet</h3><input type="file" name="spreadsheet"  /><h3>xlsfile</h3><input type="file" name="xlsfile"  /><h3>xlsxfile</h3><input type="file" name="xlsxfile"  /><input type="submit" onclick="replace_url_parameters( this.form )" /></fieldset>
</form><form method="patch" action="https://solsa.crystallography.net/db/samples/{table}" enctype="multipart/form-data"><fieldset><legend>PATCH: Update entry or entries in a table</legend><h3>table</h3><p>Name of the table</p><input data-in-path="1" name="table" placeholder="books" required="required" type="text" /><h3>csvfile</h3><input type="file" name="csvfile"  /><h3>jsonfile</h3><input type="file" name="jsonfile"  /><h3>odsfile</h3><input type="file" name="odsfile"  /><h3>spreadsheet</h3><input type="file" name="spreadsheet"  /><h3>xlsfile</h3><input type="file" name="xlsfile"  /><h3>xlsxfile</h3><input type="file" name="xlsxfile"  /><input type="submit" name="Submit Query (cannot be handled for PATCH)" value="Submit Query (cannot be handled for PATCH)" disabled="disabled" /></fieldset>
</form><form method="put" action="https://solsa.crystallography.net/db/samples/{table}" enctype="multipart/form-data"><fieldset><legend>PUT: Insert entry or entries in a table</legend><h3>table</h3><p>Name of the table</p><input data-in-path="1" name="table" placeholder="books" required="required" type="text" /><h3>csvfile</h3><input type="file" name="csvfile"  /><h3>jsonfile</h3><input type="file" name="jsonfile"  /><h3>odsfile</h3><input type="file" name="odsfile"  /><h3>spreadsheet</h3><input type="file" name="spreadsheet"  /><h3>xlsfile</h3><input type="file" name="xlsfile"  /><h3>xlsxfile</h3><input type="file" name="xlsxfile"  /><input type="submit" name="Submit Query (cannot be handled for PUT)" value="Submit Query (cannot be handled for PUT)" disabled="disabled" /></fieldset>
</form><h1>/{table}/{id}</h1><form method="get" action="https://solsa.crystallography.net/db/samples/{table}/{id}" enctype="multipart/form-data"><fieldset><legend>GET: Get an entry by its ID</legend><h3>table</h3><p>Name of the table</p><input data-in-path="1" name="table" placeholder="books" required="required" type="text" /><h3>id</h3><p>Unique identifier of an entry. ID and UUID are supported. In principle other unique keys should work as well.</p><input data-in-path="1" name="id" placeholder="1" required="required" type="text" /><h3>format</h3><p>Requested return format. 'html' by default</p><select name="format" >
<option value=""></option>
<option value="html">html</option>
<option value="csv">csv</option>
<option value="xlsx">xlsx</option>
<option value="json">json</option>
<option value="jsonapi">jsonapi</option>
</select><h3>order</h3><p>Database ordering, e.g.: 'order=revision:u,date:d'. Specifies a comma-separated list of database columns, together with a ':' delimited order specifiers ('a' == ascending, asc; 'd' == descending, desc)</p><input name="order" placeholder="order=revision:u,date:d" type="text" /><input type="submit" onclick="replace_url_parameters( this.form )" /></fieldset>
</form><form method="post" action="https://solsa.crystallography.net/db/samples/{table}/{id}" enctype="multipart/form-data"><fieldset><legend>POST: Insert or update an entry</legend><h3>table</h3><p>Name of the table</p><input data-in-path="1" name="table" placeholder="books" required="required" type="text" /><h3>id</h3><p>Unique identifier of an entry. ID and UUID are supported. In principle other unique keys should work as well.</p><input data-in-path="1" name="id" placeholder="1" required="required" type="text" /><h3>csvfile</h3><input type="file" name="csvfile"  /><h3>jsonfile</h3><input type="file" name="jsonfile"  /><h3>odsfile</h3><input type="file" name="odsfile"  /><h3>spreadsheet</h3><input type="file" name="spreadsheet"  /><h3>xlsfile</h3><input type="file" name="xlsfile"  /><h3>xlsxfile</h3><input type="file" name="xlsxfile"  /><input type="submit" onclick="replace_url_parameters( this.form )" /></fieldset>
</form><form method="patch" action="https://solsa.crystallography.net/db/samples/{table}/{id}" enctype="multipart/form-data"><fieldset><legend>PATCH: Update an entry</legend><h3>table</h3><p>Name of the table</p><input data-in-path="1" name="table" placeholder="books" required="required" type="text" /><h3>id</h3><p>Unique identifier of an entry. ID and UUID are supported. In principle other unique keys should work as well.</p><input data-in-path="1" name="id" placeholder="1" required="required" type="text" /><h3>csvfile</h3><input type="file" name="csvfile"  /><h3>jsonfile</h3><input type="file" name="jsonfile"  /><h3>odsfile</h3><input type="file" name="odsfile"  /><h3>spreadsheet</h3><input type="file" name="spreadsheet"  /><h3>xlsfile</h3><input type="file" name="xlsfile"  /><h3>xlsxfile</h3><input type="file" name="xlsxfile"  /><input type="submit" name="Submit Query (cannot be handled for PATCH)" value="Submit Query (cannot be handled for PATCH)" disabled="disabled" /></fieldset>
</form><form method="put" action="https://solsa.crystallography.net/db/samples/{table}/{id}" enctype="multipart/form-data"><fieldset><legend>PUT: Insert an entry to a table</legend><h3>table</h3><p>Name of the table</p><input data-in-path="1" name="table" placeholder="books" required="required" type="text" /><h3>id</h3><p>Unique identifier of an entry. ID and UUID are supported. In principle other unique keys should work as well.</p><input data-in-path="1" name="id" placeholder="1" required="required" type="text" /><h3>csvfile</h3><input type="file" name="csvfile"  /><h3>jsonfile</h3><input type="file" name="jsonfile"  /><h3>odsfile</h3><input type="file" name="odsfile"  /><h3>spreadsheet</h3><input type="file" name="spreadsheet"  /><h3>xlsfile</h3><input type="file" name="xlsfile"  /><h3>xlsxfile</h3><input type="file" name="xlsxfile"  /><input type="submit" name="Submit Query (cannot be handled for PUT)" value="Submit Query (cannot be handled for PUT)" disabled="disabled" /></fieldset>
</form><form method="delete" action="https://solsa.crystallography.net/db/samples/{table}/{id}" enctype="multipart/form-data"><fieldset><legend>DELETE: Delete an entry</legend><h3>table</h3><p>Name of the table</p><input data-in-path="1" name="table" placeholder="books" required="required" type="text" /><h3>id</h3><p>Unique identifier of an entry. ID and UUID are supported. In principle other unique keys should work as well.</p><input data-in-path="1" name="id" placeholder="1" required="required" type="text" /><input type="submit" name="Submit Query (cannot be handled for DELETE)" value="Submit Query (cannot be handled for DELETE)" disabled="disabled" /></fieldset>
</form><h1>/{table}/{id}/{field}</h1><form method="get" action="https://solsa.crystallography.net/db/samples/{table}/{id}/{field}" enctype="multipart/form-data"><fieldset><legend>GET: Get a file stored in entry's field</legend><h3>table</h3><p>Name of the table</p><input data-in-path="1" name="table" placeholder="books" required="required" type="text" /><h3>id</h3><p>Unique identifier of an entry. ID and UUID are supported. In principle other unique keys should work as well.</p><input data-in-path="1" name="id" placeholder="1" required="required" type="text" /><h3>field</h3><input data-in-path="1" name="field" required="required" type="text" /><input type="submit" onclick="replace_url_parameters( this.form )" /></fieldset>
</form>
</body>
</html>
END

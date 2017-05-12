# ------ Provide anchored SQL wildcards ('^', '$')
package SQL::AnchoredWildcards;



# ------ use/require pragmas
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
require Exporter;



# ------ define variables
@ISA = qw(Exporter);		# we are an Exporter
@EXPORT = 			# we export by default:
 qw(sql_anchor_wildcards);	# a function for anchoring SQL wildcards
@EXPORT_OK = ();		# we export nothing upon request
$VERSION = 1.0;




# Preloaded methods go here.


# ------ enhance SQL wildcard processing by simulating '^' and '$'
sub sql_anchor_wildcards {
	local $_ = shift;	# copy of unenhanced searchtext


	# ------ escape SQL '%' and convert to lower case
	s/%/\%/g;
	tr/A-Z/a-z/;


	# ------ search unanchored at start by user's choice
	if (m/^%/o) {
		;			# do nothing


	# ------ search anchored at start
	} elsif (m/^\^/o) {
		s/^\^//o;		# convert to anchored at start SQL


	# ------ search not anchored at start, but begins with escaped '^'
	} elsif (m/^\\\^/o) {
		s/^\\//o;		# allow escaped '^'
		$_ = "%" . $_;		# convert to unanchored SQL search


	# ------ search not anchored at start
	} else {
		$_ = "%" . $_;		# converted to unanchored SQL search
	}


	# ------ search unanchored at end
	if (m/%$/o) {
		;			# do nothing


	# ------ search not anchored at end, but ends with escaped '$'
	} elsif (m/\\\$$/o) {
		s/\\\$$/\$/o;		# allow escaped '$'
		$_ .= "%";		# convert to unanchored SQL search


	# ------ search anchored at end
	} elsif (m/\$$/o) {
		s/\$$//o;		# convert to anchored at end SQL search


	# ------ search not anchored at end
	} else {
		$_ .= "%";		# convert to unanchored SQL search
	}

	# return converted searchtext
	return $_;
}
1;



# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__



=head1 NAME

SQL::AnchoredWildcards - add anchors ('^', '$') to SQL wildcards

=head1 SYNOPSIS

  use SQL::AnchoredWildcards;
  $pattern = sql_anchor_wildcards($pattern);

=head1 DESCRIPTION

SQL::AnchorWildcards enhances the default SQL SELECT..LIKE wildcard
processing by adding support for the '^' and '$' anchor metacharacters.
When using sql_anchor_wildcards(), if the pattern does not contain
'^' ('$'), the search pattern is unanchored at the
beginning (end).  Escaping of '^' and '$' is done with '\'.

Please also note that '$' is properly escaped for Perl's
benefit.

=head1 EXAMPLES

Let's take an SQL SELECT...LIKE Perl statement as in:

  my $query = new CGI;
  $query->import_names('Q');
  my $SQL =<<endSQL;
    SELECT
     GROUPNAME,
     GROUPID
    FROM
     TSR_GROUPS
    WHERE
     GROUPNAME LIKE '$Q::search';
  endSQL

which will yield the SQL statement:

    SELECT
     GROUPNAME,
     GROUPID
    FROM
     TSR_GROUPS
    WHERE
     GROUPNAME LIKE 'HDTV';

when the user has typed 'HDTV' into the text box named 'search'
on the CGI input form.  If 'HDTV' is the search term, then
SQL SELECT..LIKE will only find groups whose name matches /^HDTV$/.
If the CGI uses:

  $Q::search = sql_anchor_wildcards($Q::search);

the SQL statement becomes:

    SELECT
     GROUPNAME,
     GROUPID
    FROM
     TSR_GROUPS
    WHERE
     GROUPNAME LIKE '%HDTV%';

which will find all groups that have 'HDTV' as part of the group's name.  I
think that most people that use a Web-based search engine would expect
that typing 'HDTV' into a search box would make the search engine
find all groups that have 'HDTV' as part of the group's name.

But what if you only want to find groups whose name starts with 'HDTV' --
say, all HDTV engineering groups like 'HDTV Power Supply Design' where
other, non-engineering groups would have 'HDTV' later in their names, like
'Marketing & Sales -- HDTV Direct View'?  In that case with 
SQL::AnchoredWildcards, you would type '^HDTV' into the CGI search box, with:

    SELECT
     GROUPNAME,
     GROUPID
    FROM
     TSR_GROUPS
    WHERE
     GROUPNAME LIKE 'HDTV%';

as the resulting SQL.  As you would expect, this SQL SELECT..LIKE
statement would find groups whose name starts with 'HDTV'.

Similarly, if you know that the groups you want are those that have 'HDTV'
as the last component of their names, like 'Marketing & Sales -- Direct View
HDTV', you would type 'HDTV$' into the CGI search box, with:

    SELECT
     GROUPNAME,
     GROUPID
    FROM
     TSR_GROUPS
    WHERE
     GROUPNAME LIKE '%HDTV';

as the resulting SQL.

If you are looking for an embedded '$', as in:

    DCL LOGICAL $SYS_INFO

you would type 'DCL LOGICAL \$SYS_INFO' into the CGI search box, with:

    SELECT
     GROUPNAME,
     GROUPID
    FROM
     TSR_GROUPS
    WHERE
     GROUPNAME LIKE 'DCL LOGICAL $SYS_INFO';

as the resulting SQL.



=head1 AUTHOR

Mark Leighton Fisher, fisherm@tce.com

=head1 SEE ALSO

perl(1).

=cut

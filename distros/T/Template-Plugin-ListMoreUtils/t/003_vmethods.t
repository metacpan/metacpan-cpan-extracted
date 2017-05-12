# -*- perl -*-

# t/003_vmethods.t - tests using the virtual methods

use Test::More tests => 52;

is tt( q{[% my1to9even.merge( my1to9prim, my1to9odd ).uniq.join(""); %]} ), "246835719", "uniq 1/2";
is tt( q{[% l = [ 1, 1, 2, 2, 3, 5, 3, 4 ]; l.uniq.join(""); %]} ), "12354", "uniq 2/2";

is tt( q{[% my1to9even.merge( my1to9prim, my1to9odd ).singleton.join(""); %]} ), "46819", "singleton 1/2";
is tt( q{[% l = [ 1, 1, 2, 2, 3, 5, 3, 4 ]; l.singleton.join(""); %]} ), "54", "singleton 2/2";

is tt( q{[% my1to9even.merge( my1to9prim, my1to9odd ).minmax.join(""); %]} ), "19", "minmax 1/2";
is tt( q{[% l = [ 1, 1, 2, 2, 3, 5, 3, 4 ]; l.minmax.join(""); %]} ), "15", "minmax 2/2";

is tt( q{[% fiveletters.mesh( my1to9odd ).join(""); %]} ), "a1b3c5d7e9", "mesh";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9prim.any( \even ) ? "Any" : "None" %]} ), "Any", "any 1/2";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9odd.any( \even ) ? "Any" : "None" %]} ), "None", "any 2/2";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9even.all( \even ) ? "All" : "Not all" %]} ), "All", "all 1/2";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9odd.all( \even ) ? "All" : "Not all" %]} ), "Not all", "all 2/2";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9odd.none( \even ) ? "None" : "Some" %]} ), "None", "none 1/2";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9even.none( \even ) ? "None" : "Some" %]} ), "Some", "none 2/2";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9prim.notall( \even ) ? "Not all" : "All" %]} ), "Not all", "notall 1/2";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9even.notall( \even ) ? "Not all" : "All" %]} ), "All", "notall 2/2";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9odd.true( \even ) %]} ), "0", "true 1/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9prim.true( \even ) %]} ), "1", "true 2/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9even.true( \even ) %]} ), "4", "true 3/3";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9odd.false( \even ) %]} ), "5", "false 1/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9prim.false( \even ) %]} ), "3", "false 2/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9even.false( \even ) %]} ), "0", "false 3/3";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9odd.firstidx( \even ) %]} ), "-1", "firstidx 1/3";
is tt( q/[% PERL %] my $fn = sub { 0 != $_ % 2 }; $stash->set( odd => $fn ); [% END %]/,
       q{[% my1to9prim.firstidx( \odd ) %]} ), "1", "firstidx 2/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9even.firstidx( \even ) %]} ), "0", "firstidx 3/3";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9odd.lastidx( \even ) %]} ), "-1", "lastidx 1/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9prim.lastidx( \even ) %]} ), "0", "lastidx 2/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9even.lastidx( \even ) %]} ), "3", "lastidx 3/3";

is tt( q/[% PERL %] my $fn = sub { $_ eq 'a' }; $stash->set( is_an_a => $fn ); [% END %]/,
       q{[% longlist.insert_after( \is_an_a, "longer" ) && longlist.join(" ") %]} ), "This is a longer list", "insert_after";

is tt( q{[% longlist.insert_after_string( "a", "longer" ) && longlist.join(" ") %]} ), "This is a longer list", "insert_after_string";

is tt( q/[% PERL %] my $fn = sub { $_ *= 2 }; $stash->set( double => $fn ); [% END %]/,
       q{[% doubles = my1to9odd.apply( \double ); doubles.join(",") %]} ), "2,6,10,14,18", "apply";

is tt( q/[% PERL %] my $fn = sub { 0 != $_ % 2 }; $stash->set( odd => $fn ); [% END %]/,
       q{[% oddprimgt3 = my1to9prim.after( \odd ); oddprimgt3.join(",") %]} ), "5,7", "after";
is tt( q/[% PERL %] my $fn = sub { 0 != $_ % 2 }; $stash->set( odd => $fn ); [% END %]/,
       q{[% oddprim = my1to9prim.after_incl( \odd ); oddprim.join(",") %]} ), "3,5,7", "after_incl";

is tt( q/[% PERL %] my $fn = sub { 0 != $_ % 2 }; $stash->set( odd => $fn ); [% END %]/,
       q{[% primlt3 = my1to9prim.before( \odd ); primlt3.join(",") %]} ), "2", "before";
is tt( q/[% PERL %] my $fn = sub { 0 != $_ % 2 }; $stash->set( odd => $fn ); [% END %]/,
       q{[% primto3 = my1to9prim.before_incl( \odd ); primto3.join(",") %]} ), "2,3", "before_incl";

is tt( q/[% PERL %] my $fn = sub { 0 != $_ % 2 }; $stash->set( odd => $fn ); [% END %]/,
       q{[% oddidx = my1to9prim.indexes( \odd ); oddidx.join(",") %]} ), "1,2,3", "indexes";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9odd.firstval( \even ) %]} ), "", "firstval 1/3";
is tt( q/[% PERL %] my $fn = sub { 0 != $_ % 2 }; $stash->set( odd => $fn ); [% END %]/,
       q{[% my1to9prim.firstval( \odd ) %]} ), "3", "firstval 2/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9even.firstval( \even ) %]} ), "2", "firstval 3/3";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9odd.lastval( \even ) %]} ), "", "lastval 1/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9prim.lastval( \even ) %]} ), "2", "lastval 2/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% my1to9even.lastval( \even ) %]} ), "8", "lastval 3/3";

is tt( q/[% PERL %] my $fn = sub { $_[0] + $_[1] }; $stash->set( add => $fn ); [% END %]/,
       q{[% my1to9even.pairwise( \add, my1to9prim ).join(",") %]} ), "4,7,11,15", "pairwise 1/2";
is tt( q/[% PERL %] my $fn = sub { $_[0] . $_[1] }; $stash->set( concat => $fn ); [% END %]/,
       q{[% fourletters.pairwise( \concat, my1to9prim ).join(",") %]} ), "a2,b3,c5,d7", "pairwise 2/2";

is tt( q/[% PERL %] my $i = 0; my $fn = sub { $_[0]->[$i++] % 2 }; $stash->set( mod2 => $fn ); [% END %]/,
       q{[% parts = my1to9even.merge( my1to9prim, my1to9odd ).part( \mod2 );
            parts.0 = parts.0.join(","); parts.1 = parts.1.join(","); parts.join(":"); %]} ), "2,4,6,8,2:3,5,7,1,3,5,7,9", "part";

is tt( q/[% PERL %] my $fn = sub { $_[0] <=> 3 }; $stash->set( cmp3 => $fn ); [% END %]/,
       q{[% my1to9prim.bsearch( \cmp3 ) ? "Found" : "Not found" %]} ), "Found", "bsearch 1/4";
is tt( q/[% PERL %] my $fn = sub { $_[0] cmp 'e' }; $stash->set( cmpe => $fn ); [% END %]/,
       q{[% fiveletters.bsearch( \cmpe ) ? "Found" : "Not found" %]} ), "Found", "bsearch 2/4";
is tt( q/[% PERL %] my $fn = sub { 3 <=> $_[0] }; $stash->set( cmp3 => $fn ); [% END %]/,
       q{[% my1to9prim.reverse.bsearch( \cmp3 ) ? "Found" : "Not found" %]} ), "Found", "bsearch 3/4";
is tt( q/[% PERL %] my $fn = sub { $_[0] <=> 9 }; $stash->set( cmp9 => $fn ); [% END %]/,
       q{[% my1to9prim.bsearch( \cmp9 ) ? "Found" : "Not found" %]} ), "Not found", "bsearch 4/4";

is tt( q/[% PERL %] my $fn = sub { $_[0] <=> 3 }; $stash->set( cmp3 => $fn ); [% END %]/,
       q{[% my1to9prim.bsearchidx( \cmp3 ) %]} ), "1", "bsearchidx 1/4";
is tt( q/[% PERL %] my $fn = sub { $_[0] cmp 'e' }; $stash->set( cmpe => $fn ); [% END %]/,
       q{[% fiveletters.bsearchidx( \cmpe ) %]} ), "4", "bsearchidx 2/4";
is tt( q/[% PERL %] my $fn = sub { 3 <=> $_[0] }; $stash->set( cmp3 => $fn ); [% END %]/,
       q{[% my1to9prim.reverse.bsearchidx( \cmp3 ) %]} ), "2", "bsearchidx 3/4";
is tt( q/[% PERL %] my $fn = sub { $_[0] <=> 9 }; $stash->set( cmp9 => $fn ); [% END %]/,
       q{[% my1to9prim.bsearchidx( \cmp9 ) %]} ), "-1", "bsearchidx 4/4";

sub tt
{
    my $template = join( '', q{[% my1to9even  = [ 2, 4, 6, 8 ];
                        my1to9prim  = [ 2, 3, 5, 7 ];
                        my1to9odd   = [ 1, 3, 5, 7, 9 ];
			fourletters = [ 'a', 'b', 'c', 'd' ];
			fiveletters = [ 'a', 'b', 'c', 'd', 'e' ];
			longlist    = [ 'This', 'is', 'a', 'list' ];
                        USE ListMoreUtilsVMethods; %]}, @_ );
    use Template;
    my $tt = Template->new( { EVAL_PERL => 1, }, );
    my $output;
    $tt->process( \$template, {}, \$output ) or
      die "Problem while processing '$template': " . $tt->error();
    return $output;
}

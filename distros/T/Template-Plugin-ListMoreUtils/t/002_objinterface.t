# -*- perl -*-

# t/002_objinterface.t - tests using the OO interface

use Test::More tests => 52;

is tt( q{[% ListMoreUtils.uniq( my1to9even.merge( my1to9prim, my1to9odd ) ).join(""); %]} ), "246835719", "uniq 1/2";
is tt( q{[% ListMoreUtils.uniq( [ 1, 1, 2, 2, 3, 5, 3, 4 ] ).join(""); %]} ), "12354", "uniq 2/2";

is tt( q{[% ListMoreUtils.singleton( my1to9even.merge( my1to9prim, my1to9odd ) ).join(""); %]} ), "46819", "singleton 1/2";
is tt( q{[% ListMoreUtils.singleton( [ 1, 1, 2, 2, 3, 5, 3, 4 ] ).join(""); %]} ), "54", "singleton 2/2";

is tt( q{[% ListMoreUtils.minmax( my1to9even.merge( my1to9prim, my1to9odd ) ).join(""); %]} ), "19", "minmax 1/2";
is tt( q{[% ListMoreUtils.minmax( [ 1, 1, 2, 2, 3, 5, 3, 4 ] ).join(""); %]} ), "15", "minmax 2/2";

is tt( q{[% ListMoreUtils.mesh( fiveletters, my1to9odd ).join(""); %]} ), "a1b3c5d7e9", "mesh";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.any( \even, my1to9prim ) ? "Any" : "None" %]} ), "Any", "any 1/2";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.any( \even, my1to9odd ) ? "Any" : "None" %]} ), "None", "any 2/2";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.all( \even, my1to9even ) ? "All" : "Not all" %]} ), "All", "all 1/2";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.all( \even, my1to9odd ) ? "All" : "Not all" %]} ), "Not all", "all 2/2";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.none( \even, my1to9odd ) ? "None" : "Some" %]} ), "None", "none 1/2";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.none( \even, my1to9even ) ? "None" : "Some" %]} ), "Some", "none 2/2";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.notall( \even, my1to9prim ) ? "Not all" : "All" %]} ), "Not all", "notall 1/2";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.notall( \even, my1to9even ) ? "Not all" : "All" %]} ), "All", "notall 2/2";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.true( \even, my1to9odd ) %]} ), "0", "true 1/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.true( \even, my1to9prim ) %]} ), "1", "true 2/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.true( \even, my1to9even ) %]} ), "4", "true 3/3";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.false( \even, my1to9odd ) %]} ), "5", "false 1/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.false( \even, my1to9prim ) %]} ), "3", "false 2/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.false( \even, my1to9even ) %]} ), "0", "false 3/3";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.firstidx( \even, my1to9odd ) %]} ), "-1", "firstidx 1/3";
is tt( q/[% PERL %] my $fn = sub { 0 != $_ % 2 }; $stash->set( odd => $fn ); [% END %]/,
       q{[% ListMoreUtils.firstidx( \odd, my1to9prim ) %]} ), "1", "firstidx 2/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.firstidx( \even, my1to9even ) %]} ), "0", "firstidx 3/3";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.lastidx( \even, my1to9odd ) %]} ), "-1", "lastidx 1/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.lastidx( \even, my1to9prim ) %]} ), "0", "lastidx 2/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.lastidx( \even, my1to9even ) %]} ), "3", "lastidx 3/3";

is tt( q/[% PERL %] my $fn = sub { $_ eq 'a' }; $stash->set( is_an_a => $fn ); [% END %]/,
       q{[% ListMoreUtils.insert_after( \is_an_a, "longer", longlist ) && longlist.join(" ") %]} ), "This is a longer list", "insert_after";

is tt( q{[% ListMoreUtils.insert_after_string( "a", "longer", longlist ) && longlist.join(" ") %]} ), "This is a longer list", "insert_after_string";

is tt( q/[% PERL %] my $fn = sub { $_ *= 2 }; $stash->set( double => $fn ); [% END %]/,
       q{[% doubles = ListMoreUtils.apply( \double, my1to9odd ); doubles.join(",") %]} ), "2,6,10,14,18", "apply";

is tt( q/[% PERL %] my $fn = sub { 0 != $_ % 2 }; $stash->set( odd => $fn ); [% END %]/,
       q{[% oddprimgt3 = ListMoreUtils.after( \odd, my1to9prim ); oddprimgt3.join(",") %]} ), "5,7", "after";
is tt( q/[% PERL %] my $fn = sub { 0 != $_ % 2 }; $stash->set( odd => $fn ); [% END %]/,
       q{[% oddprim = ListMoreUtils.after_incl( \odd, my1to9prim ); oddprim.join(",") %]} ), "3,5,7", "after_incl";

is tt( q/[% PERL %] my $fn = sub { 0 != $_ % 2 }; $stash->set( odd => $fn ); [% END %]/,
       q{[% primlt3 = ListMoreUtils.before( \odd, my1to9prim ); primlt3.join(",") %]} ), "2", "before";
is tt( q/[% PERL %] my $fn = sub { 0 != $_ % 2 }; $stash->set( odd => $fn ); [% END %]/,
       q{[% primto3 = ListMoreUtils.before_incl( \odd, my1to9prim ); primto3.join(",") %]} ), "2,3", "before_incl";

is tt( q/[% PERL %] my $fn = sub { 0 != $_ % 2 }; $stash->set( odd => $fn ); [% END %]/,
       q{[% oddidx = ListMoreUtils.indexes( \odd, my1to9prim ); oddidx.join(",") %]} ), "1,2,3", "indexes";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.firstval( \even, my1to9odd ) %]} ), "", "firstval 1/3";
is tt( q/[% PERL %] my $fn = sub { 0 != $_ % 2 }; $stash->set( odd => $fn ); [% END %]/,
       q{[% ListMoreUtils.firstval( \odd, my1to9prim ) %]} ), "3", "firstval 2/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.firstval( \even, my1to9even ) %]} ), "2", "firstval 3/3";

is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.lastval( \even, my1to9odd ) %]} ), "", "lastval 1/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.lastval( \even, my1to9prim ) %]} ), "2", "lastval 2/3";
is tt( q/[% PERL %] my $fn = sub { 0 == $_ % 2 }; $stash->set( even => $fn ); [% END %]/,
       q{[% ListMoreUtils.lastval( \even, my1to9even ) %]} ), "8", "lastval 3/3";

is tt( q/[% PERL %] my $fn = sub { $_[0] + $_[1] }; $stash->set( add => $fn ); [% END %]/,
       q{[% ListMoreUtils.pairwise( \add, my1to9even, my1to9prim ).join(",") %]} ), "4,7,11,15", "pairwise 1/2";
is tt( q/[% PERL %] my $fn = sub { $_[0] . $_[1] }; $stash->set( concat => $fn ); [% END %]/,
       q{[% ListMoreUtils.pairwise( \concat, fourletters, my1to9prim ).join(",") %]} ), "a2,b3,c5,d7", "pairwise 2/2";

is tt( q/[% PERL %] my $i = 0; my $fn = sub { $_[1]->[$i++] % 2 }; $stash->set( mod2 => $fn ); [% END %]/,
       q{[% parts = ListMoreUtils.part( \mod2, my1to9even.merge( my1to9prim, my1to9odd ) );
            parts.0 = parts.0.join(","); parts.1 = parts.1.join(","); parts.join(":"); %]} ), "2,4,6,8,2:3,5,7,1,3,5,7,9", "part";

is tt( q/[% PERL %] my $fn = sub { $_[0] <=> 3 }; $stash->set( cmp3 => $fn ); [% END %]/,
       q{[% ListMoreUtils.bsearch( \cmp3, my1to9prim ) ? "Found" : "Not found" %]} ), "Found", "bsearch 1/4";
is tt( q/[% PERL %] my $fn = sub { $_[0] cmp 'e' }; $stash->set( cmpe => $fn ); [% END %]/,
       q{[% ListMoreUtils.bsearch( \cmpe, fiveletters ) ? "Found" : "Not found" %]} ), "Found", "bsearch 2/4";
is tt( q/[% PERL %] my $fn = sub { 3 <=> $_[0] }; $stash->set( cmp3 => $fn ); [% END %]/,
       q{[% ListMoreUtils.bsearch( \cmp3, my1to9prim.reverse ) ? "Found" : "Not found" %]} ), "Found", "bsearch 3/4";
is tt( q/[% PERL %] my $fn = sub { $_[0] <=> 9 }; $stash->set( cmp9 => $fn ); [% END %]/,
       q{[% ListMoreUtils.bsearch( \cmp9, my1to9prim ) ? "Found" : "Not found" %]} ), "Not found", "bsearch 4/4";

is tt( q/[% PERL %] my $fn = sub { $_[0] <=> 3 }; $stash->set( cmp3 => $fn ); [% END %]/,
       q{[% ListMoreUtils.bsearchidx( \cmp3, my1to9prim ) %]} ), "1", "bsearchidx 1/4";
is tt( q/[% PERL %] my $fn = sub { $_[0] cmp 'e' }; $stash->set( cmpe => $fn ); [% END %]/,
       q{[% ListMoreUtils.bsearchidx( \cmpe, fiveletters ) %]} ), "4", "bsearchidx 2/4";
is tt( q/[% PERL %] my $fn = sub { 3 <=> $_[0] }; $stash->set( cmp3 => $fn ); [% END %]/,
       q{[% ListMoreUtils.bsearchidx( \cmp3, my1to9prim.reverse ) %]} ), "2", "bsearchidx 3/4";
is tt( q/[% PERL %] my $fn = sub { $_[0] <=> 9 }; $stash->set( cmp9 => $fn ); [% END %]/,
       q{[% ListMoreUtils.bsearchidx( \cmp9, my1to9prim ) %]} ), "-1", "bsearchidx 4/4";

sub tt
{
    my $template = join( '', q{[% my1to9even  = [ 2, 4, 6, 8 ];
                        my1to9prim  = [ 2, 3, 5, 7 ];
                        my1to9odd   = [ 1, 3, 5, 7, 9 ];
			fourletters = [ 'a', 'b', 'c', 'd' ];
			fiveletters = [ 'a', 'b', 'c', 'd', 'e' ];
			longlist    = [ 'This', 'is', 'a', 'list' ];
                        USE ListMoreUtils; %]}, @_ );
    use Template;
    my $tt = Template->new( { EVAL_PERL => 1, }, );
    my $output;
    $tt->process( \$template, {}, \$output ) or
      die "Problem while processing '$template': " . $tt->error();
    return $output;
}
